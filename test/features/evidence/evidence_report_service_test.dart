import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meter_reading_log/features/evidence/application/evidence_report_service.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import '../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates and verifies a persistent single-reading PDF', () async {
    final temp = await Directory.systemTemp.createTemp('evidence_test_');
    addTearDown(() => temp.delete(recursive: true));
    final photo = File('${temp.path}/photo.jpg');
    final olderPhoto = File('${temp.path}/older-photo.jpg');
    await photo.writeAsBytes(img.encodeJpg(img.Image(width: 20, height: 20)));
    await olderPhoto.writeAsBytes(
      img.encodeJpg(img.Image(width: 18, height: 18)),
    );
    final repository = MemoryEvidenceExportRepository();
    final service = EvidenceReportService(
      exports: repository,
      documentsDirectoryProvider: () async => temp,
    );
    final reading = _reading(photo.path).copyWith(
      photoHistory: [
        ReadingPhotoVersion(
          id: 'photo_version_1',
          path: olderPhoto.path,
          sha256: 'c' * 64,
          source: ReadingSource.gallery,
          addedAt: DateTime.utc(2026, 8, 30, 10),
          ocrRawText: '00122,9',
          ocrCandidate: '00122,9',
          ocrConfidence: 0.8,
        ),
      ],
    );

    final report = await service.createSingle(
      reading: reading,
      revisions: [
        ReadingRevision(
          id: 'revision_photo',
          readingId: reading.id,
          changedAt: reading.effectivePhotoAddedAt,
          reason: 'Foto war unscharf',
          changes: {
            'Prüfwert des Fotos (SHA-256)': ReadingChange(
              before: 'c' * 64,
              after: 'a' * 64,
            ),
          },
        ),
      ],
    );

    expect(report.bytes.take(4), [0x25, 0x50, 0x44, 0x46]);
    expect(await File(report.record.filePath).exists(), isTrue);
    final verified = await service.verify(report.record.filePath);
    expect(verified.status.name, 'unchanged');

    await File(report.record.filePath).writeAsString('changed');
    final changed = await service.verify(report.record.filePath);
    expect(changed.status.name, 'changed');
  });

  test('creates a PDF that includes future-at-storage evidence', () async {
    final temp = await Directory.systemTemp.createTemp('future_evidence_test_');
    addTearDown(() => temp.delete(recursive: true));
    final photo = File('${temp.path}/photo.jpg');
    await photo.writeAsBytes(img.encodeJpg(img.Image(width: 20, height: 20)));
    final service = EvidenceReportService(
      exports: MemoryEvidenceExportRepository(),
      documentsDirectoryProvider: () async => temp,
    );
    final reading = _reading(
      photo.path,
      capturedAt: DateTime.utc(2100, 1, 1),
      storedAt: DateTime.utc(2026, 9, 2),
    );

    final report = await service.createSingle(
      reading: reading,
      revisions: const [],
    );

    expect(report.bytes.take(4), [0x25, 0x50, 0x44, 0x46]);
    expect(futureReadingEvidenceNotice(reading), isNotNull);
  });

  test('creates a PDF with a readable correction history', () async {
    final temp = await Directory.systemTemp.createTemp('revision_pdf_test_');
    addTearDown(() => temp.delete(recursive: true));
    final photo = File('${temp.path}/photo.jpg');
    final firstPhoto = File('${temp.path}/first-photo.jpg');
    final originalPhoto = File('${temp.path}/original-photo.jpg');
    await photo.writeAsBytes(img.encodeJpg(img.Image(width: 20, height: 20)));
    await firstPhoto.writeAsBytes(
      img.encodeJpg(img.Image(width: 18, height: 18)),
    );
    await originalPhoto.writeAsBytes(
      img.encodeJpg(img.Image(width: 16, height: 16)),
    );
    final service = EvidenceReportService(
      exports: MemoryEvidenceExportRepository(),
      documentsDirectoryProvider: () async => temp,
    );
    final firstChange = DateTime.utc(2026, 9, 2, 12);
    final secondChange = DateTime.utc(2026, 9, 3, 12);
    final reading = _reading(photo.path).copyWith(
      photoAddedAt: secondChange,
      photoHistory: [
        ReadingPhotoVersion(
          id: 'photo_original',
          path: originalPhoto.path,
          sha256: 'c' * 64,
          source: ReadingSource.camera,
          addedAt: DateTime.utc(2026, 9, 1, 12),
          ocrRawText: '00132,4',
          ocrCandidate: '00132,4',
        ),
        ReadingPhotoVersion(
          id: 'photo_first_correction',
          path: firstPhoto.path,
          sha256: 'd' * 64,
          source: ReadingSource.gallery,
          addedAt: firstChange,
          ocrRawText: '00123,4',
          ocrCandidate: '00123,4',
        ),
      ],
    );

    final report = await service.createSingle(
      reading: reading,
      revisions: [
        ReadingRevision(
          id: 'revision_1',
          readingId: reading.id,
          changedAt: firstChange,
          reason: 'Zahlendreher berichtigt',
          changes: {
            'Zählerstand': const ReadingChange(
              before: '00132,4',
              after: '00123,4',
            ),
            'Prüfwert des Fotos (SHA-256)': ReadingChange(
              before: 'c' * 64,
              after: 'd' * 64,
            ),
            'OCR-Kandidat': const ReadingChange(
              before: '00132,4',
              after: '00123,4',
            ),
          },
        ),
        ReadingRevision(
          id: 'revision_2',
          readingId: reading.id,
          changedAt: secondChange,
          reason: 'Schärferes Foto ergänzt',
          changes: {
            'Prüfwert des Fotos (SHA-256)': ReadingChange(
              before: 'd' * 64,
              after: 'a' * 64,
            ),
          },
        ),
      ],
    );

    expect(report.bytes.take(4), [0x25, 0x50, 0x44, 0x46]);
    expect(await File(report.record.filePath).exists(), isTrue);
  });
}

MeterReading _reading(
  String photoPath, {
  DateTime? capturedAt,
  DateTime? storedAt,
}) {
  final persistedAt = storedAt ?? DateTime.utc(2026, 8, 31, 10);
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
    value: ReadingValue.tryParse('00123,4')!,
    capturedAt: capturedAt ?? DateTime.utc(2026, 8, 31, 10),
    timezoneOffsetMinutes: 120,
    storedAt: persistedAt,
    updatedAt: persistedAt,
    source: ReadingSource.camera,
    photoPath: photoPath,
    photoSha256: 'a' * 64,
    ocrRawText: '00123,4 kWh',
    ocrCandidate: '00123,4',
    ocrConfidence: 0.92,
    manifestSha256: 'b' * 64,
  );
}
