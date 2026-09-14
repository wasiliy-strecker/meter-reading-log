import 'dart:io';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

final preciseTime = DateTime.utc(2026, 9, 1, 12, 0, 0, 123, 456);
Meter meterFixture() => Meter(
  id: 'meter',
  label: 'Synthetischer Zähler',
  type: MeterType.electricity,
  unit: 'kWh',
  createdAt: preciseTime,
  updatedAt: preciseTime,
);
MeterReading readingFixture({String id = 'reading', DateTime? time}) =>
    MeterReading(
      id: id,
      meterId: 'meter',
      meter: MeterSnapshot.fromMeter(meterFixture()),
      value: ReadingValue.tryParse('12,3')!,
      capturedAt: time ?? preciseTime,
      timezoneOffsetMinutes: 540,
      storedAt: preciseTime,
      updatedAt: preciseTime,
      source: ReadingSource.camera,
      photoPath: '/synthetic/current.jpg',
      photoSha256: 'a' * 64,
      photoAddedAt: preciseTime,
      ocrRawText: '12,3',
      ocrCandidate: '12,3',
      note: 'Alt',
      photoHistory: [
        ReadingPhotoVersion(
          id: 'old-photo',
          path: '/synthetic/old.jpg',
          sha256: 'b' * 64,
          source: ReadingSource.gallery,
          addedAt: preciseTime,
          ocrRawText: '11',
          ocrCandidate: '11',
        ),
      ],
      manifestSha256: 'original-checksum',
    );
EvidenceExportRecord exportFixture(
  Directory directory,
  String id, {
  EvidenceExportKind kind = EvidenceExportKind.singleReading,
  String readingId = 'reading',
}) => EvidenceExportRecord(
  id: id,
  meterId: 'meter',
  kind: kind,
  readingIds: [readingId],
  createdAt: preciseTime,
  fileName: '$id.pdf',
  filePath: '${directory.path}/$id.pdf',
  pdfSha256: 'a' * 64,
  manifestSha256: 'b' * 64,
);
