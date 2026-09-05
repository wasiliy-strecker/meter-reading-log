import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/files/meter_photo_repository.dart';
import 'package:meter_reading_log/core/ocr/meter_ocr_repository.dart';
import 'package:meter_reading_log/features/meters/application/meter_services.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import '../../support/fakes.dart';

void main() {
  test(
    'photo correction archives original and records integrity change',
    () async {
      final repository = MemoryReadingRepository();
      final meters = MemoryMeterRepository();
      final photos = _TrackingPhotoRepository();
      final reminders = NoopMeterReminderRepository();
      final service = MeterReadingService(
        meters: meters,
        readings: repository,
        photos: photos,
        reminders: reminders,
      );
      final existing = _reading();
      meters.items[existing.meterId] = Meter(
        id: existing.meter.id,
        label: existing.meter.label,
        type: existing.meter.type,
        unit: existing.meter.unit,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 1),
        reminder: const ReadingReminderSchedule(
          interval: ReminderInterval.daily,
          day: 1,
          hour: 9,
          minute: 0,
        ),
      );
      await repository.save(existing);
      final capturedAt = existing.capturedAt.toLocal();

      final updated = await service.update(
        existing: existing,
        value: ReadingValue.tryParse('124,8')!,
        capturedAt: capturedAt,
        note: 'Neues Foto geprüft',
        reason: 'Foto war unscharf',
        replacementPhoto: StoredMeterPhoto(
          path: '/tmp/new.jpg',
          sha256: 'c' * 64,
          source: ReadingSource.gallery,
          capturedAt: DateTime.utc(2026, 9, 2, 12),
        ),
        replacementOcr: const MeterOcrResult(
          rawText: '124,8 kWh',
          candidates: [],
          confidence: 0.88,
        ),
        replacementCandidate: '124,8',
      );

      expect(updated.capturedAt, existing.capturedAt);
      expect(updated.photoPath, '/tmp/new.jpg');
      expect(updated.photoSha256, 'c' * 64);
      expect(updated.photoHistory, hasLength(1));
      expect(updated.photoHistory.single.path, '/tmp/original.jpg');
      expect(updated.photoHistory.single.sha256, 'a' * 64);
      expect(updated.manifestSha256, hasLength(64));
      expect(photos.deleted, isEmpty);
      expect(reminders.scheduledLatestReadings.last?.id, updated.id);

      final revisions = await repository.loadRevisions(existing.id);
      expect(revisions, hasLength(1));
      expect(
        revisions.single.changes,
        contains('Prüfwert des Fotos (SHA-256)'),
      );
      expect(revisions.single.changes, contains('OCR-Kandidat'));

      await service.delete(updated);
      expect(
        photos.deleted,
        containsAll(['/tmp/original.jpg', '/tmp/new.jpg']),
      );
      expect(reminders.scheduledLatestReadings.last, isNull);
    },
  );
}

class _TrackingPhotoRepository implements MeterPhotoCaptureRepository {
  final List<String> deleted = [];

  @override
  Future<StoredMeterPhoto?> capture(ReadingSource source) async => null;

  @override
  Future<void> delete(String path) async => deleted.add(path);

  @override
  Future<StoredMeterPhoto?> recoverLostCapture() async => null;
}

MeterReading _reading() {
  final meter = Meter(
    id: 'meter_1',
    label: 'Strom Keller',
    type: MeterType.electricity,
    unit: 'kWh',
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );
  return MeterReading(
    id: 'reading_1',
    meterId: meter.id,
    meter: MeterSnapshot.fromMeter(meter),
    value: ReadingValue.tryParse('123,4')!,
    capturedAt: DateTime.utc(2026, 8, 31, 10),
    timezoneOffsetMinutes: 120,
    storedAt: DateTime.utc(2026, 8, 31, 10),
    updatedAt: DateTime.utc(2026, 8, 31, 10),
    source: ReadingSource.camera,
    photoPath: '/tmp/original.jpg',
    photoSha256: 'a' * 64,
    photoAddedAt: DateTime.utc(2026, 8, 31, 10),
    ocrRawText: '123,4 kWh',
    ocrCandidate: '123,4',
    ocrConfidence: 0.9,
    manifestSha256: 'b' * 64,
  );
}
