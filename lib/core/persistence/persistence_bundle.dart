import '../../features/meters/domain/meter_repositories.dart';

class PersistenceBundle {
  const PersistenceBundle({
    required this.meters,
    required this.readings,
    required this.exports,
    required this.dispose,
  });

  final MeterRepository meters;
  final MeterReadingRepository readings;
  final EvidenceExportRepository exports;
  final Future<void> Function() dispose;
}
