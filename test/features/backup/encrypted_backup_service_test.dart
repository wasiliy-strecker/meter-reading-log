import 'dart:io';

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

  test('encrypted backup round-trips domain data, photos and PDFs', () async {
    final temp = await Directory.systemTemp.createTemp('backup_test_');
    addTearDown(() => temp.delete(recursive: true));
    const integrity = IntegrityService();
    final photo = File('${temp.path}/photo.jpg')..writeAsStringSync('photo');
    final pdf = File('${temp.path}/proof.pdf')..writeAsStringSync('%PDF proof');
    final photoHash = await integrity.sha256Bytes(await photo.readAsBytes());
    final pdfHash = await integrity.sha256Bytes(await pdf.readAsBytes());

    final sourceMeters = MemoryMeterRepository();
    final sourceReadings = MemoryReadingRepository();
    final sourceExports = MemoryEvidenceExportRepository();
    final meter = _meter();
    final reading = _reading(meter, photo.path, photoHash);
    await sourceMeters.save(meter);
    await sourceReadings.save(reading);
    await sourceReadings.saveRevision(
      ReadingRevision(
        id: 'revision_1',
        readingId: reading.id,
        changedAt: DateTime.utc(2026, 8, 31, 11),
        reason: 'Kontrolle',
        changes: const {'Notiz': ReadingChange(before: '', after: 'Geprüft')},
      ),
    );
    await sourceExports.save(
      EvidenceExportRecord(
        id: 'export_1',
        meterId: meter.id,
        kind: EvidenceExportKind.singleReading,
        readingIds: [reading.id],
        createdAt: DateTime.utc(2026, 8, 31, 12),
        fileName: 'proof.pdf',
        filePath: pdf.path,
        pdfSha256: pdfHash,
        manifestSha256: 'manifest',
      ),
    );

    final source = EncryptedBackupService(
      meters: sourceMeters,
      readings: sourceReadings,
      exports: sourceExports,
      reminders: LocalNotificationReminderRepository.instance,
      kdfIterations: 1000,
      temporaryDirectoryProvider: () async => temp,
      documentsDirectoryProvider: () async => temp,
    );
    final backup = await source.create('sicheres-passwort');
    expect(await File(backup.path).exists(), isTrue);
    expect(backup.preview.readingCount, 1);

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
  });
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
