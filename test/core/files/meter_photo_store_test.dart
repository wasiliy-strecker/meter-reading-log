import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:meter_reading_log/core/files/meter_photo_optimizer.dart';
import 'package:meter_reading_log/core/files/meter_photo_store.dart';
import 'package:meter_reading_log/core/integrity/integrity_service.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new meter photos are normalized before hashing and storage', () async {
    final temp = await Directory.systemTemp.createTemp('meter_photo_store_');
    addTearDown(() => temp.delete(recursive: true));
    final source = File('${temp.path}/camera-original.png');
    final originalBytes = img.encodePng(img.Image(width: 2400, height: 1200));
    await source.writeAsBytes(originalBytes);
    final documents = Directory('${temp.path}/documents');
    final repository = DeviceMeterPhotoCaptureRepository(
      photoPicker: (_) async => XFile(source.path),
      documentsDirectoryProvider: () async => documents,
    );

    final stored = await repository.capture(ReadingSource.gallery);
    final storedBytes = await File(stored!.path).readAsBytes();
    final decoded = img.decodeImage(storedBytes);

    expect(stored.path, endsWith('.jpg'));
    expect(decoded, isNotNull);
    expect(decoded!.width, MeterPhotoOptimizer.maxDimension);
    expect(decoded.height, 960);
    expect(
      stored.sha256,
      await const IntegrityService().sha256Bytes(storedBytes),
    );
    expect(await source.readAsBytes(), originalBytes);
  });

  test('small photos are never enlarged', () async {
    final temp = await Directory.systemTemp.createTemp('small_meter_photo_');
    addTearDown(() => temp.delete(recursive: true));
    final source = File('${temp.path}/small.jpg');
    await source.writeAsBytes(
      img.encodeJpg(img.Image(width: 800, height: 600), quality: 95),
    );
    final target = File('${temp.path}/optimized.jpg');

    final optimized = await const MeterPhotoOptimizer().optimize(
      sourcePath: source.path,
      targetPath: target.path,
    );
    final decoded = img.decodeImage(await target.readAsBytes());

    expect(optimized, isTrue);
    expect(decoded, isNotNull);
    expect(decoded!.width, 800);
    expect(decoded.height, 600);
  });
}
