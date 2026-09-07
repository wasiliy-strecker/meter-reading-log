import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import '../../../core/integrity/integrity_service.dart';
import '../../../core/reminders/local_notification_reminder_repository.dart';
import '../../evidence/domain/evidence_export.dart';
import '../../meters/domain/meter.dart';
import '../../meters/domain/meter_reading.dart';
import '../../meters/domain/meter_repositories.dart';

enum BackupFailure {
  passwordTooShort,
  missingFile,
  invalidFormat,
  invalidPassword,
  unsupportedVersion,
  integrityMismatch,
}

class BackupException implements Exception {
  const BackupException(this.failure, [this.detail = '']);

  final BackupFailure failure;
  final String detail;

  @override
  String toString() => detail.isEmpty
      ? 'BackupException($failure)'
      : 'BackupException($failure, $detail)';
}

class BackupPreview {
  const BackupPreview({
    required this.createdAt,
    required this.meterCount,
    required this.readingCount,
    required this.exportCount,
  });

  final DateTime createdAt;
  final int meterCount;
  final int readingCount;
  final int exportCount;
}

class CreatedBackup {
  const CreatedBackup({required this.path, required this.preview});

  final String path;
  final BackupPreview preview;
}

class BackupImportResult {
  const BackupImportResult({
    required this.meters,
    required this.readings,
    required this.exports,
    required this.skipped,
  });

  final int meters;
  final int readings;
  final int exports;
  final int skipped;
}

typedef BackupDirectoryProvider = Future<Directory> Function();

class EncryptedBackupService {
  EncryptedBackupService({
    required this.meters,
    required this.readings,
    required this.exports,
    required this.reminders,
    this.integrity = const IntegrityService(),
    this.kdfIterations = 210000,
    BackupDirectoryProvider? temporaryDirectoryProvider,
    BackupDirectoryProvider? documentsDirectoryProvider,
  }) : _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  static const extension = 'zslbackup';
  static const _format = 'meter_reading_log_backup';
  static const _version = 2;
  static const _minimumPasswordLength = 6;

  final MeterRepository meters;
  final MeterReadingRepository readings;
  final EvidenceExportRepository exports;
  final MeterReminderRepository reminders;
  final IntegrityService integrity;
  final int kdfIterations;
  final BackupDirectoryProvider _temporaryDirectoryProvider;
  final BackupDirectoryProvider _documentsDirectoryProvider;

  Future<CreatedBackup> create(String password) async {
    _validatePassword(password);
    final createdAt = DateTime.now();
    final allMeters = await meters.loadAll();
    final allReadings = await readings.loadAll();
    final allExports = await exports.loadAll();
    final revisions = <String, List<Map<String, dynamic>>>{};
    for (final reading in allReadings) {
      revisions[reading.id] = (await readings.loadRevisions(
        reading.id,
      )).map((item) => item.toJson()).toList();
    }
    final files = <Map<String, dynamic>>[];
    for (final reading in allReadings) {
      final portable = await _portableFile(
        kind: 'photo',
        ownerId: reading.id,
        path: reading.photoPath,
      );
      if (portable['sha256'] != reading.photoSha256) {
        throw BackupException(
          BackupFailure.integrityMismatch,
          reading.photoPath,
        );
      }
      files.add(portable);
      for (final version in reading.photoHistory) {
        final archived = await _portableFile(
          kind: 'photoVersion',
          ownerId: version.id,
          path: version.path,
        );
        if (archived['sha256'] != version.sha256) {
          throw BackupException(BackupFailure.integrityMismatch, version.path);
        }
        files.add(archived);
      }
    }
    for (final export in allExports) {
      final portable = await _portableFile(
        kind: 'evidence',
        ownerId: export.id,
        path: export.filePath,
      );
      if (portable['sha256'] != export.pdfSha256) {
        throw BackupException(BackupFailure.integrityMismatch, export.filePath);
      }
      files.add(portable);
    }
    final payload = <String, dynamic>{
      'manifest': {
        'format': _format,
        'schemaVersion': _version,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'meterCount': allMeters.length,
        'readingCount': allReadings.length,
        'exportCount': allExports.length,
      },
      'meters': allMeters.map((item) => item.toJson()).toList(),
      'readings': allReadings.map((item) => item.toJson()).toList(),
      'revisions': revisions,
      'exports': allExports.map((item) => item.toJson()).toList(),
      'files': files,
    };
    final directory = Directory(
      p.join(
        (await _temporaryDirectoryProvider()).path,
        'meter_reading_backups',
      ),
    );
    await _prepareBackupDirectory(directory);
    final encodedEnvelope = await _encrypt(payload, password);
    final stamp = createdAt.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File(
      p.join(directory.path, 'zaehlerstandlog_$stamp.$extension'),
    );
    await file.writeAsString(encodedEnvelope, flush: true);
    return CreatedBackup(
      path: file.path,
      preview: BackupPreview(
        createdAt: createdAt,
        meterCount: allMeters.length,
        readingCount: allReadings.length,
        exportCount: allExports.length,
      ),
    );
  }

  Future<BackupPreview> inspect(String path, String password) async {
    final payload = await _decrypt(path, password);
    return _preview(payload);
  }

  Future<BackupImportResult> restore(String path, String password) async {
    final payload = await _decrypt(path, password);
    final files = <String, Map<String, dynamic>>{
      for (final item in payload['files'] as List)
        '${(item as Map)['kind']}:${item['ownerId']}':
            Map<String, dynamic>.from(item),
    };
    final documents = await _documentsDirectoryProvider();
    var meterCount = 0;
    var readingCount = 0;
    var exportCount = 0;
    var skipped = 0;

    for (final raw in payload['meters'] as List) {
      final meter = Meter.fromJson(Map<String, dynamic>.from(raw as Map));
      final existing = await meters.findById(meter.id);
      if (existing != null && !meter.updatedAt.isAfter(existing.updatedAt)) {
        skipped += 1;
        continue;
      }
      await meters.save(meter);
      meterCount += 1;
    }

    final revisionsMap = Map<String, dynamic>.from(payload['revisions'] as Map);
    for (final raw in payload['readings'] as List) {
      var reading = MeterReading.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      final existing = await readings.findById(reading.id);
      if (existing != null && !reading.updatedAt.isAfter(existing.updatedAt)) {
        skipped += 1;
        continue;
      }
      final portable = files['photo:${reading.id}'];
      if (portable == null) {
        throw BackupException(BackupFailure.invalidFormat, reading.id);
      }
      if (portable['sha256'] != reading.photoSha256) {
        throw BackupException(BackupFailure.integrityMismatch, reading.id);
      }
      final restoredPath = await _restoreFile(
        portable,
        Directory(p.join(documents.path, 'meter_photos')),
      );
      final restoredHistory = <ReadingPhotoVersion>[];
      for (final version in reading.photoHistory) {
        final archived = files['photoVersion:${version.id}'];
        if (archived == null) {
          throw BackupException(BackupFailure.invalidFormat, version.id);
        }
        if (archived['sha256'] != version.sha256) {
          throw BackupException(BackupFailure.integrityMismatch, version.id);
        }
        restoredHistory.add(
          version.copyWith(
            path: await _restoreFile(
              archived,
              Directory(p.join(documents.path, 'meter_photos')),
            ),
          ),
        );
      }
      reading = reading.copyWith(
        photoPath: restoredPath,
        photoHistory: restoredHistory,
      );
      await readings.save(reading);
      final rawRevisions = revisionsMap[reading.id] as List? ?? const [];
      for (final rawRevision in rawRevisions) {
        await readings.saveRevision(
          ReadingRevision.fromJson(
            Map<String, dynamic>.from(rawRevision as Map),
          ),
        );
      }
      readingCount += 1;
    }

    for (final raw in payload['exports'] as List) {
      final item = EvidenceExportRecord.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      final portable = files['evidence:${item.id}'];
      if (portable == null) {
        throw BackupException(BackupFailure.invalidFormat, item.id);
      }
      if (portable['sha256'] != item.pdfSha256) {
        throw BackupException(BackupFailure.integrityMismatch, item.id);
      }
      final restoredPath = await _restoreFile(
        portable,
        Directory(p.join(documents.path, 'evidence_reports')),
      );
      await exports.save(
        EvidenceExportRecord(
          id: item.id,
          meterId: item.meterId,
          kind: item.kind,
          readingIds: item.readingIds,
          createdAt: item.createdAt,
          fileName: item.fileName,
          filePath: restoredPath,
          pdfSha256: item.pdfSha256,
          manifestSha256: item.manifestSha256,
          photoMode: item.photoMode,
        ),
      );
      exportCount += 1;
    }

    for (final meter in await meters.loadAll()) {
      if (meter.reminder == null) continue;
      final meterReadings = await readings.loadForMeter(meter.id);
      final latestReading = meterReadings.isEmpty
          ? null
          : meterReadings.reduce(
              (left, right) =>
                  left.capturedAt.isAfter(right.capturedAt) ? left : right,
            );
      await reminders.schedule(meter, latestReading: latestReading);
    }
    return BackupImportResult(
      meters: meterCount,
      readings: readingCount,
      exports: exportCount,
      skipped: skipped,
    );
  }

  Future<Map<String, dynamic>> _portableFile({
    required String kind,
    required String ownerId,
    required String path,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw BackupException(BackupFailure.missingFile, path);
    }
    final bytes = await file.readAsBytes();
    return {
      'kind': kind,
      'ownerId': ownerId,
      'fileName': p.basename(path),
      'sha256': await integrity.sha256Bytes(bytes),
      'bytesBase64': base64Encode(bytes),
    };
  }

  Future<void> _prepareBackupDirectory(Directory directory) async {
    await directory.create(recursive: true);
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.$extension')) {
        try {
          await entity.delete();
        } on FileSystemException {
          // A stale temporary backup must not prevent a new backup.
        }
      }
    }
  }

  Future<String> _restoreFile(
    Map<String, dynamic> portable,
    Directory directory,
  ) async {
    final bytes = base64Decode(portable['bytesBase64'] as String);
    final expected = portable['sha256'] as String;
    if (await integrity.sha256Bytes(bytes) != expected) {
      throw BackupException(
        BackupFailure.integrityMismatch,
        portable['fileName'] as String? ?? '',
      );
    }
    await directory.create(recursive: true);
    final fileName = p.basename(portable['fileName'] as String);
    final file = File(
      p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}_$fileName',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> _encrypt(Map<String, dynamic> payload, String password) async {
    final salt = _secureRandomBytes(16);
    final nonce = _secureRandomBytes(12);
    final clearTextFuture = compute(
      _encodeBackupPayload,
      payload,
      debugLabel: 'ZSL backup JSON encoding',
    );
    final key = await _deriveBackupKey(password, salt, kdfIterations);
    final clearText = await clearTextFuture;
    final box = await AesGcm.with256bits().encrypt(
      clearText,
      secretKey: key,
      nonce: nonce,
    );
    return compute(_encodeBackupEnvelope, <String, dynamic>{
      'format': _format,
      'schemaVersion': _version,
      'iterations': kdfIterations,
      'salt': salt,
      'nonce': nonce,
      'cipherText': box.cipherText,
      'mac': box.mac.bytes,
    }, debugLabel: 'ZSL backup envelope encoding');
  }

  Future<Map<String, dynamic>> _decrypt(String path, String password) async {
    _validatePassword(password);
    late final String encodedEnvelope;
    try {
      encodedEnvelope = await File(path).readAsString();
    } on Object {
      throw const BackupException(BackupFailure.invalidFormat);
    }
    final envelope = await compute(_decodeBackupEnvelope, <String, dynamic>{
      'encodedEnvelope': encodedEnvelope,
      'format': _format,
      'maximumSchemaVersion': _version,
    }, debugLabel: 'ZSL backup envelope decoding');
    final failure = envelope['failure'] as String?;
    if (failure != null) {
      throw BackupException(switch (failure) {
        'unsupportedVersion' => BackupFailure.unsupportedVersion,
        _ => BackupFailure.invalidFormat,
      });
    }
    late final List<int> clearText;
    try {
      final key = await _deriveBackupKey(
        password,
        envelope['salt'] as List<int>,
        envelope['iterations'] as int,
      );
      clearText = await AesGcm.with256bits().decrypt(
        SecretBox(
          envelope['cipherText'] as List<int>,
          nonce: envelope['nonce'] as List<int>,
          mac: Mac(envelope['mac'] as List<int>),
        ),
        secretKey: key,
      );
    } on SecretBoxAuthenticationError {
      throw const BackupException(BackupFailure.invalidPassword);
    } on Object {
      throw const BackupException(BackupFailure.invalidFormat);
    }
    final decoded = await compute(
      _decodeBackupPayload,
      clearText,
      debugLabel: 'ZSL backup JSON decoding',
    );
    if (decoded['failure'] != null) {
      throw const BackupException(BackupFailure.invalidFormat);
    }
    final payload = Map<String, dynamic>.from(decoded['payload'] as Map);
    _validatePayload(payload);
    return payload;
  }

  void _validatePayload(Map<String, dynamic> payload) {
    final manifest = payload['manifest'];
    if (manifest is! Map ||
        manifest['format'] != _format ||
        payload['meters'] is! List ||
        payload['readings'] is! List ||
        payload['revisions'] is! Map ||
        payload['exports'] is! List ||
        payload['files'] is! List) {
      throw const BackupException(BackupFailure.invalidFormat);
    }
  }

  BackupPreview _preview(Map<String, dynamic> payload) {
    final manifest = Map<String, dynamic>.from(payload['manifest'] as Map);
    return BackupPreview(
      createdAt: DateTime.parse(manifest['createdAt'] as String),
      meterCount: (manifest['meterCount'] as num).toInt(),
      readingCount: (manifest['readingCount'] as num).toInt(),
      exportCount: (manifest['exportCount'] as num).toInt(),
    );
  }

  void _validatePassword(String password) {
    if (password.length < _minimumPasswordLength) {
      throw const BackupException(BackupFailure.passwordTooShort);
    }
  }
}

Uint8List _encodeBackupPayload(Map<String, dynamic> payload) {
  return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
}

String _encodeBackupEnvelope(Map<String, dynamic> input) {
  return jsonEncode({
    'format': input['format'] as String,
    'schemaVersion': input['schemaVersion'] as int,
    'crypto': {
      'algorithm': 'aes-256-gcm',
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': input['iterations'] as int,
      'salt': base64Encode(input['salt'] as List<int>),
      'nonce': base64Encode(input['nonce'] as List<int>),
    },
    'cipherText': base64Encode(input['cipherText'] as List<int>),
    'mac': base64Encode(input['mac'] as List<int>),
  });
}

Map<String, dynamic> _decodeBackupEnvelope(Map<String, dynamic> input) {
  late final Map<String, dynamic> envelope;
  try {
    envelope =
        jsonDecode(input['encodedEnvelope'] as String) as Map<String, dynamic>;
  } on Object {
    return const {'failure': 'invalidFormat'};
  }
  final schemaVersion = (envelope['schemaVersion'] as num?)?.toInt();
  if (envelope['format'] != input['format'] ||
      schemaVersion == null ||
      schemaVersion < 1 ||
      schemaVersion > (input['maximumSchemaVersion'] as int)) {
    return const {'failure': 'unsupportedVersion'};
  }
  try {
    final crypto = Map<String, dynamic>.from(envelope['crypto'] as Map);
    return {
      'iterations': (crypto['iterations'] as num).toInt(),
      'salt': base64Decode(crypto['salt'] as String),
      'nonce': base64Decode(crypto['nonce'] as String),
      'cipherText': base64Decode(envelope['cipherText'] as String),
      'mac': base64Decode(envelope['mac'] as String),
    };
  } on Object {
    return const {'failure': 'invalidFormat'};
  }
}

Map<String, dynamic> _decodeBackupPayload(List<int> clearText) {
  try {
    return {
      'payload': jsonDecode(utf8.decode(clearText)) as Map<String, dynamic>,
    };
  } on Object {
    return const {'failure': 'invalidFormat'};
  }
}

Future<SecretKey> _deriveBackupKey(
  String password,
  List<int> salt,
  int iterations,
) {
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
