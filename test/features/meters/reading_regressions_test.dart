import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:meter_reading_log/core/files/meter_photo_repository.dart';
import 'package:meter_reading_log/core/integrity/integrity_service.dart';
import 'package:meter_reading_log/core/persistence/app_database.dart';
import 'package:meter_reading_log/features/evidence/application/evidence_report_service.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/meters/application/meter_services.dart';
import 'package:meter_reading_log/features/meters/data/drift_meter_repositories.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';

import '../../support/fakes.dart';
import '../../support/reading_fixtures.dart';

void main() {
  test(
    'SQLite preserves every manifest timestamp and sub-millisecond order',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final repository = DriftMeterReadingRepository(db);
      const integrity = IntegrityService();
      var original = readingFixture();
      original = original.copyWith(
        manifestSha256: await integrity.readingManifestHash(original),
      );
      await repository.save(original);
      final loaded = (await repository.findById(original.id))!;
      expect(loaded.toJson(), original.toJson());
      expect(
        await integrity.readingManifestHash(loaded),
        original.manifestSha256,
      );

      final earlier = readingFixture(
        id: 'z-earlier',
        time: preciseTime.subtract(const Duration(microseconds: 1)),
      );
      await repository.save(earlier);
      final first = await repository.watchPageForMeter('meter', limit: 1).first;
      final second = await repository
          .watchPageForMeter('meter', limit: 1, offset: 1)
          .first;
      expect(first.readings.single.id, original.id);
      expect(first.olderNeighbor!.id, earlier.id);
      expect(second.readings.single.id, earlier.id);
      await repository.updateWithRevision(
        loaded,
        ReadingRevision(
          id: 'revision',
          readingId: loaded.id,
          changedAt: preciseTime,
          reason: '',
          changes: const {},
        ),
      );
      expect(
        (await repository.loadRevisions(loaded.id)).single.changedAt,
        preciseTime,
      );
    },
  );

  test(
    'note correction preserves capture offset and PDF time; time correction records offset',
    () async {
      final readings = MemoryReadingRepository();
      final exports = MemoryEvidenceExportRepository();
      final service = makeService(readings, exports);
      final original = readingFixture();
      final before = EvidenceReportService.readingTimeText(
        original,
        DateFormat('yyyy-MM-dd HH:mm'),
      );
      final updated = await service.update(
        existing: original,
        value: original.value,
        capturedAt: original.capturedAt.toLocal(),
        note: 'Neue Notiz',
        reason: '',
      );
      expect(updated.timezoneOffsetMinutes, 540);
      expect(
        EvidenceReportService.readingTimeText(
          updated,
          DateFormat('yyyy-MM-dd HH:mm'),
        ),
        before,
      );
      expect(readings.revisions[original.id]!.single.changes.keys, ['Notiz']);
      expect(readings.revisions[original.id]!.single.reason, isEmpty);

      final changed = await service.update(
        existing: updated,
        value: updated.value,
        capturedAt: updated.capturedAt.add(const Duration(hours: 1)),
        note: updated.note,
        reason: 'Uhrzeit berichtigt',
      );
      expect(changed.timezoneOffsetMinutes, 0);
      final changes = readings.revisions[original.id]!.last.changes;
      expect(changes, contains('Zeitpunkt der Ablesung'));
      expect(changes['Zeitzone der Ablesung']!.before, 'UTC+09:00');
      expect(changes['Zeitzone der Ablesung']!.after, 'UTC+00:00');
    },
  );

  test(
    'deleting a reading removes its single PDFs, including missing files, but keeps history',
    () async {
      final temp = await Directory.systemTemp.createTemp('reading_pdf_delete_');
      addTearDown(() => temp.delete(recursive: true));
      final readings = MemoryReadingRepository()
        ..items['reading'] = readingFixture();
      final exports = MemoryEvidenceExportRepository();
      for (final entry in [
        exportFixture(temp, 'single'),
        exportFixture(temp, 'missing'),
        exportFixture(temp, 'history', kind: EvidenceExportKind.meterHistory),
        exportFixture(temp, 'other', readingId: 'other-reading'),
      ]) {
        await exports.save(entry);
        if (entry.id != 'missing') {
          await File(entry.filePath).writeAsString('Synthetic PDF');
        }
      }
      final photos = TrackingPhotos();
      await makeService(
        readings,
        exports,
        photos: photos,
      ).delete(readingFixture());
      expect(readings.items, isEmpty);
      expect(
        photos.deleted,
        containsAll(['/synthetic/current.jpg', '/synthetic/old.jpg']),
      );
      expect(exports.items.keys, unorderedEquals(['history', 'other']));
      expect(await File('${temp.path}/single.pdf').exists(), isFalse);
      expect(await File('${temp.path}/history.pdf').exists(), isTrue);
      expect(await File('${temp.path}/other.pdf').exists(), isTrue);
    },
  );

  test(
    'PDF deletion failure keeps reading and photos available for retry',
    () async {
      final temp = await Directory.systemTemp.createTemp('reading_pdf_retry_');
      addTearDown(() => temp.delete(recursive: true));
      final reading = readingFixture();
      final readings = MemoryReadingRepository()..items[reading.id] = reading;
      final exports = MemoryEvidenceExportRepository();
      final export = exportFixture(temp, 'single');
      await exports.save(export);
      await File(export.filePath).writeAsString('Synthetic PDF');
      final reports = FailingReports(exports);
      final photos = TrackingPhotos();
      final service = makeService(
        readings,
        exports,
        photos: photos,
        reports: reports,
      );
      await expectLater(
        service.delete(reading),
        throwsA(isA<FileSystemException>()),
      );
      expect(readings.items, contains(reading.id));
      expect(photos.deleted, isEmpty);
      reports.fail = false;
      await service.delete(reading);
      expect(readings.items, isEmpty);
      expect(exports.items, isEmpty);
      expect(await File(export.filePath).exists(), isFalse);
    },
  );
}

MeterReadingService makeService(
  MemoryReadingRepository readings,
  MemoryEvidenceExportRepository exports, {
  TrackingPhotos? photos,
  EvidenceReportService? reports,
}) => MeterReadingService(
  meters: MemoryMeterRepository()..items['meter'] = meterFixture(),
  readings: readings,
  exports: exports,
  evidenceReports: reports ?? EvidenceReportService(exports: exports),
  photos: photos ?? TrackingPhotos(),
  reminders: NoopMeterReminderRepository(),
);

class TrackingPhotos implements MeterPhotoCaptureRepository {
  final deleted = <String>[];
  @override
  Future<StoredMeterPhoto?> capture(ReadingSource source) async => null;
  @override
  Future<StoredMeterPhoto?> recoverLostCapture() async => null;
  @override
  Future<void> delete(String path) async {
    deleted.add(path);
  }
}

class FailingReports extends EvidenceReportService {
  FailingReports(MemoryEvidenceExportRepository repository)
    : super(exports: repository);
  bool fail = true;
  @override
  Future<void> delete(EvidenceExportRecord record) async {
    if (fail) throw const FileSystemException('Synthetic deletion failure');
    await super.delete(record);
  }
}
