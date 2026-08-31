import 'package:universal_io/io.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../integrity/integrity_service.dart';
import '../utils/id_generator.dart';
import '../../features/meters/domain/meter_reading.dart';
import 'meter_photo_repository.dart';

class DeviceMeterPhotoCaptureRepository implements MeterPhotoCaptureRepository {
  DeviceMeterPhotoCaptureRepository({
    ImagePicker? picker,
    IntegrityService integrity = const IntegrityService(),
  }) : _picker = picker ?? ImagePicker(),
       _integrity = integrity;

  final ImagePicker _picker;
  final IntegrityService _integrity;

  @override
  Future<StoredMeterPhoto?> capture(ReadingSource source) async {
    final picked = await _picker.pickImage(
      source: source == ReadingSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      requestFullMetadata: true,
    );
    if (picked == null) {
      return null;
    }
    return _persist(picked, source: source, capturedAt: DateTime.now());
  }

  @override
  Future<StoredMeterPhoto?> recoverLostCapture() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null || response.files!.isEmpty) {
      return null;
    }
    return _persist(
      response.files!.first,
      source: ReadingSource.camera,
      capturedAt: DateTime.now(),
    );
  }

  Future<StoredMeterPhoto> _persist(
    XFile picked, {
    required ReadingSource source,
    required DateTime capturedAt,
  }) async {
    final bytes = await picked.readAsBytes();
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'meter_photos'));
    await directory.create(recursive: true);
    final extension = _safeExtension(p.extension(picked.name));
    final file = File(
      p.join(directory.path, '${newLocalId('photo')}$extension'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return StoredMeterPhoto(
      path: file.path,
      sha256: await _integrity.sha256Bytes(bytes),
      source: source,
      capturedAt: capturedAt,
    );
  }

  String _safeExtension(String value) {
    return switch (value.toLowerCase()) {
      '.png' => '.png',
      '.heic' || '.heif' => '.heic',
      _ => '.jpg',
    };
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
