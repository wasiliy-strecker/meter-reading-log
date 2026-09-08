import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meter_reading_log/core/files/evidence_photo_asset_repository.dart';
import 'package:meter_reading_log/features/evidence/application/evidence_report_service.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import '../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('older export JSON defaults to the legacy all-photo mode', () {
    final record = EvidenceExportRecord.fromJson({
      'id': 'legacy',
      'meterId': 'meter',
      'kind': 'singleReading',
      'readingIds': <String>['reading'],
      'createdAt': DateTime.utc(2026, 9, 1).toIso8601String(),
      'fileName': 'legacy.pdf',
      'filePath': '/tmp/legacy.pdf',
      'pdfSha256': 'a' * 64,
      'manifestSha256': 'b' * 64,
    });

    expect(record.photoMode, EvidencePhotoMode.allPhotos);
  });

  test('deletes the PDF file and its stored export record', () async {
    final temp = await Directory.systemTemp.createTemp('delete_evidence_test_');
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}/single.pdf');
    await file.writeAsBytes(const [0x25, 0x50, 0x44, 0x46]);
    final repository = MemoryEvidenceExportRepository();
    final record = _export(file.path);
    await repository.save(record);
    final service = EvidenceReportService(exports: repository);

    await service.delete(record);

    expect(await file.exists(), isFalse);
    expect(repository.items, isNot(contains(record.id)));
  });

  test(
    'deletes the stored record when the PDF file is already missing',
    () async {
      final repository = MemoryEvidenceExportRepository();
      final record = _export('/tmp/missing-evidence-report.pdf');
      await repository.save(record);
      final service = EvidenceReportService(exports: repository);

      await service.delete(record);

      expect(repository.items, isNot(contains(record.id)));
    },
  );

  test(
    'creates a persistent single-reading PDF with internal hashes',
    () async {
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
      expect(report.record.pdfSha256, hasLength(64));
      expect(report.record.manifestSha256, hasLength(64));
    },
  );

  test(
    'allows repeated single-reading PDFs without overwriting files',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'duplicate_evidence_test_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final photo = File('${temp.path}/photo.jpg');
      await photo.writeAsBytes(img.encodeJpg(img.Image(width: 20, height: 20)));
      final repository = MemoryEvidenceExportRepository();
      final service = EvidenceReportService(
        exports: repository,
        documentsDirectoryProvider: () async => temp,
      );
      final reading = _reading(photo.path);

      final first = await service.createSingle(
        reading: reading,
        revisions: const [],
      );
      final second = await service.createSingle(
        reading: reading,
        revisions: const [],
      );

      expect(repository.items, hasLength(2));
      expect(second.record.id, isNot(first.record.id));
      expect(second.record.filePath, isNot(first.record.filePath));
      expect(await File(first.record.filePath).exists(), isTrue);
      expect(await File(second.record.filePath).exists(), isTrue);
    },
  );

  test('a correction changes the single-reading evidence manifest', () async {
    final temp = await Directory.systemTemp.createTemp('manifest_test_');
    addTearDown(() => temp.delete(recursive: true));
    final reading = _reading('${temp.path}/not-needed.jpg');
    final service = EvidenceReportService(
      exports: MemoryEvidenceExportRepository(),
      documentsDirectoryProvider: () async => temp,
    );
    final before = await service.createSingle(
      reading: reading,
      revisions: const [],
      photoMode: EvidencePhotoMode.withoutPhotos,
    );
    final after = await service.createSingle(
      reading: reading,
      revisions: [
        ReadingRevision(
          id: 'revision_after_export',
          readingId: reading.id,
          changedAt: DateTime.utc(2026, 9, 5, 11),
          reason: 'Zählerstand korrigiert',
          changes: const {
            'Zählerstand': ReadingChange(before: '00123,3', after: '00123,4'),
          },
        ),
      ],
      photoMode: EvidencePhotoMode.withoutPhotos,
    );

    expect(after.record.manifestSha256, isNot(before.record.manifestSha256));
  });

  test('new readings and corrections change the history manifest', () async {
    final temp = await Directory.systemTemp.createTemp('history_hash_test_');
    addTearDown(() => temp.delete(recursive: true));
    final first = _reading('${temp.path}/first-not-needed.jpg');
    final second = _reading(
      '${temp.path}/second-not-needed.jpg',
      id: 'reading_2',
      capturedAt: DateTime.utc(2026, 9, 1, 10),
      storedAt: DateTime.utc(2026, 9, 1, 10),
    );
    final service = EvidenceReportService(
      exports: MemoryEvidenceExportRepository(),
      documentsDirectoryProvider: () async => temp,
    );
    final initial = await service.createHistory(
      meter: _meter(),
      readings: [first],
      revisions: {first.id: const []},
      photoMode: EvidencePhotoMode.withoutPhotos,
    );
    final withReading = await service.createHistory(
      meter: _meter(),
      readings: [second, first],
      revisions: {first.id: const [], second.id: const []},
      photoMode: EvidencePhotoMode.withoutPhotos,
    );
    final withCorrection = await service.createHistory(
      meter: _meter(),
      readings: [first],
      revisions: {
        first.id: [
          ReadingRevision(
            id: 'history_revision',
            readingId: first.id,
            changedAt: DateTime.utc(2026, 9, 5, 11),
            reason: 'Zählerstand korrigiert',
            changes: const {
              'Zählerstand': ReadingChange(before: '00123,3', after: '00123,4'),
            },
          ),
        ],
      },
      photoMode: EvidencePhotoMode.withoutPhotos,
    );

    expect(
      withReading.record.manifestSha256,
      isNot(initial.record.manifestSha256),
    );
    expect(
      withCorrection.record.manifestSha256,
      isNot(initial.record.manifestSha256),
    );
  });

  test('allows repeated history PDFs and uses current meter data', () async {
    final temp = await Directory.systemTemp.createTemp(
      'duplicate_history_test_',
    );
    addTearDown(() => temp.delete(recursive: true));
    final repository = MemoryEvidenceExportRepository();
    final service = EvidenceReportService(
      exports: repository,
      documentsDirectoryProvider: () async => temp,
    );
    final reading = _reading('${temp.path}/not-needed.jpg');
    final first = await service.createHistory(
      meter: _meter(location: 'Alter Standort'),
      readings: [reading],
      revisions: {reading.id: const []},
      photoMode: EvidencePhotoMode.withoutPhotos,
    );
    final second = await service.createHistory(
      meter: _meter(label: 'Strom Neu', location: 'Neuer Standort'),
      readings: [reading],
      revisions: {reading.id: const []},
      photoMode: EvidencePhotoMode.withoutPhotos,
    );

    expect(repository.items, hasLength(2));
    expect(second.record.filePath, isNot(first.record.filePath));
    expect(second.record.fileName, contains('strom_neu'));
    expect(second.record.manifestSha256, isNot(first.record.manifestSha256));
  });

  test('allows history recreation when the matching PDF is missing', () async {
    final temp = await Directory.systemTemp.createTemp('missing_history_test_');
    addTearDown(() => temp.delete(recursive: true));
    final repository = MemoryEvidenceExportRepository();
    final service = EvidenceReportService(
      exports: repository,
      documentsDirectoryProvider: () async => temp,
    );
    final reading = _reading('/tmp/photo.jpg');
    repository.items['missing_history'] = EvidenceExportRecord(
      id: 'missing_history',
      meterId: reading.meterId,
      kind: EvidenceExportKind.meterHistory,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 9, 5, 10),
      fileName: 'missing.pdf',
      filePath: '${temp.path}/missing.pdf',
      pdfSha256: 'c' * 64,
      manifestSha256: 'd' * 64,
      photoMode: EvidencePhotoMode.withoutPhotos,
    );

    final report = await service.createHistory(
      meter: _meter(),
      readings: [reading],
      revisions: {reading.id: const []},
      photoMode: EvidencePhotoMode.withoutPhotos,
    );

    expect(await File(report.record.filePath).exists(), isTrue);
    expect(repository.items, hasLength(2));
  });

  test(
    'allows recreation when a matching single-reading PDF is missing',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'missing_evidence_test_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final photo = File('${temp.path}/photo.jpg');
      await photo.writeAsBytes(img.encodeJpg(img.Image(width: 20, height: 20)));
      final repository = MemoryEvidenceExportRepository();
      final service = EvidenceReportService(
        exports: repository,
        documentsDirectoryProvider: () async => temp,
      );
      final reading = _reading(photo.path);
      repository.items['missing'] = EvidenceExportRecord(
        id: 'missing',
        meterId: reading.meterId,
        kind: EvidenceExportKind.singleReading,
        readingIds: [reading.id],
        createdAt: DateTime.utc(2026, 9, 5, 10),
        fileName: 'missing.pdf',
        filePath: '${temp.path}/missing.pdf',
        pdfSha256: 'c' * 64,
        manifestSha256: 'd' * 64,
      );

      final report = await service.createSingle(
        reading: reading,
        revisions: const [],
      );

      expect(await File(report.record.filePath).exists(), isTrue);
      expect(repository.items, hasLength(2));
    },
  );

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

  test('compact PDFs never prepare or read a photo', () async {
    final temp = await Directory.systemTemp.createTemp('compact_pdf_test_');
    addTearDown(() => temp.delete(recursive: true));
    final photoAssets = _RecordingPhotoAssets();
    final service = EvidenceReportService(
      exports: MemoryEvidenceExportRepository(),
      documentsDirectoryProvider: () async => temp,
      photoAssets: photoAssets,
    );

    final report = await service.createSingle(
      reading: _reading('${temp.path}/does-not-exist.jpg'),
      revisions: const [],
      photoMode: EvidencePhotoMode.withoutPhotos,
    );

    expect(photoAssets.prepared, isEmpty);
    expect(report.record.photoMode, EvidencePhotoMode.withoutPhotos);
    expect(report.record.fileName, contains('_kompakt_'));
    expect(report.bytes.take(4), [0x25, 0x50, 0x44, 0x46]);
  });

  test('current-photo PDFs prepare only the current photo', () async {
    final temp = await Directory.systemTemp.createTemp('current_pdf_test_');
    addTearDown(() => temp.delete(recursive: true));
    final current = File('${temp.path}/current.jpg');
    final archived = File('${temp.path}/archived.jpg');
    await current.writeAsBytes(img.encodeJpg(img.Image(width: 20, height: 20)));
    await archived.writeAsBytes(
      img.encodeJpg(img.Image(width: 18, height: 18)),
    );
    final reading = _reading(current.path).copyWith(
      photoHistory: [
        ReadingPhotoVersion(
          id: 'archived',
          path: archived.path,
          sha256: 'c' * 64,
          source: ReadingSource.gallery,
          addedAt: DateTime.utc(2026, 9, 1),
          ocrRawText: '',
          ocrCandidate: '',
        ),
      ],
    );
    final photoAssets = _RecordingPhotoAssets();
    final service = EvidenceReportService(
      exports: MemoryEvidenceExportRepository(),
      documentsDirectoryProvider: () async => temp,
      photoAssets: photoAssets,
    );

    final report = await service.createSingle(
      reading: reading,
      revisions: const [],
      photoMode: EvidencePhotoMode.currentPhotos,
    );

    expect(photoAssets.prepared, [(path: current.path, sha256: 'a' * 64)]);
    expect(report.record.fileName, contains('_mit_fotos_'));
  });

  test('all PDF variants can be created repeatedly', () async {
    final temp = await Directory.systemTemp.createTemp('variant_pdf_test_');
    addTearDown(() => temp.delete(recursive: true));
    final photo = File('${temp.path}/photo.jpg');
    await photo.writeAsBytes(img.encodeJpg(img.Image(width: 20, height: 20)));
    final repository = MemoryEvidenceExportRepository();
    final service = EvidenceReportService(
      exports: repository,
      documentsDirectoryProvider: () async => temp,
      photoAssets: _RecordingPhotoAssets(),
    );
    final reading = _reading(photo.path);

    final compactFirst = await service.createSingle(
      reading: reading,
      revisions: const [],
      photoMode: EvidencePhotoMode.withoutPhotos,
    );
    final photoFirst = await service.createSingle(
      reading: reading,
      revisions: const [],
      photoMode: EvidencePhotoMode.currentPhotos,
    );
    final compactSecond = await service.createSingle(
      reading: reading,
      revisions: const [],
      photoMode: EvidencePhotoMode.withoutPhotos,
    );
    final photoSecond = await service.createSingle(
      reading: reading,
      revisions: const [],
      photoMode: EvidencePhotoMode.currentPhotos,
    );

    expect(repository.items, hasLength(4));
    expect(compactSecond.record.filePath, isNot(compactFirst.record.filePath));
    expect(photoSecond.record.filePath, isNot(photoFirst.record.filePath));
  });
}

class _RecordingPhotoAssets implements EvidencePhotoAssetRepository {
  final List<({String path, String sha256})> prepared = [];

  @override
  Future<String?> prepare({
    required String path,
    required String sha256,
  }) async {
    prepared.add((path: path, sha256: sha256));
    return path;
  }

  @override
  Future<void> delete(String sha256) async {}
}

EvidenceExportRecord _export(String filePath) => EvidenceExportRecord(
  id: 'evidence_1',
  meterId: 'meter_1',
  kind: EvidenceExportKind.singleReading,
  readingIds: const ['reading_1'],
  createdAt: DateTime.utc(2026, 9, 7),
  fileName: 'single.pdf',
  filePath: filePath,
  pdfSha256: 'c' * 64,
  manifestSha256: 'd' * 64,
);

MeterReading _reading(
  String photoPath, {
  String id = 'reading_1',
  DateTime? capturedAt,
  DateTime? storedAt,
}) {
  final persistedAt = storedAt ?? DateTime.utc(2026, 8, 31, 10);
  final meter = _meter();
  return MeterReading(
    id: id,
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

Meter _meter({String label = 'Strom Keller', String location = ''}) => Meter(
  id: 'meter_1',
  label: label,
  type: MeterType.electricity,
  unit: 'kWh',
  meterNumber: 'EL-42',
  location: location,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 9, 8),
);
