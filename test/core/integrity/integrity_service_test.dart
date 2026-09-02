import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/integrity/integrity_service.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

void main() {
  test('canonical JSON is stable across map insertion order', () {
    const service = IntegrityService();
    final left = service.canonicalJson({
      'b': 2,
      'a': {'z': 1, 'c': 3},
    });
    final right = service.canonicalJson({
      'a': {'c': 3, 'z': 1},
      'b': 2,
    });

    expect(left, right);
  });

  test('SHA-256 matches known vector', () async {
    const service = IntegrityService();
    expect(
      await service.sha256Text('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test(
    'manifest ignores local paths but includes archived photo hash',
    () async {
      const service = IntegrityService();
      final reading = _reading();
      final relocated = reading.copyWith(
        photoPath: '/restored/current.jpg',
        photoHistory: [
          reading.photoHistory.single.copyWith(path: '/restored/old.jpg'),
        ],
      );
      final changedHash = reading.copyWith(
        photoHistory: [
          ReadingPhotoVersion(
            id: 'photo_1',
            path: '/tmp/old.jpg',
            sha256: 'd' * 64,
            source: ReadingSource.camera,
            addedAt: DateTime.utc(2026, 8, 1),
            ocrRawText: '9',
            ocrCandidate: '9',
          ),
        ],
      );

      expect(
        await service.readingManifestHash(reading),
        await service.readingManifestHash(relocated),
      );
      expect(
        await service.readingManifestHash(reading),
        isNot(await service.readingManifestHash(changedHash)),
      );
    },
  );

  test('legacy reading JSON loads without photo version fields', () {
    final json = _reading().toJson()
      ..remove('photoAddedAt')
      ..remove('photoHistory');

    final restored = MeterReading.fromJson(json);

    expect(restored.photoAddedAt, isNull);
    expect(restored.effectivePhotoAddedAt, restored.storedAt);
    expect(restored.photoHistory, isEmpty);
  });
}

MeterReading _reading() {
  final meter = Meter(
    id: 'meter_1',
    label: 'Test',
    type: MeterType.electricity,
    unit: 'kWh',
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );
  return MeterReading(
    id: 'reading_1',
    meterId: meter.id,
    meter: MeterSnapshot.fromMeter(meter),
    value: ReadingValue.tryParse('10')!,
    capturedAt: DateTime.utc(2026, 8, 1),
    timezoneOffsetMinutes: 120,
    storedAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
    source: ReadingSource.camera,
    photoPath: '/tmp/current.jpg',
    photoSha256: 'a' * 64,
    ocrRawText: '10',
    ocrCandidate: '10',
    photoHistory: [
      ReadingPhotoVersion(
        id: 'photo_1',
        path: '/tmp/old.jpg',
        sha256: 'c' * 64,
        source: ReadingSource.camera,
        addedAt: DateTime.utc(2026, 8, 1),
        ocrRawText: '9',
        ocrCandidate: '9',
      ),
    ],
    manifestSha256: '',
  );
}
