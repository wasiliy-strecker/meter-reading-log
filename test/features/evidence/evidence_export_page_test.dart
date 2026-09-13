import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/persistence/app_database.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export_page.dart';
import 'package:meter_reading_log/features/meters/data/drift_meter_repositories.dart';
import 'package:meter_reading_log/features/meters/data/in_memory_meter_repositories.dart';

void main() {
  test(
    '100 exports: bounded pages agree, filter and sort ties consistently',
    () async {
      final database = AppDatabase.memory();
      final memory = InMemoryEvidenceExportRepository();
      addTearDown(database.close);
      addTearDown(memory.dispose);
      final drift = DriftEvidenceExportRepository(database);
      final exports = List.generate(100, exportFixture)
        ..sort(compareExportsNewestFirst);
      for (final repository in [drift, memory]) {
        for (final export in exports) {
          await repository.save(export);
        }
        await repository.save(exportFixture(101, meterId: 'other'));
        await repository.save(
          exportFixture(102, kind: EvidenceExportKind.singleReading),
        );
        final seen = <String>[];
        for (var offset = 0; offset < 100; offset += 5) {
          final page = await repository
              .watchPageForMeter(
                'meter',
                kind: EvidenceExportKind.meterHistory,
                limit: 5,
                offset: offset,
              )
              .first;
          expect(page.totalCount, 100);
          expect(page.offset, offset);
          expect(page.exports.length, 5);
          expect(page.hasMore, offset < 95);
          seen.addAll(page.exports.map((e) => e.id));
        }
        expect(seen, exports.map((e) => e.id));
        expect(seen.toSet().length, 100);
        final empty = await repository
            .watchPageForMeter(
              'absent',
              kind: EvidenceExportKind.meterHistory,
              limit: 5,
            )
            .first;
        expect(empty.totalCount, 0);
        expect(empty.exports, isEmpty);
        expect(empty.hasMore, isFalse);
        final pastEnd = await repository
            .watchPageForMeter(
              'meter',
              kind: EvidenceExportKind.meterHistory,
              limit: 5,
              offset: 100,
            )
            .first;
        expect(pastEnd.exports, isEmpty);
        expect(pastEnd.totalCount, 100);
        await expectLater(
          () => repository
              .watchPageForMeter(
                'meter',
                kind: EvidenceExportKind.meterHistory,
                limit: 0,
              )
              .first,
          throwsArgumentError,
        );
        await expectLater(
          () => repository
              .watchPageForMeter(
                'meter',
                kind: EvidenceExportKind.meterHistory,
                limit: 5,
                offset: -1,
              )
              .first,
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'Drift only deserializes the requested page, not older exports',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = DriftEvidenceExportRepository(database);
      for (var i = 0; i < 100; i++) {
        await repository.save(exportFixture(i));
      }
      // An unreadable older fixture would fail an eager, unbounded load.
      await (database.update(
        database.evidenceExportRecords,
      )..where((r) => r.id.equals('export_000'))).write(
        const EvidenceExportRecordsCompanion(
          readingIdsJson: Value('invalid fixture JSON'),
        ),
      );
      final page = await repository
          .watchPageForMeter(
            'meter',
            kind: EvidenceExportKind.meterHistory,
            limit: 5,
          )
          .first;
      expect(page.totalCount, 100);
      expect(page.exports.map((e) => e.id), [
        'export_099',
        'export_098',
        'export_097',
        'export_096',
        'export_095',
      ]);
    },
  );

  for (final useDrift in [true, false]) {
    test(
      '${useDrift ? 'Drift' : 'memory'} page reacts to deleting final entry',
      () async {
        final database = AppDatabase.memory();
        final memory = InMemoryEvidenceExportRepository();
        addTearDown(database.close);
        addTearDown(memory.dispose);
        final repository = useDrift
            ? DriftEvidenceExportRepository(database)
            : memory;
        for (var i = 0; i < 6; i++) {
          await repository.save(exportFixture(i));
        }
        final events = <EvidenceExportPage>[];
        final subscription = repository
            .watchPageForMeter(
              'meter',
              kind: EvidenceExportKind.meterHistory,
              limit: 5,
              offset: 5,
            )
            .listen(events.add);
        addTearDown(subscription.cancel);
        await pumpEventQueue();
        expect(events.last.totalCount, 6);
        expect(events.last.exports.single.id, 'export_000');
        await repository.delete('export_000');
        await pumpEventQueue();
        expect(events.last.totalCount, 5);
        expect(events.last.exports, isEmpty);
        await repository.save(exportFixture(6));
        await pumpEventQueue();
        expect(events.last.totalCount, 6);
        expect(events.last.exports.single.id, 'export_001');
      },
    );
  }
}

EvidenceExportRecord exportFixture(
  int index, {
  String meterId = 'meter',
  EvidenceExportKind kind = EvidenceExportKind.meterHistory,
}) {
  final suffix = index.toString().padLeft(3, '0');
  return EvidenceExportRecord(
    id: 'export_$suffix',
    meterId: meterId,
    kind: kind,
    readingIds: const ['reading'],
    createdAt: DateTime.utc(2026, 9, 1).add(Duration(minutes: index ~/ 10)),
    fileName: '$suffix.pdf',
    filePath: '/synthetic/$suffix.pdf',
    pdfSha256: 'a' * 64,
    manifestSha256: 'b' * 64,
  );
}
