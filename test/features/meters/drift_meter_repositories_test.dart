import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/persistence/app_database.dart';
import 'package:meter_reading_log/features/meters/data/drift_meter_repositories.dart';
import 'package:meter_reading_log/features/meters/data/in_memory_meter_repositories.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading_order.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

void main() {
  late AppDatabase database;
  late DriftMeterRepository meters;
  late DriftMeterReadingRepository readings;
  late DriftMeterDashboardRepository dashboard;

  setUp(() {
    database = AppDatabase.memory();
    meters = DriftMeterRepository(database);
    readings = DriftMeterReadingRepository(database);
    dashboard = DriftMeterDashboardRepository(database);
  });

  tearDown(() => database.close());

  test(
    'Drift and memory pages agree on equal timestamps without duplicates',
    () async {
      final memory = InMemoryMeterReadingRepository();
      addTearDown(memory.dispose);
      final meter = _meter();
      await meters.save(meter);
      final entries = List.generate(
        30,
        (i) => _historyReading(
          meter,
          index: i,
          capturedAt: DateTime.utc(2026, 9, 1),
          note: '',
        ),
      );
      for (final reading in entries) {
        await readings.save(reading);
        await memory.save(reading);
      }
      entries.sort(compareReadingsNewestFirst);
      for (final repository in [readings, memory]) {
        final first = await repository
            .watchPageForMeter(meter.id, limit: 20)
            .first;
        final second = await repository
            .watchPageForMeter(meter.id, limit: 20, offset: 20)
            .first;
        expect(
          [...first.readings, ...second.readings].map((r) => r.id),
          entries.map((r) => r.id),
        );
        expect(first.olderNeighbor!.id, second.readings.first.id);
        expect(second.latestReading!.id, entries.first.id);
        expect(second.hasMore, isFalse);
      }
    },
  );

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

  test('persists the PDF photo mode', () async {
    final exports = DriftEvidenceExportRepository(database);
    await exports.save(
      EvidenceExportRecord(
        id: 'export_1',
        meterId: 'meter_1',
        kind: EvidenceExportKind.meterHistory,
        readingIds: const ['reading_1'],
        createdAt: DateTime.utc(2026, 9, 5),
        fileName: 'history.pdf',
        filePath: '/tmp/history.pdf',
        pdfSha256: 'a' * 64,
        manifestSha256: 'b' * 64,
        photoMode: EvidencePhotoMode.currentPhotos,
      ),
    );

    expect(
      (await exports.loadAll()).single.photoMode,
      EvidencePhotoMode.currentPhotos,
    );
  });

  test(
    'dashboard query returns only the latest value and newest edit',
    () async {
      final meter = _meter();
      final emptyMeter = _meter().copyWith(label: 'Wasser Dach');
      await meters.save(meter);
      await meters.save(
        Meter(
          id: 'meter_2',
          label: emptyMeter.label,
          type: MeterType.water,
          unit: 'm³',
          meterNumber: '',
          location: 'Dach',
          createdAt: emptyMeter.createdAt,
          updatedAt: DateTime.utc(2026, 8, 2),
        ),
      );
      await readings.save(_reading(meter));
      await readings.save(
        MeterReading(
          id: 'reading_older_but_edited_later',
          meterId: meter.id,
          meter: MeterSnapshot.fromMeter(meter),
          value: ReadingValue.tryParse('100,0')!,
          capturedAt: DateTime.utc(2026, 8, 30, 10),
          timezoneOffsetMinutes: 120,
          storedAt: DateTime.utc(2026, 8, 30, 10),
          updatedAt: DateTime.utc(2026, 9, 3, 12),
          source: ReadingSource.camera,
          photoPath: '/tmp/older.jpg',
          photoSha256: 'd' * 64,
          ocrRawText: '100,0',
          ocrCandidate: '100,0',
          manifestSha256: 'e' * 64,
        ),
      );

      final items = await dashboard.watchAll().first;
      final electricity = items.singleWhere(
        (item) => item.meter.id == meter.id,
      );
      final empty = items.singleWhere((item) => item.meter.id == 'meter_2');

      expect(electricity.latestValue?.displayText, '123,4');
      expect(electricity.latestUnit, 'kWh');
      expect(electricity.lastEdited, DateTime.utc(2026, 9, 3, 12));
      expect(empty.latestValue, isNull);
      expect(empty.lastEdited, DateTime.utc(2026, 8, 2));
    },
  );

  test('creates the dashboard reading indexes', () async {
    final rows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'reading_meter_%_idx' ORDER BY name",
        )
        .get();

    expect(
      rows.map((row) => row.read<String>('name')),
      containsAll(['reading_meter_captured_idx', 'reading_meter_updated_idx']),
    );
  });

  test(
    'history page limits rows and searches value note and local date',
    () async {
      final meter = _meter();
      await meters.save(meter);
      final base = DateTime.utc(2026, 8, 1, 12);
      for (var index = 0; index < 45; index++) {
        await readings.save(
          _historyReading(
            meter,
            index: index,
            capturedAt: base.add(Duration(days: index)),
            note: index == 7 ? 'Seltener ÖLSTAND im Keller' : '',
          ),
        );
      }

      final firstPage = await readings
          .watchPageForMeter(meter.id, limit: 20)
          .first;

      expect(firstPage.readings, hasLength(20));
      expect(firstPage.totalCount, 45);
      expect(firstPage.matchingCount, 45);
      expect(firstPage.hasMore, isTrue);
      expect(firstPage.readings.first.id, 'history_44');
      expect(firstPage.readings.last.id, 'history_25');
      expect(firstPage.latestReading?.id, 'history_44');
      expect(firstPage.olderNeighbor?.id, 'history_24');

      final secondPage = await readings
          .watchPageForMeter(meter.id, limit: 20, offset: 20)
          .first;
      expect(secondPage.offset, 20);
      expect(secondPage.readings, hasLength(20));
      expect(secondPage.readings.first.id, 'history_24');
      expect(secondPage.readings.last.id, 'history_5');
      expect(secondPage.olderNeighbor?.id, 'history_4');
      expect(secondPage.latestReading?.id, 'history_44');
      expect(secondPage.hasMore, isTrue);
      final lastPage = await readings
          .watchPageForMeter(meter.id, limit: 20, offset: 40)
          .first;
      expect(lastPage.readings, hasLength(5));
      expect(lastPage.hasMore, isFalse);
      expect(lastPage.olderNeighbor, isNull);
      expect(
        {
          ...firstPage.readings,
          ...secondPage.readings,
          ...lastPage.readings,
        }.map((r) => r.id).toSet(),
        hasLength(45),
      );

      final valueMatch = await readings
          .watchPageForMeter(meter.id, limit: 20, query: '1044,0')
          .first;
      expect(valueMatch.readings.map((reading) => reading.id), ['history_44']);
      expect(valueMatch.totalCount, 45);
      expect(valueMatch.matchingCount, 1);
      expect(valueMatch.latestReading?.id, 'history_44');

      final noteMatch = await readings
          .watchPageForMeter(meter.id, limit: 20, query: 'ölstand')
          .first;
      expect(noteMatch.readings.map((reading) => reading.id), ['history_7']);

      final dateMatch = await readings
          .watchPageForMeter(meter.id, limit: 20, query: '07.09.2026')
          .first;
      expect(dateMatch.readings.map((reading) => reading.id), ['history_37']);
    },
  );

  test('history page stays bounded for 5000 readings of one meter', () async {
    const readingCount = 5000;
    final meter = _meter();
    await meters.save(meter);
    final baseMillis = DateTime.utc(2020, 1, 1).millisecondsSinceEpoch;
    await database.batch((batch) {
      batch.insertAll(database.readingRecords, [
        for (var index = 0; index < readingCount; index++)
          ReadingRecordsCompanion.insert(
            id: 'long_history_$index',
            meterId: meter.id,
            meterSnapshotJson: jsonEncode(
              MeterSnapshot.fromMeter(meter).toJson(),
            ),
            displayValue: '$index,0',
            valueDigits: '${index}0',
            valueScale: 1,
            capturedAtMillis: baseMillis + index,
            timezoneOffsetMinutes: 60,
            storedAtMillis: baseMillis + index,
            updatedAtMillis: baseMillis + index,
            source: ReadingSource.camera.name,
            photoPath: '/tmp/photo.jpg',
            photoSha256: 'a' * 64,
            note: const Value('Langzeittest'),
            manifestSha256: 'b' * 64,
          ),
      ]);
    });

    final stopwatch = Stopwatch()..start();
    final page = await readings.watchPageForMeter(meter.id, limit: 20).first;
    stopwatch.stop();

    expect(page.readings, hasLength(20));
    expect(page.totalCount, readingCount);
    expect(page.olderNeighbor, isNotNull);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    final lastPage = await readings
        .watchPageForMeter(meter.id, limit: 20, offset: 4980)
        .first;
    expect(lastPage.readings, hasLength(20));
    expect(lastPage.latestReading?.id, 'long_history_4999');
    expect(lastPage.hasMore, isFalse);
    final searchPage = await readings
        .watchPageForMeter(
          meter.id,
          limit: 20,
          offset: 200,
          query: 'Langzeittest',
        )
        .first;
    expect(searchPage.readings, hasLength(20));
    expect(searchPage.matchingCount, 5000);
    expect(searchPage.readings.first.id, 'long_history_4799');
  });

  test(
    'dashboard query stays bounded for 500 meters and 10000 readings',
    () async {
      const meterCount = 500;
      const readingsPerMeter = 20;
      final baseMillis = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;
      await database.batch((batch) {
        batch.insertAll(database.meterRecords, [
          for (var meterIndex = 0; meterIndex < meterCount; meterIndex++)
            MeterRecordsCompanion.insert(
              id: 'meter_$meterIndex',
              label: 'Zähler $meterIndex',
              type: MeterType.electricity.name,
              unit: 'kWh',
              meterNumber: Value('N$meterIndex'),
              location: const Value('Test'),
              createdAtMillis: baseMillis,
              updatedAtMillis: baseMillis,
            ),
        ]);
        batch.insertAll(database.readingRecords, [
          for (var meterIndex = 0; meterIndex < meterCount; meterIndex++)
            for (
              var readingIndex = 0;
              readingIndex < readingsPerMeter;
              readingIndex++
            )
              ReadingRecordsCompanion.insert(
                id: 'reading_${meterIndex}_$readingIndex',
                meterId: 'meter_$meterIndex',
                meterSnapshotJson: jsonEncode({
                  'id': 'meter_$meterIndex',
                  'label': 'Zähler $meterIndex',
                  'type': MeterType.electricity.name,
                  'unit': 'kWh',
                  'meterNumber': 'N$meterIndex',
                  'location': 'Test',
                }),
                displayValue: '$readingIndex,0',
                valueDigits: '${readingIndex}0',
                valueScale: 1,
                capturedAtMillis: baseMillis + readingIndex,
                timezoneOffsetMinutes: 60,
                storedAtMillis: baseMillis + readingIndex,
                updatedAtMillis: baseMillis + readingIndex,
                source: ReadingSource.camera.name,
                photoPath: '/tmp/photo.jpg',
                photoSha256: 'a' * 64,
                manifestSha256: 'b' * 64,
              ),
        ]);
      });

      final stopwatch = Stopwatch()..start();
      final items = await dashboard.watchAll().first;
      stopwatch.stop();

      expect(items, hasLength(meterCount));
      expect(items.first.latestValue, isNotNull);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    },
  );
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

MeterReading _historyReading(
  Meter meter, {
  required int index,
  required DateTime capturedAt,
  required String note,
}) => MeterReading(
  id: 'history_$index',
  meterId: meter.id,
  meter: MeterSnapshot.fromMeter(meter),
  value: ReadingValue.tryParse('${1000 + index},0')!,
  capturedAt: capturedAt,
  timezoneOffsetMinutes: capturedAt.timeZoneOffset.inMinutes,
  storedAt: capturedAt,
  updatedAt: capturedAt,
  source: ReadingSource.camera,
  photoPath: '/tmp/photo_$index.jpg',
  photoSha256: 'a' * 64,
  ocrRawText: '${1000 + index},0',
  ocrCandidate: '${1000 + index},0',
  note: note,
  manifestSha256: 'b' * 64,
);
