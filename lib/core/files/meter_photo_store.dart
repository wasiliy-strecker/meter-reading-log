import 'package:universal_io/io.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../integrity/integrity_service.dart';
import '../utils/id_generator.dart';
import '../../features/meters/domain/meter_reading.dart';
import 'meter_photo_optimizer.dart';
import 'meter_photo_repository.dart';

typedef MeterPhotoDocumentsDirectoryProvider = Future<Directory> Function();
typedef MeterPhotoPicker = Future<XFile?> Function(ReadingSource source);

class DeviceMeterPhotoCaptureRepository implements MeterPhotoCaptureRepository {
  DeviceMeterPhotoCaptureRepository({
    ImagePicker? picker,
    IntegrityService integrity = const IntegrityService(),
    MeterPhotoOptimizer optimizer = const MeterPhotoOptimizer(),
    MeterPhotoDocumentsDirectoryProvider? documentsDirectoryProvider,
    MeterPhotoPicker? photoPicker,
  }) : _picker = picker ?? ImagePicker(),
       _integrity = integrity,
       _optimizer = optimizer,
       _photoPicker = photoPicker,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final ImagePicker _picker;
  final IntegrityService _integrity;
  final MeterPhotoOptimizer _optimizer;
  final MeterPhotoDocumentsDirectoryProvider _documentsDirectoryProvider;
  final MeterPhotoPicker? _photoPicker;

  @override
  Future<StoredMeterPhoto?> capture(ReadingSource source) async {
    final picked = await (_photoPicker != null
        ? _photoPicker(source)
        : _picker.pickImage(
            source: source == ReadingSource.camera
                ? ImageSource.camera
                : ImageSource.gallery,
            requestFullMetadata: false,
          ));
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
    final documents = await _documentsDirectoryProvider();
    final directory = Directory(p.join(documents.path, 'meter_photos'));
    await directory.create(recursive: true);
    final id = newLocalId('photo');
    final optimizedFile = File(p.join(directory.path, '$id.jpg'));
    final staging = File(p.join(directory.path, '$id.preparing.jpg'));
    final optimized = await _optimizer.optimize(
      sourcePath: picked.path,
      targetPath: staging.path,
    );
    late final File file;
    if (optimized) {
      file = await staging.rename(optimizedFile.path);
    } else {
      if (await staging.exists()) await staging.delete();
      final extension = _safeExtension(p.extension(picked.name));
      file = File(p.join(directory.path, '$id$extension'));
      await File(picked.path).copy(file.path);
    }
    final bytes = await file.readAsBytes();
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
