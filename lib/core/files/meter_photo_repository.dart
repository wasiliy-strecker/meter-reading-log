import '../../features/meters/domain/meter_reading.dart';

class StoredMeterPhoto {
  const StoredMeterPhoto({
    required this.path,
    required this.sha256,
    required this.source,
    required this.capturedAt,
  });

  final String path;
  final String sha256;
  final ReadingSource source;
  final DateTime capturedAt;
}

abstract interface class MeterPhotoCaptureRepository {
  Future<StoredMeterPhoto?> capture(ReadingSource source);
  Future<StoredMeterPhoto?> recoverLostCapture();
  Future<void> delete(String path);
}

class UnsupportedMeterPhotoCaptureRepository
    implements MeterPhotoCaptureRepository {
  const UnsupportedMeterPhotoCaptureRepository();

  @override
  Future<StoredMeterPhoto?> capture(ReadingSource source) async => null;

  @override
  Future<void> delete(String path) async {}

  @override
  Future<StoredMeterPhoto?> recoverLostCapture() async => null;
}
