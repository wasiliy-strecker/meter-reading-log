import 'meter.dart';
import 'reading_value.dart';

class MeterDashboardItem {
  const MeterDashboardItem({
    required this.meter,
    required this.lastEdited,
    this.latestValue,
    this.latestUnit,
  });

  final Meter meter;
  final ReadingValue? latestValue;
  final String? latestUnit;
  final DateTime lastEdited;
}
