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
  IntColumn get createdAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();
  TextColumn get reminderJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('StoredReadingRecord')
class ReadingRecords extends Table {
  TextColumn get id => text()();
  TextColumn get meterId => text()();
  TextColumn get meterSnapshotJson => text()();
  TextColumn get displayValue => text()();
  TextColumn get valueDigits => text()();
  IntColumn get valueScale => integer()();
  IntColumn get capturedAtMillis => integer()();
  IntColumn get timezoneOffsetMinutes => integer()();
  IntColumn get storedAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();
  TextColumn get source => text()();
  TextColumn get photoPath => text()();
  TextColumn get photoSha256 => text()();
  TextColumn get ocrRawText => text().withDefault(const Constant(''))();
  TextColumn get ocrCandidate => text().withDefault(const Constant(''))();
  RealColumn get ocrConfidence => real().nullable()();
  IntColumn get photoAddedAtMillis => integer().nullable()();
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
  IntColumn get changedAtMillis => integer()();
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
  IntColumn get createdAtMillis => integer()();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  TextColumn get pdfSha256 => text()();
  TextColumn get manifestSha256 => text()();

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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          readingRecords,
          readingRecords.photoAddedAtMillis,
        );
        await migrator.addColumn(
          readingRecords,
          readingRecords.photoHistoryJson,
        );
      }
    },
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
