import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/features/meters/application/reading_revision_photos.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

void main() {
  test('matches every photo correction to its before and after photo', () {
    final firstChange = DateTime.utc(2026, 9, 2, 10);
    final secondChange = DateTime.utc(2026, 9, 3, 10);
    final reading = _reading(
      currentAddedAt: secondChange,
      photoHistory: [
        _photo('original', '/tmp/original.jpg', 'a', DateTime.utc(2026, 9, 1)),
        _photo('first', '/tmp/first.jpg', 'b', firstChange),
      ],
    );
    final firstRevision = _revision(
      id: 'revision_1',
      changedAt: firstChange,
      beforeHash: 'a',
      afterHash: 'b',
    );
    final secondRevision = _revision(
      id: 'revision_2',
      changedAt: secondChange,
      beforeHash: 'b',
      afterHash: 'c',
    );

    final firstPhotos = photosForRevision(
      reading: reading,
      revision: firstRevision,
    );
    final secondPhotos = photosForRevision(
      reading: reading,
      revision: secondRevision,
    );

    expect(firstPhotos?.before?.path, '/tmp/original.jpg');
    expect(firstPhotos?.after?.path, '/tmp/first.jpg');
    expect(secondPhotos?.before?.path, '/tmp/first.jpg');
    expect(secondPhotos?.after?.path, '/tmp/current.jpg');
  });

  test(
    'keeps a photo change visible when archived files cannot be matched',
    () {
      final reading = _reading(currentAddedAt: DateTime.utc(2026, 9, 3));
      final revision = _revision(
        id: 'revision_missing',
        changedAt: DateTime.utc(2026, 9, 3),
        beforeHash: 'missing-before',
        afterHash: 'missing-after',
      );

      final photos = photosForRevision(reading: reading, revision: revision);

      expect(photos, isNotNull);
      expect(photos?.before, isNull);
      expect(photos?.after, isNull);
    },
  );
}

MeterReading _reading({
  required DateTime currentAddedAt,
  List<ReadingPhotoVersion> photoHistory = const [],
}) {
  final meter = Meter(
    id: 'meter_1',
    label: 'Strom Keller',
    type: MeterType.electricity,
    unit: 'kWh',
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 1),
  );
  return MeterReading(
    id: 'reading_1',
    meterId: meter.id,
    meter: MeterSnapshot.fromMeter(meter),
    value: ReadingValue.tryParse('123,4')!,
    capturedAt: DateTime.utc(2026, 9, 1),
    timezoneOffsetMinutes: 120,
    storedAt: DateTime.utc(2026, 9, 1),
    updatedAt: currentAddedAt,
    source: ReadingSource.camera,
    photoPath: '/tmp/current.jpg',
    photoSha256: 'c',
    photoAddedAt: currentAddedAt,
    photoHistory: photoHistory,
    ocrRawText: '123,4',
    ocrCandidate: '123,4',
    manifestSha256: 'manifest',
  );
}

ReadingPhotoVersion _photo(
  String id,
  String path,
  String hash,
  DateTime addedAt,
) => ReadingPhotoVersion(
  id: id,
  path: path,
  sha256: hash,
  source: ReadingSource.camera,
  addedAt: addedAt,
  ocrRawText: '',
  ocrCandidate: '',
);

ReadingRevision _revision({
  required String id,
  required DateTime changedAt,
  required String beforeHash,
  required String afterHash,
}) => ReadingRevision(
  id: id,
  readingId: 'reading_1',
  changedAt: changedAt,
  reason: 'Foto korrigiert',
  changes: {
    'Prüfwert des Fotos (SHA-256)': ReadingChange(
      before: beforeHash,
      after: afterHash,
    ),
  },
);
