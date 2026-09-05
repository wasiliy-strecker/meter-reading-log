import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/persistence/app_database.dart';

void main() {
  test('schema 3 migration adds dashboard reading indexes', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
CREATE TABLE reading_records (
  meter_id TEXT NOT NULL,
  captured_at_millis INTEGER NOT NULL,
  stored_at_millis INTEGER NOT NULL,
  updated_at_millis INTEGER NOT NULL
)
''');
        database.execute('PRAGMA user_version = 3');
      },
    );
    final database = AppDatabase.withExecutor(executor);
    addTearDown(database.close);

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
}
