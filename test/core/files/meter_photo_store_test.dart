import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:meter_reading_log/core/files/meter_photo_optimizer.dart';
import 'package:meter_reading_log/core/files/meter_photo_store.dart';
import 'package:meter_reading_log/core/integrity/integrity_service.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';

void main() {
  test(
    'rotated photo respects the longest-edge limit and removes orientation metadata',
    () async {
      final temp = await Directory.systemTemp.createTemp('rotated_photo_');
      addTearDown(() => temp.delete(recursive: true));
      final source = File('${temp.path}/source.jpg');
      final original = img.Image(width: 2400, height: 1600)
        ..exif.imageIfd.orientation = 6;
      await source.writeAsBytes(img.encodeJpg(original));
      final target = File('${temp.path}/target.jpg');
      expect(
        await const MeterPhotoOptimizer().optimize(
          sourcePath: source.path,
          targetPath: target.path,
        ),
        isTrue,
      );
      final decoded = img.decodeImage(await target.readAsBytes())!;
      expect((decoded.width, decoded.height), (1280, 1920));
      expect(decoded.exif.imageIfd.orientation, isNull);
    },
  );

  for (final size in [(2560, 1920), (1920, 2560), (800, 600)]) {
    test(
      'bounds native output ${size.$1} x ${size.$2} before storage and hashing',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'native_photo_bounds_',
        );
        addTearDown(() => temp.delete(recursive: true));
        final nativeBytes = img.encodeJpg(
          img.Image(width: size.$1, height: size.$2),
        );
        final source = File('${temp.path}/source.jpg');
        await source.writeAsBytes(nativeBytes);
        var calls = 0;
        final optimizer = MeterPhotoOptimizer(
          nativeCompressor: (sourcePath, targetPath) async {
            calls++;
            await File(targetPath).writeAsBytes(nativeBytes);
            return true;
          },
        );
        final repository = DeviceMeterPhotoCaptureRepository(
          integrity: const IntegrityService(),
          optimizer: optimizer,
          photoPicker: (_) async => XFile(source.path),
          documentsDirectoryProvider: () async => temp,
        );
        final photo = (await repository.capture(ReadingSource.gallery))!;
        final bytes = await File(photo.path).readAsBytes();
        final decoded = img.decodeImage(bytes)!;
        expect(calls, 1);
        expect(decoded.width, lessThanOrEqualTo(1920));
        expect(decoded.height, lessThanOrEqualTo(1920));
        expect(
          decoded.width / decoded.height,
          closeTo(size.$1 / size.$2, 0.002),
        );
        if (size.$1 == 800) expect((decoded.width, decoded.height), (800, 600));
        expect(photo.sha256, await const IntegrityService().sha256Bytes(bytes));
        expect(await source.readAsBytes(), nativeBytes);
        expect(
          (await Directory('${temp.path}/meter_photos').list().toList()),
          hasLength(1),
        );
      },
    );
  }

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

  test('optimized photos do not retain EXIF metadata', () async {
    final temp = await Directory.systemTemp.createTemp('photo_metadata_');
    addTearDown(() => temp.delete(recursive: true));
    final source = File('${temp.path}/with-metadata.jpg');
    final image = img.Image(width: 800, height: 600)
      ..exif.imageIfd.make = 'Private camera'
      ..exif.imageIfd.imageDescription = 'Private location';
    await source.writeAsBytes(img.encodeJpg(image, quality: 95));
    final target = File('${temp.path}/optimized.jpg');

    final optimized = await const MeterPhotoOptimizer().optimize(
      sourcePath: source.path,
      targetPath: target.path,
    );
    final decoded = img.decodeJpg(await target.readAsBytes());

    expect(optimized, isTrue);
    expect(decoded, isNotNull);
    expect(decoded!.exif.isEmpty, isTrue);
  });

  test('an unoptimizable photo is not stored as a raw fallback', () async {
    final temp = await Directory.systemTemp.createTemp('failed_photo_');
    addTearDown(() => temp.delete(recursive: true));
    final source = File('${temp.path}/source.jpg');
    await source.writeAsBytes([1, 2, 3, 4]);
    final documents = Directory('${temp.path}/documents');
    final repository = DeviceMeterPhotoCaptureRepository(
      optimizer: const _FailingMeterPhotoOptimizer(),
      photoPicker: (_) async => XFile(source.path),
      documentsDirectoryProvider: () async => documents,
    );

    await expectLater(
      repository.capture(ReadingSource.gallery),
      throwsA(isA<MeterPhotoProcessingException>()),
    );
    final storedFiles = await Directory(
      '${documents.path}/meter_photos',
    ).list().toList();
    expect(storedFiles, isEmpty);
    expect(await source.readAsBytes(), [1, 2, 3, 4]);
  });
}

class _FailingMeterPhotoOptimizer extends MeterPhotoOptimizer {
  const _FailingMeterPhotoOptimizer();

  @override
  Future<bool> optimize({
    required String sourcePath,
    required String targetPath,
  }) async => false;
}
