import '../domain/meter_repositories.dart';
import 'drift_meter_repositories.dart';
import 'in_memory_meter_repositories.dart';

MeterDashboardRepository createMeterDashboardRepository({
  required MeterRepository meters,
  required MeterReadingRepository readings,
}) {
  if (meters is DriftMeterRepository &&
      readings is DriftMeterReadingRepository &&
      identical(meters.database, readings.database)) {
    return DriftMeterDashboardRepository(meters.database);
  }
  return CombinedMeterDashboardRepository(meters: meters, readings: readings);
}
