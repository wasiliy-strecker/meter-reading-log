import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/persistence/app_database.dart';
import 'package:meter_reading_log/features/meters/data/drift_meter_repositories.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

void main() {
  late AppDatabase database;
  late DriftMeterRepository meters;
  late DriftMeterReadingRepository readings;

  setUp(() {
    database = AppDatabase.memory();
    meters = DriftMeterRepository(database);
    readings = DriftMeterReadingRepository(database);
  });

  tearDown(() => database.close());

  test('persists meter, reading and append-only revision', () async {
    final meter = _meter();
    await meters.save(meter);
    final reading = _reading(meter);
    await readings.save(reading);
    final updated = reading.copyWith(
      value: ReadingValue.tryParse('124,0'),
      updatedAt: DateTime.utc(2026, 8, 31, 12),
      manifestSha256: 'changed',
    );
    await readings.updateWithRevision(
      updated,
      ReadingRevision(
        id: 'revision_1',
        readingId: reading.id,
        changedAt: DateTime.utc(2026, 8, 31, 12),
        reason: 'Tippfehler',
        changes: const {
          'Zählerstand': ReadingChange(before: '123,4', after: '124,0'),
        },
      ),
    );

    expect((await meters.findById(meter.id))?.label, 'Strom Keller');
    expect((await readings.findById(reading.id))?.value.displayText, '124,0');
    final restored = (await readings.findById(reading.id))!;
    expect(restored.photoHistory, hasLength(1));
    expect(restored.photoHistory.single.sha256, 'c' * 64);
    final revisions = await readings.loadRevisions(reading.id);
    expect(revisions, hasLength(1));
    expect(revisions.single.reason, 'Tippfehler');
  });
}

Meter _meter() => Meter(
  id: 'meter_1',
  label: 'Strom Keller',
  type: MeterType.electricity,
  unit: 'kWh',
  meterNumber: 'ABC123',
  location: 'Keller',
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

MeterReading _reading(Meter meter) => MeterReading(
  id: 'reading_1',
  meterId: meter.id,
  meter: MeterSnapshot.fromMeter(meter),
  value: ReadingValue.tryParse('123,4')!,
  capturedAt: DateTime.utc(2026, 8, 31, 10),
  timezoneOffsetMinutes: 120,
  storedAt: DateTime.utc(2026, 8, 31, 10),
  updatedAt: DateTime.utc(2026, 8, 31, 10),
  source: ReadingSource.camera,
  photoPath: '/tmp/photo.jpg',
  photoSha256: 'a' * 64,
  ocrRawText: '00123,4 kWh',
  ocrCandidate: '00123,4',
  ocrConfidence: 0.9,
  photoAddedAt: DateTime.utc(2026, 8, 31, 10),
  photoHistory: [
    ReadingPhotoVersion(
      id: 'photo_version_1',
      path: '/tmp/older.jpg',
      sha256: 'c' * 64,
      source: ReadingSource.gallery,
      addedAt: DateTime.utc(2026, 8, 30, 10),
      ocrRawText: '122,0 kWh',
      ocrCandidate: '122,0',
      ocrConfidence: 0.8,
    ),
  ],
  manifestSha256: 'b' * 64,
);
