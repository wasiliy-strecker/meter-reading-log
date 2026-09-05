import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/persistence/app_database.dart';
import '../../evidence/domain/evidence_export.dart';
import '../domain/meter.dart';
import '../domain/meter_reading.dart';
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
  Stream<List<MeterReading>> watchForMeter(String meterId) {
    final query = database.select(database.readingRecords)
      ..where((row) => row.meterId.equals(meterId))
      ..orderBy([(row) => OrderingTerm.desc(row.capturedAtMillis)]);
    return query.watch().map((rows) => rows.map(_readingFromRow).toList());
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
    );
  }
}
