import '../../features/meters/data/in_memory_meter_repositories.dart';
import 'persistence_bundle.dart';

PersistenceBundle createPersistenceBundle() {
  final meters = InMemoryMeterRepository();
  final readings = InMemoryMeterReadingRepository();
  final exports = InMemoryEvidenceExportRepository();
  return PersistenceBundle(
    meters: meters,
    readings: readings,
    exports: exports,
    dispose: () async {
      await meters.dispose();
      await readings.dispose();
      await exports.dispose();
    },
  );
}
