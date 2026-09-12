import 'meter_reading.dart';

class MeterReadingPage {
  const MeterReadingPage({
    required this.readings,
    required this.totalCount,
    required this.matchingCount,
    required this.latestReading,
    this.offset = 0,
    this.olderNeighbor,
  });

  final List<MeterReading> readings;
  final int totalCount;
  final int matchingCount;
  final int offset;
  final MeterReading? latestReading;
  final MeterReading? olderNeighbor;

  bool get hasMore => offset + readings.length < matchingCount;
}

bool meterReadingMatchesQuery(MeterReading reading, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return true;
  final localDate = reading.capturedAt.toLocal();
  final formattedDate =
      '${localDate.day.toString().padLeft(2, '0')}.'
      '${localDate.month.toString().padLeft(2, '0')}.'
      '${localDate.year.toString().padLeft(4, '0')}';
  return formattedDate.contains(query) ||
      reading.value.displayText.toLowerCase().contains(query) ||
      reading.note.toLowerCase().contains(query);
}
