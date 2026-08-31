import 'dart:async';

import '../../evidence/domain/evidence_export.dart';
import '../domain/meter.dart';
import '../domain/meter_reading.dart';
import '../domain/meter_repositories.dart';

class InMemoryMeterRepository implements MeterRepository {
  final Map<String, Meter> _items = {};
  final StreamController<List<Meter>> _changes = StreamController.broadcast();

  @override
  Stream<List<Meter>> watchAll() async* {
    yield _sorted;
    yield* _changes.stream;
  }

  List<Meter> get _sorted =>
      _items.values.toList()..sort((a, b) => a.label.compareTo(b.label));

  void _emit() => _changes.add(_sorted);

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _emit();
  }

  @override
  Future<Meter?> findById(String id) async => _items[id];

  @override
  Future<List<Meter>> loadAll() async => _sorted;

  @override
  Future<void> save(Meter meter) async {
    _items[meter.id] = meter;
    _emit();
  }

  Future<void> dispose() => _changes.close();
}

class InMemoryMeterReadingRepository implements MeterReadingRepository {
  final Map<String, MeterReading> _items = {};
  final Map<String, List<ReadingRevision>> _revisions = {};
  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Stream<List<MeterReading>> watchForMeter(String meterId) async* {
    yield _forMeter(meterId);
    await for (final _ in _changes.stream) {
      yield _forMeter(meterId);
    }
  }

  List<MeterReading> _forMeter(String id) =>
      _items.values.where((item) => item.meterId == id).toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _revisions.remove(id);
    _changes.add(null);
  }

  @override
  Future<MeterReading?> findById(String id) async => _items[id];

  @override
  Future<List<MeterReading>> loadAll() async => _items.values.toList();

  @override
  Future<List<MeterReading>> loadForMeter(String meterId) async =>
      _forMeter(meterId);

  @override
  Future<List<ReadingRevision>> loadRevisions(String readingId) async =>
      List.unmodifiable(_revisions[readingId] ?? const []);

  @override
  Future<void> save(MeterReading reading) async {
    _items[reading.id] = reading;
    _changes.add(null);
  }

  @override
  Future<void> saveRevision(ReadingRevision revision) async {
    final items = _revisions.putIfAbsent(revision.readingId, () => []);
    items.removeWhere((item) => item.id == revision.id);
    items.add(revision);
  }

  @override
  Future<void> updateWithRevision(
    MeterReading reading,
    ReadingRevision revision,
  ) async {
    await save(reading);
    await saveRevision(revision);
  }

  Future<void> dispose() => _changes.close();
}

class InMemoryEvidenceExportRepository implements EvidenceExportRepository {
  final Map<String, EvidenceExportRecord> _items = {};
  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Stream<List<EvidenceExportRecord>> watchForMeter(String meterId) async* {
    yield _forMeter(meterId);
    await for (final _ in _changes.stream) {
      yield _forMeter(meterId);
    }
  }

  List<EvidenceExportRecord> _forMeter(String id) =>
      _items.values.where((item) => item.meterId == id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _changes.add(null);
  }

  @override
  Future<EvidenceExportRecord?> findByFileName(String fileName) async =>
      _items.values.where((item) => item.fileName == fileName).firstOrNull;

  @override
  Future<EvidenceExportRecord?> findByPdfHash(String sha256) async =>
      _items.values.where((item) => item.pdfSha256 == sha256).firstOrNull;

  @override
  Future<List<EvidenceExportRecord>> loadAll() async => _items.values.toList();

  @override
  Future<List<EvidenceExportRecord>> loadForMeter(String meterId) async =>
      _forMeter(meterId);

  @override
  Future<void> save(EvidenceExportRecord record) async {
    _items[record.id] = record;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
