import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/persistence/app_database.dart';
import '../../evidence/domain/evidence_export.dart';
import '../domain/meter.dart';
import '../domain/meter_dashboard_item.dart';
import '../domain/meter_reading.dart';
import '../domain/meter_reading_page.dart';
import '../domain/meter_repositories.dart';
import '../domain/reading_value.dart';

class DriftMeterRepository implements MeterRepository {
  const DriftMeterRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<Meter>> watchAll() {
    final query = database.select(database.meterRecords)
      ..orderBy([(row) => OrderingTerm.asc(row.label)]);
    return query.watch().map((rows) => rows.map(_meterFromRow).toList());
  }

  @override
  Future<List<Meter>> loadAll() async {
    final query = database.select(database.meterRecords)
      ..orderBy([(row) => OrderingTerm.asc(row.label)]);
    return (await query.get()).map(_meterFromRow).toList();
  }

  @override
  Future<Meter?> findById(String id) async {
    final row = await (database.select(
      database.meterRecords,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row == null ? null : _meterFromRow(row);
  }

  @override
  Future<void> save(Meter meter) async {
    await database
        .into(database.meterRecords)
        .insertOnConflictUpdate(
          MeterRecordsCompanion.insert(
            id: meter.id,
            label: meter.label,
            type: meter.type.name,
            unit: meter.unit,
            meterNumber: Value(meter.meterNumber),
            location: Value(meter.location),
            createdAtMillis: meter.createdAt.toUtc().millisecondsSinceEpoch,
            updatedAtMillis: meter.updatedAt.toUtc().millisecondsSinceEpoch,
            reminderJson: Value(
              meter.reminder == null
                  ? null
                  : jsonEncode(meter.reminder!.toJson()),
            ),
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(
      database.meterRecords,
    )..where((item) => item.id.equals(id))).go();
  }

  Meter _meterFromRow(StoredMeterRecord row) {
    final reminder = row.reminderJson;
    return Meter(
      id: row.id,
      label: row.label,
      type: MeterType.values.byName(row.type),
      unit: row.unit,
      meterNumber: row.meterNumber,
      location: row.location,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMillis,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMillis,
        isUtc: true,
      ),
      reminder: reminder == null
          ? null
          : ReadingReminderSchedule.fromJson(
              jsonDecode(reminder) as Map<String, dynamic>,
            ),
    );
  }
}

class DriftMeterReadingRepository implements MeterReadingRepository {
  const DriftMeterReadingRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<MeterReading>> watchAll() {
    final query = database.select(database.readingRecords)
      ..orderBy([(row) => OrderingTerm.desc(row.capturedAtMillis)]);
    return query.watch().map((rows) => rows.map(_readingFromRow).toList());
  }

  @override
  Stream<List<MeterReading>> watchForMeter(String meterId) {
    final query = database.select(database.readingRecords)
      ..where((row) => row.meterId.equals(meterId))
      ..orderBy([(row) => OrderingTerm.desc(row.capturedAtMillis)]);
    return query.watch().map((rows) => rows.map(_readingFromRow).toList());
  }

  @override
  Stream<MeterReadingPage> watchPageForMeter(
    String meterId, {
    required int limit,
    int offset = 0,
    String query = '',
  }) {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    if (offset < 0) throw ArgumentError.value(offset, 'offset');
    final normalizedQuery = query.trim().toLowerCase();
    final searchPredicate = _searchPredicate(normalizedQuery);
    final pageQuery = database.select(database.readingRecords)
      ..where(
        (row) =>
            row.meterId.equals(meterId) &
            (searchPredicate ?? const Constant(true)),
      )
      ..orderBy([
        (row) => OrderingTerm.desc(row.capturedAtMillis),
        (row) => OrderingTerm.desc(row.storedAtMillis),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(limit + 1, offset: offset);
    return pageQuery.watch().asyncMap((rows) async {
      final totalCount = await _countForMeter(meterId);
      final matchingCount = searchPredicate == null
          ? totalCount
          : await _countForMeter(meterId, searchPredicate: searchPredicate);
      final latestReading =
          offset == 0 && searchPredicate == null && rows.isNotEmpty
          ? _readingFromRow(rows.first)
          : await _latestForMeter(meterId);
      final visibleRows = rows.take(limit).toList(growable: false);
      return MeterReadingPage(
        offset: offset,
        readings: visibleRows.map(_readingFromRow).toList(growable: false),
        totalCount: totalCount,
        matchingCount: matchingCount,
        latestReading: latestReading,
        olderNeighbor: rows.length > limit
            ? _readingFromRow(rows[limit])
            : null,
      );
    });
  }

  @override
  Future<List<MeterReading>> loadAll() async {
    final query = database.select(database.readingRecords)
      ..orderBy([(row) => OrderingTerm.desc(row.capturedAtMillis)]);
    return (await query.get()).map(_readingFromRow).toList();
  }

  @override
  Future<List<MeterReading>> loadForMeter(String meterId) async {
    final query = database.select(database.readingRecords)
      ..where((row) => row.meterId.equals(meterId))
      ..orderBy([(row) => OrderingTerm.desc(row.capturedAtMillis)]);
    return (await query.get()).map(_readingFromRow).toList();
  }

  @override
  Future<MeterReading?> findById(String id) async {
    final row = await (database.select(
      database.readingRecords,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row == null ? null : _readingFromRow(row);
  }

  Expression<bool>? _searchPredicate(String query) {
    if (query.isEmpty) return null;
    String escapedLikePattern(String value) => value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');

    final lowercasePattern = '%${escapedLikePattern(query)}%';
    final uppercasePattern = '%${escapedLikePattern(query.toUpperCase())}%';
    const formattedLocalDate = CustomExpression<String>(
      "strftime('%d.%m.%Y', "
      '"reading_records"."captured_at_millis" / 1000, '
      "'unixepoch', 'localtime')",
    );
    final readings = database.readingRecords;
    Expression<bool> matchesText(Expression<String> column) =>
        column.lower().like(lowercasePattern, escapeChar: r'\') |
        column.like(uppercasePattern, escapeChar: r'\');

    return matchesText(readings.displayValue) |
        matchesText(readings.note) |
        formattedLocalDate.like(lowercasePattern, escapeChar: r'\');
  }

  Future<int> _countForMeter(
    String meterId, {
    Expression<bool>? searchPredicate,
  }) async {
    final count = countAll();
    final query = database.selectOnly(database.readingRecords)
      ..addColumns([count])
      ..where(database.readingRecords.meterId.equals(meterId));
    if (searchPredicate != null) query.where(searchPredicate);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<MeterReading?> _latestForMeter(String meterId) async {
    final query = database.select(database.readingRecords)
      ..where((row) => row.meterId.equals(meterId))
      ..orderBy([
        (row) => OrderingTerm.desc(row.capturedAtMillis),
        (row) => OrderingTerm.desc(row.storedAtMillis),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _readingFromRow(row);
  }

  @override
  Future<void> save(MeterReading reading) async {
    await database
        .into(database.readingRecords)
        .insertOnConflictUpdate(_readingCompanion(reading));
  }

  @override
  Future<void> updateWithRevision(
    MeterReading reading,
    ReadingRevision revision,
  ) async {
    await database.transaction(() async {
      await database
          .into(database.readingRecords)
          .insertOnConflictUpdate(_readingCompanion(reading));
      await database
          .into(database.revisionRecords)
          .insert(
            RevisionRecordsCompanion.insert(
              id: revision.id,
              readingId: revision.readingId,
              changedAtMillis: revision.changedAt
                  .toUtc()
                  .millisecondsSinceEpoch,
              reason: revision.reason,
              changesJson: jsonEncode(
                revision.changes.map(
                  (key, value) => MapEntry(key, value.toJson()),
                ),
              ),
            ),
          );
    });
  }

  @override
  Future<List<ReadingRevision>> loadRevisions(String readingId) async {
    final query = database.select(database.revisionRecords)
      ..where((row) => row.readingId.equals(readingId))
      ..orderBy([(row) => OrderingTerm.asc(row.changedAtMillis)]);
    final rows = await query.get();
    return rows.map((row) {
      final rawChanges = jsonDecode(row.changesJson) as Map<String, dynamic>;
      return ReadingRevision(
        id: row.id,
        readingId: row.readingId,
        changedAt: DateTime.fromMillisecondsSinceEpoch(
          row.changedAtMillis,
          isUtc: true,
        ),
        reason: row.reason,
        changes: rawChanges.map(
          (key, value) => MapEntry(
            key,
            ReadingChange.fromJson(Map<String, dynamic>.from(value as Map)),
          ),
        ),
      );
    }).toList();
  }

  @override
  Future<void> saveRevision(ReadingRevision revision) async {
    await database
        .into(database.revisionRecords)
        .insertOnConflictUpdate(
          RevisionRecordsCompanion.insert(
            id: revision.id,
            readingId: revision.readingId,
            changedAtMillis: revision.changedAt.toUtc().millisecondsSinceEpoch,
            reason: revision.reason,
            changesJson: jsonEncode(
              revision.changes.map(
                (key, value) => MapEntry(key, value.toJson()),
              ),
            ),
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    await database.transaction(() async {
      await (database.delete(
        database.revisionRecords,
      )..where((row) => row.readingId.equals(id))).go();
      await (database.delete(
        database.readingRecords,
      )..where((row) => row.id.equals(id))).go();
    });
  }

  ReadingRecordsCompanion _readingCompanion(MeterReading reading) {
    return ReadingRecordsCompanion.insert(
      id: reading.id,
      meterId: reading.meterId,
      meterSnapshotJson: jsonEncode(reading.meter.toJson()),
      displayValue: reading.value.displayText,
      valueDigits: reading.value.digits,
      valueScale: reading.value.scale,
      capturedAtMillis: reading.capturedAt.toUtc().millisecondsSinceEpoch,
      timezoneOffsetMinutes: reading.timezoneOffsetMinutes,
      storedAtMillis: reading.storedAt.toUtc().millisecondsSinceEpoch,
      updatedAtMillis: reading.updatedAt.toUtc().millisecondsSinceEpoch,
      source: reading.source.name,
      photoPath: reading.photoPath,
      photoSha256: reading.photoSha256,
      ocrRawText: Value(reading.ocrRawText),
      ocrCandidate: Value(reading.ocrCandidate),
      ocrConfidence: Value(reading.ocrConfidence),
      photoAddedAtMillis: Value(
        reading.photoAddedAt?.toUtc().millisecondsSinceEpoch,
      ),
      photoHistoryJson: Value(
        jsonEncode(
          reading.photoHistory.map((version) => version.toJson()).toList(),
        ),
      ),
      lowerReadingReason: Value(reading.lowerReadingReason?.name),
      note: Value(reading.note),
      manifestSha256: reading.manifestSha256,
    );
  }

  MeterReading _readingFromRow(StoredReadingRecord row) {
    return MeterReading(
      id: row.id,
      meterId: row.meterId,
      meter: MeterSnapshot.fromJson(
        jsonDecode(row.meterSnapshotJson) as Map<String, dynamic>,
      ),
      value: ReadingValue(
        displayText: row.displayValue,
        digits: row.valueDigits,
        scale: row.valueScale,
      ),
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        row.capturedAtMillis,
        isUtc: true,
      ),
      timezoneOffsetMinutes: row.timezoneOffsetMinutes,
      storedAt: DateTime.fromMillisecondsSinceEpoch(
        row.storedAtMillis,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMillis,
        isUtc: true,
      ),
      source: ReadingSource.values.byName(row.source),
      photoPath: row.photoPath,
      photoSha256: row.photoSha256,
      ocrRawText: row.ocrRawText,
      ocrCandidate: row.ocrCandidate,
      ocrConfidence: row.ocrConfidence,
      photoAddedAt: row.photoAddedAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.photoAddedAtMillis!,
              isUtc: true,
            ),
      photoHistory: (jsonDecode(row.photoHistoryJson) as List)
          .map(
            (item) => ReadingPhotoVersion.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      lowerReadingReason: row.lowerReadingReason == null
          ? null
          : LowerReadingReason.values.byName(row.lowerReadingReason!),
      note: row.note,
      manifestSha256: row.manifestSha256,
    );
  }
}

class DriftMeterDashboardRepository implements MeterDashboardRepository {
  const DriftMeterDashboardRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<MeterDashboardItem>> watchAll() {
    return database
        .customSelect(
          _dashboardQuery,
          readsFrom: {database.meterRecords, database.readingRecords},
        )
        .watch()
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  MeterDashboardItem _fromRow(QueryRow row) {
    final reminderJson = row.readNullable<String>('dashboard_reminder_json');
    final meter = Meter(
      id: row.read<String>('dashboard_meter_id'),
      label: row.read<String>('dashboard_label'),
      type: MeterType.values.byName(row.read<String>('dashboard_type')),
      unit: row.read<String>('dashboard_unit'),
      meterNumber: row.read<String>('dashboard_meter_number'),
      location: row.read<String>('dashboard_location'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('dashboard_created_at_millis'),
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('dashboard_meter_updated_at_millis'),
        isUtc: true,
      ),
      reminder: reminderJson == null
          ? null
          : ReadingReminderSchedule.fromJson(
              jsonDecode(reminderJson) as Map<String, dynamic>,
            ),
    );
    final latestDigits = row.readNullable<String>('dashboard_latest_digits');
    final latestSnapshot = row.readNullable<String>(
      'dashboard_latest_meter_snapshot_json',
    );
    final latestValue = latestDigits == null
        ? null
        : ReadingValue(
            displayText: row.read<String>('dashboard_latest_display_value'),
            digits: latestDigits,
            scale: row.read<int>('dashboard_latest_scale'),
          );
    var latestUnit = meter.unit;
    if (latestSnapshot != null) {
      final snapshot = jsonDecode(latestSnapshot) as Map<String, dynamic>;
      latestUnit = snapshot['unit'] as String? ?? meter.unit;
    }
    return MeterDashboardItem(
      meter: meter,
      latestValue: latestValue,
      latestUnit: latestValue == null ? null : latestUnit,
      lastEdited: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('dashboard_last_edited_millis'),
        isUtc: true,
      ),
    );
  }
}

const _dashboardQuery = '''
SELECT
  meter.id AS dashboard_meter_id,
  meter.label AS dashboard_label,
  meter.type AS dashboard_type,
  meter.unit AS dashboard_unit,
  meter.meter_number AS dashboard_meter_number,
  meter.location AS dashboard_location,
  meter.created_at_millis AS dashboard_created_at_millis,
  meter.updated_at_millis AS dashboard_meter_updated_at_millis,
  meter.reminder_json AS dashboard_reminder_json,
  latest.display_value AS dashboard_latest_display_value,
  latest.value_digits AS dashboard_latest_digits,
  latest.value_scale AS dashboard_latest_scale,
  latest.meter_snapshot_json AS dashboard_latest_meter_snapshot_json,
  MAX(
    meter.updated_at_millis,
    COALESCE(
      (
        SELECT MAX(history.updated_at_millis)
        FROM reading_records AS history
        WHERE history.meter_id = meter.id
      ),
      meter.updated_at_millis
    )
  ) AS dashboard_last_edited_millis
FROM meter_records AS meter
LEFT JOIN reading_records AS latest
  ON latest.id = (
    SELECT candidate.id
    FROM reading_records AS candidate
    WHERE candidate.meter_id = meter.id
    ORDER BY
      candidate.captured_at_millis DESC,
      candidate.stored_at_millis DESC,
      candidate.id DESC
    LIMIT 1
  )
ORDER BY meter.label COLLATE NOCASE, meter.id
''';

class DriftEvidenceExportRepository implements EvidenceExportRepository {
  const DriftEvidenceExportRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<EvidenceExportRecord>> watchForMeter(String meterId) {
    final query = database.select(database.evidenceExportRecords)
      ..where((row) => row.meterId.equals(meterId))
      ..orderBy([(row) => OrderingTerm.desc(row.createdAtMillis)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Future<List<EvidenceExportRecord>> loadAll() async {
    final query = database.select(database.evidenceExportRecords)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAtMillis)]);
    return (await query.get()).map(_fromRow).toList();
  }

  @override
  Future<List<EvidenceExportRecord>> loadForMeter(String meterId) async {
    final query = database.select(database.evidenceExportRecords)
      ..where((row) => row.meterId.equals(meterId))
      ..orderBy([(row) => OrderingTerm.desc(row.createdAtMillis)]);
    return (await query.get()).map(_fromRow).toList();
  }

  @override
  Future<void> save(EvidenceExportRecord record) async {
    await database
        .into(database.evidenceExportRecords)
        .insertOnConflictUpdate(
          EvidenceExportRecordsCompanion.insert(
            id: record.id,
            meterId: record.meterId,
            kind: record.kind.name,
            readingIdsJson: jsonEncode(record.readingIds),
            createdAtMillis: record.createdAt.toUtc().millisecondsSinceEpoch,
            fileName: record.fileName,
            filePath: record.filePath,
            pdfSha256: record.pdfSha256,
            manifestSha256: record.manifestSha256,
            photoMode: Value(record.photoMode.name),
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(
      database.evidenceExportRecords,
    )..where((row) => row.id.equals(id))).go();
  }

  EvidenceExportRecord _fromRow(StoredEvidenceExportRecord row) {
    return EvidenceExportRecord(
      id: row.id,
      meterId: row.meterId,
      kind: EvidenceExportKind.values.byName(row.kind),
      readingIds: (jsonDecode(row.readingIdsJson) as List).cast<String>(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMillis,
        isUtc: true,
      ),
      fileName: row.fileName,
      filePath: row.filePath,
      pdfSha256: row.pdfSha256,
      manifestSha256: row.manifestSha256,
      photoMode: EvidencePhotoMode.fromStoredName(row.photoMode),
    );
  }
}
