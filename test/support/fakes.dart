import 'dart:async';

import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/meter_repositories.dart';
import 'package:meter_reading_log/core/reminders/local_notification_reminder_repository.dart';

class NoopMeterReminderRepository implements MeterReminderRepository {
  NoopMeterReminderRepository({this.statuses = const {}});

  final Map<String, ReminderStatus> statuses;
  final List<String> acknowledgedMeterIds = [];
  int alarmTestCount = 0;

  @override
  Stream<String> get notificationOpened => const Stream.empty();

  @override
  Stream<int> get statusChanges => const Stream.empty();

  @override
  Future<void> acknowledge(String meterId) async {
    acknowledgedMeterIds.add(meterId);
  }

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<void> cancel(String meterId) async {}

  @override
  Future<String?> consumeInitialMeterId() async => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<Map<String, ReminderStatus>> loadStatuses(
    Iterable<String> meterIds,
  ) async {
    final result = <String, ReminderStatus>{};
    for (final meterId in meterIds) {
      final status = statuses[meterId];
      if (status != null) result[meterId] = status;
    }
    return result;
  }

  @override
  Future<ReminderPermissionStatus> permissionStatus() async =>
      ReminderPermissionStatus.granted;

  @override
  void refreshStatuses() {}

  @override
  Future<bool> requestExactAlarmPermission() async => true;

  @override
  Future<ReminderPermissionStatus> requestPermission() async =>
      ReminderPermissionStatus.granted;

  @override
  Future<void> schedule(Meter meter) async {}

  @override
  Future<void> showAlarmTest() async {
    alarmTestCount += 1;
  }
}

class MemoryMeterRepository implements MeterRepository {
  final Map<String, Meter> items = {};

  @override
  Future<void> delete(String id) async => items.remove(id);

  @override
  Future<Meter?> findById(String id) async => items[id];

  @override
  Future<List<Meter>> loadAll() async => items.values.toList();

  @override
  Future<void> save(Meter meter) async => items[meter.id] = meter;

  @override
  Stream<List<Meter>> watchAll() => Stream.value(items.values.toList());
}

class MemoryReadingRepository implements MeterReadingRepository {
  final Map<String, MeterReading> items = {};
  final Map<String, List<ReadingRevision>> revisions = {};

  @override
  Future<void> delete(String id) async {
    items.remove(id);
    revisions.remove(id);
  }

  @override
  Future<MeterReading?> findById(String id) async => items[id];

  @override
  Future<List<MeterReading>> loadAll() async => items.values.toList();

  @override
  Future<List<MeterReading>> loadForMeter(String meterId) async =>
      items.values.where((item) => item.meterId == meterId).toList();

  @override
  Future<List<ReadingRevision>> loadRevisions(String readingId) async =>
      revisions[readingId] ?? const [];

  @override
  Future<void> save(MeterReading reading) async => items[reading.id] = reading;

  @override
  Future<void> saveRevision(ReadingRevision revision) async {
    revisions.putIfAbsent(revision.readingId, () => []).add(revision);
  }

  @override
  Future<void> updateWithRevision(
    MeterReading reading,
    ReadingRevision revision,
  ) async {
    await save(reading);
    await saveRevision(revision);
  }

  @override
  Stream<List<MeterReading>> watchForMeter(String meterId) => Stream.value(
    items.values.where((item) => item.meterId == meterId).toList(),
  );
}

class MemoryEvidenceExportRepository implements EvidenceExportRepository {
  final Map<String, EvidenceExportRecord> items = {};

  @override
  Future<void> delete(String id) async => items.remove(id);

  @override
  Future<EvidenceExportRecord?> findByFileName(String fileName) async =>
      items.values.where((item) => item.fileName == fileName).firstOrNull;

  @override
  Future<EvidenceExportRecord?> findByPdfHash(String sha256) async =>
      items.values.where((item) => item.pdfSha256 == sha256).firstOrNull;

  @override
  Future<List<EvidenceExportRecord>> loadAll() async => items.values.toList();

  @override
  Future<List<EvidenceExportRecord>> loadForMeter(String meterId) async =>
      items.values.where((item) => item.meterId == meterId).toList();

  @override
  Future<void> save(EvidenceExportRecord record) async =>
      items[record.id] = record;

  @override
  Stream<List<EvidenceExportRecord>> watchForMeter(String meterId) =>
      Stream.value(
        items.values.where((item) => item.meterId == meterId).toList(),
      );
}
