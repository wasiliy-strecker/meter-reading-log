import 'meter_reading.dart';

/// Matches the database history order, including equal capture timestamps.
int compareReadingsNewestFirst(MeterReading left, MeterReading right) {
  final captured = right.capturedAt.compareTo(left.capturedAt);
  if (captured != 0) return captured;
  final stored = right.storedAt.compareTo(left.storedAt);
  if (stored != 0) return stored;
  return right.id.compareTo(left.id);
}
