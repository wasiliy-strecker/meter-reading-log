import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:universal_io/io.dart';

import '../integrity/integrity_service.dart';
import 'meter_photo_repository.dart';
import 'meter_photo_store.dart';

MeterPhotoCaptureRepository createPhotoCaptureRepository(
  IntegrityService integrity,
) {
  if (Platform.isAndroid) {
    configureAndroidPhotoPicker(ImagePickerPlatform.instance);
  }
  return DeviceMeterPhotoCaptureRepository(integrity: integrity);
}

void configureAndroidPhotoPicker(ImagePickerPlatform implementation) {
  if (implementation is ImagePickerAndroid) {
    implementation.useAndroidPhotoPicker = true;
  }
}
