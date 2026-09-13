import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/integrity/integrity_service.dart';
import 'package:meter_reading_log/features/backup/application/encrypted_backup_service.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import '../support/fakes.dart';

/// Opt-in host-side fixture generator, never linked into the app.
/// First render the synthetic SVG meter illustrations using render.mjs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fixturePath = String.fromEnvironment('STORE_DEMO_DIR');
  test(
    'demo fixture round-trips values, matching photos and revision',
    () async {
      final root = Directory(fixturePath);
      final rows =
          (jsonDecode(await File('${root.path}/readings.json').readAsString())
                  as List)
              .cast<Map<String, dynamic>>();
      final meters = MemoryMeterRepository();
      final readings = MemoryReadingRepository();
      const integrity = IntegrityService();
      for (final row in rows) {
        final meterId = row['meterId'] as String;
        final meter = meters.items.putIfAbsent(
          meterId,
          () => Meter(
            id: meterId,
            label: row['label'] as String,
            type: MeterType.values.byName(row['type'] as String),
            unit: row['unit'] as String,
            meterNumber: 'DEMO-${meterId.toUpperCase()}',
            location: meterId == 'wasser' ? 'Badezimmer' : 'Zählerraum',
            createdAt: DateTime.utc(2025, 10, 1),
            updatedAt: DateTime.utc(2026, 9, 1),
          ),
        );
        final photo = File('${root.path}/${row['photo']}');
        final value = row['value'] as String;
        final at = DateTime.parse(row['date'] as String);
        var reading = MeterReading(
          id: '${meterId}_${at.year}_${at.month}',
          meterId: meterId,
          meter: MeterSnapshot.fromMeter(meter),
          value: ReadingValue.tryParse(value)!,
          capturedAt: at,
          timezoneOffsetMinutes: at.month >= 4 && at.month <= 9 ? 120 : 60,
          storedAt: at.add(const Duration(minutes: 2)),
          updatedAt: at.add(const Duration(minutes: 4)),
          source: ReadingSource.gallery,
          photoPath: photo.path,
          photoSha256: await integrity.sha256Bytes(await photo.readAsBytes()),
          ocrRawText: '',
          ocrCandidate: '',
          manifestSha256: '',
          note: 'Monatsablesung · Beispieldaten',
        );
        // No simulated OCR confidence: the synthetic historical values are manual.
        reading = reading.copyWith(
          manifestSha256: await integrity.readingManifestHash(reading),
        );
        await readings.save(reading);
      }
      await readings.saveRevision(
        ReadingRevision(
          id: 'demo-note-revision',
          readingId: 'strom_2026_9',
          changedAt: DateTime.utc(2026, 9, 1, 8, 4),
          reason: 'Notiz zur Monatsablesung ergänzt',
          changes: const {
            'Notiz': ReadingChange(
              before: 'Beispieldaten',
              after: 'Monatsablesung · Beispieldaten',
            ),
          },
        ),
      );
      final service = EncryptedBackupService(
        meters: meters,
        readings: readings,
        exports: MemoryEvidenceExportRepository(),
        reminders: NoopMeterReminderRepository(),
        temporaryDirectoryProvider: () async => root,
        documentsDirectoryProvider: () async => root,
      );
      final backup = await service.create('Demo2026');
      final delivery = await File(
        backup.path,
      ).copy('${root.path}/Demo.zslbackup');
      final restoredRoot = await Directory('${root.path}/roundtrip').create();
      final restoredMeters = MemoryMeterRepository();
      final restoredReadings = MemoryReadingRepository();
      final target = EncryptedBackupService(
        meters: restoredMeters,
        readings: restoredReadings,
        exports: MemoryEvidenceExportRepository(),
        reminders: NoopMeterReminderRepository(),
        temporaryDirectoryProvider: () async => restoredRoot,
        documentsDirectoryProvider: () async => restoredRoot,
      );
      await target.restore(delivery.path, 'Demo2026');
      expect(restoredMeters.items.length, 3);
      expect(restoredReadings.items.length, 24);
      expect((await restoredReadings.loadRevisions('strom_2026_9')).length, 1);
      for (final reading in restoredReadings.items.values) {
        final original = readings.items[reading.id]!;
        expect(reading.value.canonical, original.value.canonical);
        expect(
          await integrity.readingManifestHash(reading),
          reading.manifestSha256,
        );
        expect(
          await integrity.sha256Bytes(
            await File(reading.photoPath).readAsBytes(),
          ),
          original.photoSha256,
        );
      }
    },
    skip: fixturePath.isEmpty ? 'Opt-in store asset generator' : false,
  );
}
