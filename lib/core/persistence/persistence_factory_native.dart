import '../../features/meters/data/drift_meter_repositories.dart';
import 'app_database.dart';
import 'persistence_bundle.dart';

PersistenceBundle createPersistenceBundle() {
  final database = AppDatabase();
  return PersistenceBundle(
    meters: DriftMeterRepository(database),
    readings: DriftMeterReadingRepository(database),
    exports: DriftEvidenceExportRepository(database),
    dispose: database.close,
  );
}
