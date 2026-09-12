import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/integrity/integrity_service.dart';
import 'package:meter_reading_log/core/reminders/local_notification_reminder_repository.dart';
import 'package:meter_reading_log/features/backup/application/encrypted_backup_service.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import '../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'hourly reminder start survives an encrypted backup and rescheduling',
    () async {
      final temp = await Directory.systemTemp.createTemp('hourly_backup_test_');
      addTearDown(() => temp.delete(recursive: true));
      final start = DateTime.utc(2030, 9, 15, 12, 30);
      final meter = _meter().copyWith(
        reminder: ReadingReminderSchedule(
          interval: ReminderInterval.hourly,
          day: 1,
          hour: 14,
          minute: 30,
          startsAt: start,
        ),
      );
      final sourceMeters = MemoryMeterRepository()..items[meter.id] = meter;
      final source = EncryptedBackupService(
        meters: sourceMeters,
        readings: MemoryReadingRepository(),
        exports: MemoryEvidenceExportRepository(),
        reminders: NoopMeterReminderRepository(),
        kdfIterations: 1000,
        temporaryDirectoryProvider: () async => temp,
        documentsDirectoryProvider: () async => temp,
      );
      final backup = await source.create('123456');
      final targetRoot = await Directory('${temp.path}/restored').create();
      final restoredMeters = MemoryMeterRepository();
      final reminders = NoopMeterReminderRepository();
      final target = EncryptedBackupService(
        meters: restoredMeters,
        readings: MemoryReadingRepository(),
        exports: MemoryEvidenceExportRepository(),
        reminders: reminders,
        kdfIterations: 1000,
        temporaryDirectoryProvider: () async => targetRoot,
        documentsDirectoryProvider: () async => targetRoot,
      );
      await target.restore(backup.path, '123456');
      expect(restoredMeters.items[meter.id]!.reminder!.startsAt, start);
      expect(reminders.scheduledMeters.single.reminder!.startsAt, start);
    },
  );

  test('accepts six-character passwords and rejects shorter ones', () async {
    final temp = await Directory.systemTemp.createTemp('backup_password_test_');
    addTearDown(() => temp.delete(recursive: true));
    final service = EncryptedBackupService(
      meters: MemoryMeterRepository(),
      readings: MemoryReadingRepository(),
      exports: MemoryEvidenceExportRepository(),
      reminders: LocalNotificationReminderRepository.instance,
      kdfIterations: 1000,
      temporaryDirectoryProvider: () async => temp,
      documentsDirectoryProvider: () async => temp,
    );

    await expectLater(
      service.create('12345'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.failure,
          'failure',
          BackupFailure.passwordTooShort,
        ),
      ),
    );

    final firstBackup = await service.create('123456');
    final latestBackup = await service.create('123456');
    expect(await File(firstBackup.path).exists(), isFalse);
    expect(await File(latestBackup.path).exists(), isTrue);
    expect(
      await File(latestBackup.path).parent
          .list()
          .where((entity) => entity.path.endsWith('.zslbackup'))
          .length,
      1,
    );
  });

  test('failed encryption removes its partial backup file', () async {
    final temp = await Directory.systemTemp.createTemp('failed_backup_test_');
    addTearDown(() => temp.delete(recursive: true));
    final photo = File('${temp.path}/photo.jpg')..writeAsStringSync('photo');
    final corruptedDuplicate = File('${temp.path}/corrupted.jpg')
      ..writeAsStringSync('corrupted');
    final photoHash = await const IntegrityService().sha256Bytes(
      await photo.readAsBytes(),
    );
    final meter = _meter();
    final meters = MemoryMeterRepository();
    final readings = MemoryReadingRepository();
    await meters.save(meter);
    await readings.save(
      _reading(meter, photo.path, photoHash).copyWith(
        photoHistory: [
          ReadingPhotoVersion(
            id: 'corrupted_duplicate',
            path: corruptedDuplicate.path,
            sha256: photoHash,
            source: ReadingSource.gallery,
            addedAt: DateTime.utc(2026, 9, 8),
            ocrRawText: '',
            ocrCandidate: '',
            ocrConfidence: 0,
          ),
        ],
      ),
    );
    final service = EncryptedBackupService(
      meters: meters,
      readings: readings,
      exports: MemoryEvidenceExportRepository(),
      reminders: LocalNotificationReminderRepository.instance,
      kdfIterations: 1000,
      temporaryDirectoryProvider: () async => temp,
      documentsDirectoryProvider: () async => temp,
    );

    await expectLater(
      service.create('123456'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.failure,
          'failure',
          BackupFailure.integrityMismatch,
        ),
      ),
    );
    final backupDirectory = Directory('${temp.path}/meter_reading_backups');
    expect(
      await backupDirectory
          .list()
          .where((entity) => entity.path.endsWith('.zslbackup'))
          .isEmpty,
      isTrue,
    );
  });

  test('encrypted backup round-trips domain data, photos and PDFs', () async {
    final temp = await Directory.systemTemp.createTemp('backup_test_');
    addTearDown(() => temp.delete(recursive: true));
    const integrity = IntegrityService();
    final photo = File('${temp.path}/photo.jpg')..writeAsStringSync('photo');
    final olderPhoto = File('${temp.path}/older-photo.jpg')
      ..writeAsStringSync('older photo');
    final pdf = File('${temp.path}/proof.pdf')..writeAsStringSync('%PDF proof');
    final photoHash = await integrity.sha256Bytes(await photo.readAsBytes());
    final olderPhotoHash = await integrity.sha256Bytes(
      await olderPhoto.readAsBytes(),
    );
    final pdfHash = await integrity.sha256Bytes(await pdf.readAsBytes());

    final sourceMeters = MemoryMeterRepository();
    final sourceReadings = MemoryReadingRepository();
    final sourceExports = MemoryEvidenceExportRepository();
    final meter = _meter();
    final reading = _reading(meter, photo.path, photoHash).copyWith(
      photoHistory: [
        ReadingPhotoVersion(
          id: 'photo_version_1',
          path: olderPhoto.path,
          sha256: olderPhotoHash,
          source: ReadingSource.camera,
          addedAt: DateTime.utc(2026, 8, 30, 10),
          ocrRawText: '41,9',
          ocrCandidate: '41,9',
          ocrConfidence: 0.8,
        ),
        ReadingPhotoVersion(
          id: 'photo_version_duplicate',
          path: photo.path,
          sha256: photoHash,
          source: ReadingSource.camera,
          addedAt: DateTime.utc(2026, 8, 30, 11),
          ocrRawText: '42,5',
          ocrCandidate: '42,5',
          ocrConfidence: 0.9,
        ),
      ],
    );
    await sourceMeters.save(meter);
    await sourceReadings.save(reading);
    final revision = ReadingRevision(
      id: 'revision_1',
      readingId: reading.id,
      changedAt: DateTime.utc(2026, 8, 31, 11),
      reason: 'Kontrolle',
      changes: const {'Notiz': ReadingChange(before: '', after: 'Geprüft')},
    );
    await sourceReadings.saveRevision(revision);
    final export = EvidenceExportRecord(
      id: 'export_1',
      meterId: meter.id,
      kind: EvidenceExportKind.singleReading,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 8, 31, 12),
      fileName: 'proof.pdf',
      filePath: pdf.path,
      pdfSha256: pdfHash,
      manifestSha256: 'manifest',
      photoMode: EvidencePhotoMode.currentPhotos,
    );
    await sourceExports.save(export);

    final source = EncryptedBackupService(
      meters: sourceMeters,
      readings: sourceReadings,
      exports: sourceExports,
      reminders: LocalNotificationReminderRepository.instance,
      kdfIterations: 1000,
      temporaryDirectoryProvider: () async => temp,
      documentsDirectoryProvider: () async => temp,
    );
    final progress = <BackupProgress>[];
    final backup = await source.create(
      'sicheres-passwort',
      onProgress: progress.add,
    );
    expect(await File(backup.path).exists(), isTrue);
    expect(backup.sizeBytes, await File(backup.path).length());
    expect(backup.preview.readingCount, 1);
    expect(
      progress.map((item) => item.phase),
      containsAllInOrder([
        BackupProgressPhase.preparing,
        BackupProgressPhase.encrypting,
        BackupProgressPhase.packaging,
        BackupProgressPhase.complete,
      ]),
    );
    final archiveInput = InputFileStream(backup.path);
    final archive = ZipDecoder().decodeStream(archiveInput);
    expect(
      archive.where((entry) => entry.name.startsWith('assets/')),
      hasLength(3),
    );
    archive.clearSync();
    archiveInput.closeSync();

    final legacyPayload = <String, dynamic>{
      'manifest': {
        'format': 'meter_reading_log_backup',
        'schemaVersion': 2,
        'createdAt': DateTime.utc(2026, 8, 31, 12).toIso8601String(),
        'meterCount': 1,
        'readingCount': 1,
        'exportCount': 1,
      },
      'meters': [meter.toJson()],
      'readings': [reading.toJson()],
      'revisions': {
        reading.id: [revision.toJson()],
      },
      'exports': [export.toJson()],
      'files': [
        _legacyFile('photo', reading.id, photo, photoHash),
        _legacyFile(
          'photoVersion',
          'photo_version_1',
          olderPhoto,
          olderPhotoHash,
        ),
        _legacyFile(
          'photoVersion',
          'photo_version_duplicate',
          photo,
          photoHash,
        ),
        _legacyFile('evidence', export.id, pdf, pdfHash),
      ],
    };
    final legacyPath = await _writeLegacyBackup(
      temp,
      'sicheres-passwort',
      legacyPayload,
    );
    expect(
      (await source.inspect(legacyPath, 'sicheres-passwort')).readingCount,
      1,
    );

    final targetRoot = Directory('${temp.path}/restored')..createSync();
    final targetMeters = MemoryMeterRepository();
    final targetReadings = MemoryReadingRepository();
    final targetExports = MemoryEvidenceExportRepository();
    final target = EncryptedBackupService(
      meters: targetMeters,
      readings: targetReadings,
      exports: targetExports,
      reminders: LocalNotificationReminderRepository.instance,
      kdfIterations: 1000,
      temporaryDirectoryProvider: () async => targetRoot,
      documentsDirectoryProvider: () async => targetRoot,
    );

    final result = await target.restore(backup.path, 'sicheres-passwort');
    expect(result.meters, 1);
    expect(result.readings, 1);
    expect(result.exports, 1);
    expect(await targetReadings.loadRevisions(reading.id), hasLength(1));
    expect(
      await File(
        (await targetReadings.findById(reading.id))!.photoPath,
      ).exists(),
      isTrue,
    );
    final restoredReading = (await targetReadings.findById(reading.id))!;
    expect(restoredReading.photoHistory, hasLength(2));
    expect(
      await File(restoredReading.photoHistory.first.path).exists(),
      isTrue,
    );
    expect(restoredReading.photoHistory.first.sha256, olderPhotoHash);
    expect(
      (await targetExports.loadAll()).single.photoMode,
      EvidencePhotoMode.currentPhotos,
    );

    await expectLater(
      target.inspect(backup.path, 'falsches-passwort'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.failure,
          'failure',
          BackupFailure.invalidPassword,
        ),
      ),
    );

    final legacyTargetRoot = Directory('${temp.path}/legacy-restored')
      ..createSync();
    final legacyReadings = MemoryReadingRepository();
    final legacyTarget = EncryptedBackupService(
      meters: MemoryMeterRepository(),
      readings: legacyReadings,
      exports: MemoryEvidenceExportRepository(),
      reminders: LocalNotificationReminderRepository.instance,
      kdfIterations: 1000,
      temporaryDirectoryProvider: () async => legacyTargetRoot,
      documentsDirectoryProvider: () async => legacyTargetRoot,
    );
    final legacyResult = await legacyTarget.restore(
      legacyPath,
      'sicheres-passwort',
    );
    expect(legacyResult.meters, 1);
    expect(legacyResult.readings, 1);
    expect(legacyResult.exports, 1);
    expect(
      (await legacyReadings.findById(reading.id))!.photoHistory,
      hasLength(2),
    );
  });
}

Map<String, dynamic> _legacyFile(
  String kind,
  String ownerId,
  File file,
  String sha256,
) {
  return {
    'kind': kind,
    'ownerId': ownerId,
    'fileName': file.uri.pathSegments.last,
    'sha256': sha256,
    'bytesBase64': base64Encode(file.readAsBytesSync()),
  };
}

Future<String> _writeLegacyBackup(
  Directory directory,
  String password,
  Map<String, dynamic> payload,
) async {
  const iterations = 1000;
  final salt = List<int>.generate(16, (index) => index + 1);
  final nonce = List<int>.generate(12, (index) => index + 20);
  final key = await Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: password, nonce: salt);
  final box = await AesGcm.with256bits().encrypt(
    utf8.encode(jsonEncode(payload)),
    secretKey: key,
    nonce: nonce,
  );
  final envelope = {
    'format': 'meter_reading_log_backup',
    'schemaVersion': 2,
    'crypto': {
      'algorithm': 'aes-256-gcm',
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
    },
    'cipherText': base64Encode(box.cipherText),
    'mac': base64Encode(box.mac.bytes),
  };
  final path = '${directory.path}/legacy.${EncryptedBackupService.extension}';
  await File(path).writeAsString(jsonEncode(envelope));
  return path;
}

Meter _meter() => Meter(
  id: 'meter_1',
  label: 'Wasser Küche',
  type: MeterType.water,
  unit: 'm³',
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

MeterReading _reading(Meter meter, String photoPath, String photoHash) =>
    MeterReading(
      id: 'reading_1',
      meterId: meter.id,
      meter: MeterSnapshot.fromMeter(meter),
      value: ReadingValue.tryParse('42,5')!,
      capturedAt: DateTime.utc(2026, 8, 31, 10),
      timezoneOffsetMinutes: 120,
      storedAt: DateTime.utc(2026, 8, 31, 10),
      updatedAt: DateTime.utc(2026, 8, 31, 10),
      source: ReadingSource.camera,
      photoPath: photoPath,
      photoSha256: photoHash,
      ocrRawText: '42,5',
      ocrCandidate: '42,5',
      ocrConfidence: 0.9,
      manifestSha256: 'manifest',
    );
