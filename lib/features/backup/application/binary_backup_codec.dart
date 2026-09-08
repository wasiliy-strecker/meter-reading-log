import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:universal_io/io.dart';

const binaryBackupFormat = 'meter_reading_log_backup';
const binaryBackupVersion = 3;

class BinaryBackupCodecException implements Exception {
  const BinaryBackupCodecException(this.code, [this.detail = '']);

  final String code;
  final String detail;

  @override
  String toString() => detail.isEmpty ? code : '$code: $detail';
}

Future<bool> isBinaryBackup(String path) async {
  try {
    final prefix = await File(path)
        .openRead(0, 4)
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
    return prefix.length >= 2 && prefix[0] == 0x50 && prefix[1] == 0x4b;
  } on Object {
    return false;
  }
}

Future<Map<String, dynamic>> createBinaryBackupArchive(
  Map<String, dynamic> input,
  void Function(Map<String, dynamic>) onProgress,
) async {
  final outputPath = input['outputPath'] as String;
  final payload = Map<String, dynamic>.from(input['payload'] as Map);
  final rawAssets = (input['assets'] as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
  final assetSizes = <int>[];
  for (final asset in rawAssets) {
    final file = File(asset['path'] as String);
    if (!await file.exists()) {
      throw BinaryBackupCodecException('missingFile', file.path);
    }
    assetSizes.add(await file.length());
  }
  final totalBytes = assetSizes.fold<int>(0, (sum, size) => sum + size);
  onProgress({
    'phase': 'preparing',
    'processedBytes': 0,
    'totalBytes': totalBytes,
    'completedItems': 0,
    'totalItems': rawAssets.length,
  });

  final password = input['password'] as String;
  final iterations = input['iterations'] as int;
  final salt = _secureRandomBytes(16);
  final key = await _deriveKey(password, salt, iterations);
  final encoder = ZipEncoder();
  OutputFileStream? output;
  var opened = false;
  try {
    await File(outputPath).parent.create(recursive: true);
    output = OutputFileStream(outputPath);
    encoder.startEncode(output, level: 0);
    opened = true;
    final encryptedAssets = <String, dynamic>{};
    var processedBytes = 0;
    var completedItems = 0;
    var lastReportedBytes = -1;

    for (var index = 0; index < rawAssets.length; index += 1) {
      final asset = rawAssets[index];
      final sha256 = asset['sha256'] as String;
      final file = File(asset['path'] as String);
      final hashSink = Sha256().toSync().newHashSink();
      final trackedStream = file.openRead().map((chunk) {
        hashSink.add(chunk);
        processedBytes += chunk.length;
        if (processedBytes - lastReportedBytes >= 256 * 1024 ||
            processedBytes == totalBytes) {
          lastReportedBytes = processedBytes;
          onProgress({
            'phase': 'encrypting',
            'processedBytes': processedBytes,
            'totalBytes': totalBytes,
            'completedItems': completedItems,
            'totalItems': rawAssets.length,
          });
        }
        return chunk;
      });
      if (encryptedAssets.containsKey(sha256)) {
        await for (final _ in trackedStream) {
          // Duplicate paths are still hashed so every referenced file is
          // verified, but their bytes are stored only once.
        }
      } else {
        final nonce = _secureRandomBytes(12);
        Mac? mac;
        final cipherText = BytesBuilder(copy: false);
        await for (final chunk in AesGcm.with256bits().encryptStream(
          trackedStream,
          secretKey: key,
          nonce: nonce,
          aad: _assetAad(sha256),
          onMac: (value) => mac = value,
        )) {
          cipherText.add(chunk);
        }
        final encryptedBytes = cipherText.takeBytes();
        final assetPath = 'assets/$sha256.bin';
        encoder.add(
          ArchiveFile.noCompress(
            assetPath,
            encryptedBytes.length,
            encryptedBytes,
          ),
        );
        encryptedAssets[sha256] = {
          'entry': assetPath,
          'size': assetSizes[index],
          'nonce': base64Encode(nonce),
          'mac': base64Encode(mac!.bytes),
        };
      }
      hashSink.close();
      final actualSha256 = _hex(hashSink.hashSync().bytes);
      if (actualSha256 != sha256) {
        throw BinaryBackupCodecException('integrityMismatch', file.path);
      }
      completedItems += 1;
      onProgress({
        'phase': 'encrypting',
        'processedBytes': processedBytes,
        'totalBytes': totalBytes,
        'completedItems': completedItems,
        'totalItems': rawAssets.length,
      });
    }

    payload['assets'] = encryptedAssets;
    onProgress({
      'phase': 'packaging',
      'processedBytes': totalBytes,
      'totalBytes': totalBytes,
      'completedItems': rawAssets.length,
      'totalItems': rawAssets.length,
    });
    final manifestNonce = _secureRandomBytes(12);
    final manifestBox = await AesGcm.with256bits().encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: key,
      nonce: manifestNonce,
      aad: _manifestAad,
    );
    encoder.add(
      ArchiveFile.noCompress(
        'manifest.bin',
        manifestBox.cipherText.length,
        manifestBox.cipherText,
      ),
    );
    final header = jsonEncode({
      'format': binaryBackupFormat,
      'schemaVersion': binaryBackupVersion,
      'crypto': {
        'algorithm': 'aes-256-gcm',
        'kdf': 'pbkdf2-hmac-sha256',
        'iterations': iterations,
        'salt': base64Encode(salt),
        'manifestNonce': base64Encode(manifestNonce),
        'manifestMac': base64Encode(manifestBox.mac.bytes),
      },
    });
    encoder.add(ArchiveFile.string('header.json', header));
    encoder.endEncode();
    output.closeSync();
    opened = false;
    onProgress({
      'phase': 'complete',
      'processedBytes': totalBytes,
      'totalBytes': totalBytes,
      'completedItems': rawAssets.length,
      'totalItems': rawAssets.length,
    });
    return {
      'sizeBytes': await File(outputPath).length(),
      'uniqueAssetCount': encryptedAssets.length,
    };
  } on BinaryBackupCodecException {
    rethrow;
  } on Object catch (error) {
    throw BinaryBackupCodecException('invalidFormat', error.toString());
  } finally {
    if (opened) {
      try {
        encoder.endEncode();
      } on Object {
        // The partial archive is removed below.
      }
      try {
        output?.closeSync();
      } on Object {
        // The partial archive is removed below.
      }
      final partial = File(outputPath);
      if (await partial.exists()) await partial.delete();
    }
  }
}

class BinaryBackupReader {
  BinaryBackupReader._({
    required this.payload,
    required Archive archive,
    required InputFileStream input,
    required SecretKey key,
  }) : _archive = archive,
       _input = input,
       _key = key;

  final Map<String, dynamic> payload;
  final Archive _archive;
  final InputFileStream _input;
  final SecretKey _key;

  static Future<BinaryBackupReader> open(String path, String password) async {
    InputFileStream? input;
    Archive? archive;
    try {
      input = InputFileStream(path);
      archive = ZipDecoder().decodeStream(input);
      final headerEntry = archive.findFile('header.json');
      final manifestEntry = archive.findFile('manifest.bin');
      if (headerEntry == null || manifestEntry == null) {
        throw const BinaryBackupCodecException('invalidFormat');
      }
      final header = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(headerEntry.readBytes()!)) as Map,
      );
      final version = (header['schemaVersion'] as num?)?.toInt();
      if (header['format'] != binaryBackupFormat || version == null) {
        throw const BinaryBackupCodecException('invalidFormat');
      }
      if (version != binaryBackupVersion) {
        throw const BinaryBackupCodecException('unsupportedVersion');
      }
      final crypto = Map<String, dynamic>.from(header['crypto'] as Map);
      if (crypto['algorithm'] != 'aes-256-gcm' ||
          crypto['kdf'] != 'pbkdf2-hmac-sha256') {
        throw const BinaryBackupCodecException('unsupportedVersion');
      }
      final iterations = (crypto['iterations'] as num).toInt();
      if (iterations < 1000 || iterations > 2000000) {
        throw const BinaryBackupCodecException('invalidFormat');
      }
      final key = await _deriveKey(
        password,
        base64Decode(crypto['salt'] as String),
        iterations,
      );
      late final List<int> clearManifest;
      try {
        clearManifest = await AesGcm.with256bits().decrypt(
          SecretBox(
            manifestEntry.readBytes()!,
            nonce: base64Decode(crypto['manifestNonce'] as String),
            mac: Mac(base64Decode(crypto['manifestMac'] as String)),
          ),
          secretKey: key,
          aad: _manifestAad,
        );
      } on SecretBoxAuthenticationError {
        throw const BinaryBackupCodecException('invalidPassword');
      }
      final payload = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(clearManifest)) as Map,
      );
      return BinaryBackupReader._(
        payload: payload,
        archive: archive,
        input: input,
        key: key,
      );
    } on BinaryBackupCodecException {
      archive?.clearSync();
      input?.closeSync();
      rethrow;
    } on Object catch (error) {
      archive?.clearSync();
      input?.closeSync();
      throw BinaryBackupCodecException('invalidFormat', error.toString());
    }
  }

  Future<Uint8List> readAsset(String sha256) async {
    try {
      final assets = Map<String, dynamic>.from(payload['assets'] as Map);
      final crypto = Map<String, dynamic>.from(assets[sha256] as Map);
      final expectedEntry = 'assets/$sha256.bin';
      if (crypto['entry'] != expectedEntry) {
        throw const BinaryBackupCodecException('invalidFormat');
      }
      final entry = _archive.findFile(expectedEntry);
      if (entry == null) {
        throw const BinaryBackupCodecException('invalidFormat');
      }
      final encryptedBytes = entry.readBytes();
      entry.clear();
      if (encryptedBytes == null) {
        throw const BinaryBackupCodecException('invalidFormat');
      }
      final clearText = await AesGcm.with256bits().decrypt(
        SecretBox(
          encryptedBytes,
          nonce: base64Decode(crypto['nonce'] as String),
          mac: Mac(base64Decode(crypto['mac'] as String)),
        ),
        secretKey: _key,
        aad: _assetAad(sha256),
      );
      if (_hex((await Sha256().hash(clearText)).bytes) != sha256) {
        throw const BinaryBackupCodecException('integrityMismatch');
      }
      return Uint8List.fromList(clearText);
    } on BinaryBackupCodecException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const BinaryBackupCodecException('integrityMismatch');
    } on Object catch (error) {
      throw BinaryBackupCodecException('invalidFormat', error.toString());
    }
  }

  void close() {
    try {
      _archive.clearSync();
    } on Object {
      // Closing is best-effort after all requested entries were read.
    }
    try {
      _input.closeSync();
    } on Object {
      // The archive may already have closed the underlying input.
    }
  }
}

final _manifestAad = utf8.encode('$binaryBackupFormat:v3:manifest');

List<int> _assetAad(String sha256) =>
    utf8.encode('$binaryBackupFormat:v$binaryBackupVersion:asset:$sha256');

Future<SecretKey> _deriveKey(String password, List<int> salt, int iterations) {
  return Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: password, nonce: salt);
}

List<int> _secureRandomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

String _hex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
