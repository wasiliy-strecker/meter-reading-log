import '../domain/meter_repositories.dart';
import 'in_memory_meter_repositories.dart';

MeterDashboardRepository createMeterDashboardRepository({
  required MeterRepository meters,
  required MeterReadingRepository readings,
}) {
  return CombinedMeterDashboardRepository(meters: meters, readings: readings);
}
