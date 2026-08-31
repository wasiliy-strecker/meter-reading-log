import '../integrity/integrity_service.dart';
import 'meter_photo_repository.dart';

MeterPhotoCaptureRepository createPhotoCaptureRepository(
  IntegrityService integrity,
) {
  return const UnsupportedMeterPhotoCaptureRepository();
}
