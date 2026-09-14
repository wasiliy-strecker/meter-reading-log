import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('StoredMeterRecord')
class MeterRecords extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get type => text()();
  TextColumn get unit => text()();
  TextColumn get meterNumber => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
  IntColumn get createdAtMicros => integer()();
  IntColumn get updatedAtMicros => integer()();
  TextColumn get reminderJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('StoredReadingRecord')
@TableIndex(
  name: 'reading_meter_captured_idx',
  columns: {#meterId, #capturedAtMicros, #storedAtMicros},
)
@TableIndex(
  name: 'reading_meter_updated_idx',
  columns: {#meterId, #updatedAtMicros},
)
class ReadingRecords extends Table {
  TextColumn get id => text()();
  TextColumn get meterId => text()();
  TextColumn get meterSnapshotJson => text()();
  TextColumn get displayValue => text()();
  TextColumn get valueDigits => text()();
  IntColumn get valueScale => integer()();
  IntColumn get capturedAtMicros => integer()();
  IntColumn get timezoneOffsetMinutes => integer()();
  IntColumn get storedAtMicros => integer()();
  IntColumn get updatedAtMicros => integer()();
  TextColumn get source => text()();
  TextColumn get photoPath => text()();
  TextColumn get photoSha256 => text()();
  TextColumn get ocrRawText => text().withDefault(const Constant(''))();
  TextColumn get ocrCandidate => text().withDefault(const Constant(''))();
  RealColumn get ocrConfidence => real().nullable()();
  IntColumn get photoAddedAtMicros => integer().nullable()();
  TextColumn get photoHistoryJson => text().withDefault(const Constant('[]'))();
  TextColumn get lowerReadingReason => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get manifestSha256 => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('StoredRevisionRecord')
class RevisionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get readingId => text()();
  IntColumn get changedAtMicros => integer()();
  TextColumn get reason => text()();
  TextColumn get changesJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('StoredEvidenceExportRecord')
class EvidenceExportRecords extends Table {
  TextColumn get id => text()();
  TextColumn get meterId => text()();
  TextColumn get kind => text()();
  TextColumn get readingIdsJson => text()();
  IntColumn get createdAtMicros => integer()();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  TextColumn get pdfSha256 => text()();
  TextColumn get manifestSha256 => text()();
  TextColumn get photoMode => text().withDefault(const Constant('allPhotos'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    MeterRecords,
    ReadingRecords,
    RevisionRecords,
    EvidenceExportRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.memory() : super(NativeDatabase.memory());

  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) => transaction(() async {
      // Upgrade older schemas using their original column names first.
      if (from < 2) {
        await customStatement(
          'ALTER TABLE reading_records ADD COLUMN photo_added_at_millis INTEGER',
        );
        await customStatement(
          "ALTER TABLE reading_records ADD COLUMN photo_history_json TEXT NOT NULL DEFAULT '[]'",
        );
      }
      if (from < 3) {
        await migrator.addColumn(
          evidenceExportRecords,
          evidenceExportRecords.photoMode,
        );
      }
      if (from < 5) {
        const timestamps = {
          'meter_records': ['created_at', 'updated_at'],
          'reading_records': [
            'captured_at',
            'stored_at',
            'updated_at',
            'photo_added_at',
          ],
          'revision_records': ['changed_at'],
          'evidence_export_records': ['created_at'],
        };
        for (final table in timestamps.entries) {
          for (final column in table.value) {
            // SQLite also updates existing index definitions on rename.
            await customStatement(
              'ALTER TABLE ${table.key} RENAME COLUMN ${column}_millis TO ${column}_micros',
            );
            await customStatement(
              'UPDATE ${table.key} SET ${column}_micros = ${column}_micros * 1000',
            );
          }
        }
        await customStatement(
          'CREATE INDEX IF NOT EXISTS reading_meter_captured_idx '
          'ON reading_records '
          '(meter_id, captured_at_micros, stored_at_micros)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS reading_meter_updated_idx '
          'ON reading_records (meter_id, updated_at_micros)',
        );
      }
    }),
  );
}

QueryExecutor _openConnection() {
  if (_runningInFlutterTest) {
    return NativeDatabase.memory();
  }
  return LazyDatabase(() async {
    Directory directory;
    try {
      directory = await getApplicationDocumentsDirectory();
    } on MissingPluginException {
      directory = await Directory.systemTemp.createTemp(
        'meter_reading_log_db_',
      );
    }
    return NativeDatabase(
      File(p.join(directory.path, 'meter_reading_log.sqlite')),
    );
  });
}

bool get _runningInFlutterTest {
  return Platform.environment.containsKey('FLUTTER_TEST') ||
      Platform.resolvedExecutable.contains('flutter_tester') ||
      Platform.script.toString().contains('flutter_test');
}
