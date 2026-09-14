import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/persistence/app_database.dart';
import 'package:meter_reading_log/features/meters/data/drift_meter_repositories.dart';

void main() {
  for (final version in [1, 2, 3, 4]) {
    test(
      'schema $version migrates timestamps without changing values, hashes or paths',
      () async {
        const stamp = 1788264000123;
        final snapshot = jsonEncode({
          'id': 'meter',
          'label': 'Test',
          'type': 'electricity',
          'unit': 'kWh',
          'meterNumber': '',
          'location': '',
        });
        final executor = NativeDatabase.memory(
          setup: (db) {
            db.execute('''
CREATE TABLE meter_records (
 id TEXT PRIMARY KEY, label TEXT NOT NULL, type TEXT NOT NULL, unit TEXT NOT NULL,
 meter_number TEXT NOT NULL DEFAULT '', location TEXT NOT NULL DEFAULT '',
 created_at_millis INTEGER NOT NULL, updated_at_millis INTEGER NOT NULL, reminder_json TEXT
);
CREATE TABLE reading_records (
 id TEXT PRIMARY KEY, meter_id TEXT NOT NULL, meter_snapshot_json TEXT NOT NULL,
 display_value TEXT NOT NULL, value_digits TEXT NOT NULL, value_scale INTEGER NOT NULL,
 captured_at_millis INTEGER NOT NULL, timezone_offset_minutes INTEGER NOT NULL,
 stored_at_millis INTEGER NOT NULL, updated_at_millis INTEGER NOT NULL,
 source TEXT NOT NULL, photo_path TEXT NOT NULL, photo_sha256 TEXT NOT NULL,
 ocr_raw_text TEXT NOT NULL DEFAULT '', ocr_candidate TEXT NOT NULL DEFAULT '', ocr_confidence REAL,
 ${version >= 2 ? "photo_added_at_millis INTEGER, photo_history_json TEXT NOT NULL DEFAULT '[]'," : ''}
 lower_reading_reason TEXT, note TEXT NOT NULL DEFAULT '', manifest_sha256 TEXT NOT NULL
);
CREATE TABLE revision_records (
 id TEXT PRIMARY KEY, reading_id TEXT NOT NULL, changed_at_millis INTEGER NOT NULL,
 reason TEXT NOT NULL, changes_json TEXT NOT NULL
);
CREATE TABLE evidence_export_records (
 id TEXT PRIMARY KEY, meter_id TEXT NOT NULL, kind TEXT NOT NULL, reading_ids_json TEXT NOT NULL,
 created_at_millis INTEGER NOT NULL, file_name TEXT NOT NULL, file_path TEXT NOT NULL,
 pdf_sha256 TEXT NOT NULL, manifest_sha256 TEXT NOT NULL
 ${version >= 3 ? ", photo_mode TEXT NOT NULL DEFAULT 'allPhotos'" : ''}
);
''');
            if (version >= 4) {
              db.execute(
                'CREATE INDEX reading_meter_captured_idx ON reading_records (meter_id, captured_at_millis, stored_at_millis)',
              );
              db.execute(
                'CREATE INDEX reading_meter_updated_idx ON reading_records (meter_id, updated_at_millis)',
              );
            }
            db.execute(
              'INSERT INTO meter_records (id,label,type,unit,created_at_millis,updated_at_millis) VALUES (?,?,?,?,?,?)',
              ['meter', 'Test', 'electricity', 'kWh', stamp, stamp],
            );
            for (final id in ['reading', 'nullable-photo-time']) {
              db.execute(
                '''INSERT INTO reading_records (id,meter_id,meter_snapshot_json,display_value,value_digits,value_scale,captured_at_millis,timezone_offset_minutes,stored_at_millis,updated_at_millis,source,photo_path,photo_sha256,manifest_sha256)
VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
                [
                  id,
                  'meter',
                  snapshot,
                  '0012,3',
                  '123',
                  1,
                  stamp,
                  120,
                  stamp,
                  stamp,
                  'camera',
                  '/synthetic/photo.jpg',
                  'photo-hash',
                  'original-manifest',
                ],
              );
            }
            if (version >= 2) {
              db.execute(
                "UPDATE reading_records SET photo_added_at_millis = ? WHERE id = 'reading'",
                [stamp],
              );
            }
            db.execute('INSERT INTO revision_records VALUES (?,?,?,?,?)', [
              'revision',
              'reading',
              stamp,
              '',
              '{}',
            ]);
            db.execute(
              'INSERT INTO evidence_export_records (id,meter_id,kind,reading_ids_json,created_at_millis,file_name,file_path,pdf_sha256,manifest_sha256) VALUES (?,?,?,?,?,?,?,?,?)',
              [
                'pdf',
                'meter',
                'singleReading',
                '["reading"]',
                stamp,
                'test.pdf',
                '/synthetic/test.pdf',
                'pdf-hash',
                'pdf-manifest',
              ],
            );
            db.execute('PRAGMA user_version = $version');
          },
        );
        final database = AppDatabase.withExecutor(executor);
        addTearDown(database.close);
        final readings = DriftMeterReadingRepository(database);
        final reading = (await readings.findById('reading'))!;
        final expectedTime = DateTime.fromMillisecondsSinceEpoch(
          stamp,
          isUtc: true,
        );
        expect(reading.capturedAt, expectedTime);
        expect(reading.storedAt, expectedTime);
        expect(reading.updatedAt, expectedTime);
        expect(reading.photoAddedAt, version >= 2 ? expectedTime : isNull);
        expect(
          (await readings.findById('nullable-photo-time'))!.photoAddedAt,
          isNull,
        );
        expect(reading.value.canonical, '12.3');
        expect(reading.value.displayText, '0012,3');
        expect(reading.photoPath, '/synthetic/photo.jpg');
        expect(reading.manifestSha256, 'original-manifest');
        expect(
          (await readings.loadRevisions('reading')).single.changedAt,
          expectedTime,
        );
        expect(
          (await DriftMeterRepository(database).findById('meter'))!.createdAt,
          expectedTime,
        );
        final pdf = (await DriftEvidenceExportRepository(
          database,
        ).loadAll()).single;
        expect(pdf.createdAt, expectedTime);
        expect(pdf.filePath, '/synthetic/test.pdf');
        expect(pdf.pdfSha256, 'pdf-hash');
        final indexes = await database
            .customSelect(
              "SELECT sql FROM sqlite_master WHERE type='index' AND name LIKE 'reading_meter_%_idx'",
            )
            .get();
        expect(indexes, hasLength(2));
        expect(
          indexes.map((r) => r.read<String>('sql')).join(),
          contains('captured_at_micros'),
        );
        expect(
          (await database.customSelect('PRAGMA user_version').getSingle())
              .read<int>('user_version'),
          5,
        );
        final raw = await database
            .customSelect(
              "SELECT captured_at_micros FROM reading_records WHERE id='reading'",
            )
            .getSingle();
        expect(raw.read<int>('captured_at_micros'), stamp * 1000);
      },
    );
  }
}
