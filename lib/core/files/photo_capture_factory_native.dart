import '../integrity/integrity_service.dart';
import 'meter_photo_repository.dart';
import 'meter_photo_store.dart';

MeterPhotoCaptureRepository createPhotoCaptureRepository(
  IntegrityService integrity,
) {
  return DeviceMeterPhotoCaptureRepository(integrity: integrity);
}
