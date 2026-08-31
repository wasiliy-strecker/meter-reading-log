import 'dart:convert';
import 'package:universal_io/io.dart';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  static const _version = 1;
  static const _minimumPasswordLength = 10;

  final MeterRepository meters;
  final MeterReadingRepository readings;
  final EvidenceExportRepository exports;
  final LocalNotificationReminderRepository reminders;
  final IntegrityService integrity;
  final int kdfIterations;
  final BackupDirectoryProvider _temporaryDirectoryProvider;
  final BackupDirectoryProvider _documentsDirectoryProvider;
  final AesGcm _cipher = AesGcm.with256bits();

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
    final envelope = await _encrypt(payload, password);
    final directory = Directory(
      p.join(
        (await _temporaryDirectoryProvider()).path,
        'meter_reading_backups',
      ),
    );
    await directory.create(recursive: true);
    final stamp = createdAt.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File(
      p.join(directory.path, 'zaehlerstandlog_$stamp.$extension'),
    );
    await file.writeAsString(jsonEncode(envelope), flush: true);
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
      await reminders.schedule(meter);
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
      reading = reading.copyWith(photoPath: restoredPath);
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
        ),
      );
      exportCount += 1;
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

  Future<Map<String, dynamic>> _encrypt(
    Map<String, dynamic> payload,
    String password,
  ) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveKey(password, salt, kdfIterations);
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: key,
      nonce: nonce,
    );
    return {
      'format': _format,
      'schemaVersion': _version,
      'crypto': {
        'algorithm': 'aes-256-gcm',
        'kdf': 'pbkdf2-hmac-sha256',
        'iterations': kdfIterations,
        'salt': base64Encode(salt),
        'nonce': base64Encode(nonce),
      },
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  Future<Map<String, dynamic>> _decrypt(String path, String password) async {
    _validatePassword(password);
    late final Map<String, dynamic> envelope;
    try {
      envelope =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    } on Object {
      throw const BackupException(BackupFailure.invalidFormat);
    }
    if (envelope['format'] != _format ||
        (envelope['schemaVersion'] as num?)?.toInt() != _version) {
      throw const BackupException(BackupFailure.unsupportedVersion);
    }
    try {
      final crypto = Map<String, dynamic>.from(envelope['crypto'] as Map);
      final key = await _deriveKey(
        password,
        base64Decode(crypto['salt'] as String),
        (crypto['iterations'] as num).toInt(),
      );
      final clear = await _cipher.decrypt(
        SecretBox(
          base64Decode(envelope['cipherText'] as String),
          nonce: base64Decode(crypto['nonce'] as String),
          mac: Mac(base64Decode(envelope['mac'] as String)),
        ),
        secretKey: key,
      );
      final payload = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      _validatePayload(payload);
      return payload;
    } on SecretBoxAuthenticationError {
      throw const BackupException(BackupFailure.invalidPassword);
    } on BackupException {
      rethrow;
    } on Object {
      throw const BackupException(BackupFailure.invalidFormat);
    }
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

  Future<SecretKey> _deriveKey(
    String password,
    List<int> salt,
    int iterations,
  ) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  void _validatePassword(String password) {
    if (password.length < _minimumPasswordLength) {
      throw const BackupException(BackupFailure.passwordTooShort);
    }
  }
}
