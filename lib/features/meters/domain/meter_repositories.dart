import '../../evidence/domain/evidence_export.dart';
import 'meter.dart';
import 'meter_reading.dart';

abstract interface class MeterRepository {
  Stream<List<Meter>> watchAll();
  Future<List<Meter>> loadAll();
  Future<Meter?> findById(String id);
  Future<void> save(Meter meter);
  Future<void> delete(String id);
}

abstract interface class MeterReadingRepository {
  Stream<List<MeterReading>> watchForMeter(String meterId);
  Future<List<MeterReading>> loadAll();
  Future<List<MeterReading>> loadForMeter(String meterId);
  Future<MeterReading?> findById(String id);
  Future<void> save(MeterReading reading);
  Future<void> updateWithRevision(
    MeterReading reading,
    ReadingRevision revision,
  );
  Future<List<ReadingRevision>> loadRevisions(String readingId);
  Future<void> saveRevision(ReadingRevision revision);
  Future<void> delete(String id);
}

abstract interface class EvidenceExportRepository {
  Stream<List<EvidenceExportRecord>> watchForMeter(String meterId);
  Future<List<EvidenceExportRecord>> loadAll();
  Future<List<EvidenceExportRecord>> loadForMeter(String meterId);
  Future<EvidenceExportRecord?> findByPdfHash(String sha256);
  Future<EvidenceExportRecord?> findByFileName(String fileName);
  Future<void> save(EvidenceExportRecord record);
  Future<void> delete(String id);
}
