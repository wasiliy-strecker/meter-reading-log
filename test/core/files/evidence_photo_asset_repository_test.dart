import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meter_reading_log/core/files/evidence_photo_asset_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'creates and reuses a bounded PDF photo without changing the original',
    () async {
      final temp = await Directory.systemTemp.createTemp('pdf_photo_cache_');
      addTearDown(() => temp.delete(recursive: true));
      final source = File('${temp.path}/original.jpg');
      final originalBytes = img.encodeJpg(
        img.Image(width: 2400, height: 1200),
        quality: 95,
      );
      await source.writeAsBytes(originalBytes);
      final cache = Directory('${temp.path}/cache');
      final repository = LocalEvidencePhotoAssetRepository(
        cacheDirectoryProvider: () async => cache,
      );

      final first = await repository.prepare(
        path: source.path,
        sha256: 'a' * 64,
      );
      final firstModified = await File(first!).lastModified();
      final second = await repository.prepare(
        path: source.path,
        sha256: 'a' * 64,
      );
      final decoded = img.decodeImage(await File(first).readAsBytes());

      expect(second, first);
      expect(await File(first).lastModified(), firstModified);
      expect(decoded, isNotNull);
      expect(decoded!.width, 1600);
      expect(decoded.height, 800);
      expect(await source.readAsBytes(), originalBytes);
    },
  );
}
