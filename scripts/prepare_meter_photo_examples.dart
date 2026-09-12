import 'dart:io';

import 'package:image/image.dart' as img;

const _sourceNames = [
  '01_strom_digital_001842-7_kwh',
  '02_gas_mechanisch_004731-82_m3',
  '03_wasser_000286-4_m3',
  '04_strom_alt_012958-6_kwh',
];
const _maxDimension = 1024;
const _maxBytes = 150 * 1024;

// Run from the app directory. These are viewing thumbnails only; the original
// manual OCR fixtures and optimization of users' evidence photos are unchanged.
Future<void> main() async {
  final targetDirectory = Directory('assets/dev/meter_photo_examples');
  await targetDirectory.create(recursive: true);
  var totalBytes = 0;
  for (final name in _sourceNames) {
    final source = File('test/manual_fixtures/meter_photos/$name.png');
    final decoded = img.decodeImage(await source.readAsBytes());
    if (decoded == null) throw StateError('Cannot decode ${source.path}');
    var preview = img.bakeOrientation(decoded);
    if (preview.width > _maxDimension || preview.height > _maxDimension) {
      preview = img.copyResize(
        preview,
        width: preview.width >= preview.height ? _maxDimension : null,
        height: preview.height > preview.width ? _maxDimension : null,
        interpolation: img.Interpolation.average,
      );
    }
    preview.exif.clear();
    preview.iccProfile = null;
    var quality = 80;
    var bytes = img.encodeJpg(preview, quality: quality);
    while (bytes.length > _maxBytes && quality > 50) {
      quality -= 5;
      bytes = img.encodeJpg(preview, quality: quality);
    }
    if (bytes.length > _maxBytes) {
      throw StateError('$name exceeds the 150 KiB preview budget');
    }
    final target = File('${targetDirectory.path}/$name.jpg');
    await target.writeAsBytes(bytes, flush: true);
    totalBytes += bytes.length;
    stdout.writeln(
      '${target.path}: ${preview.width}x${preview.height}, '
      '${(bytes.length / 1024).toStringAsFixed(1)} KiB, JPEG quality $quality',
    );
  }
  stdout.writeln('Total: ${(totalBytes / 1024).toStringAsFixed(1)} KiB');
}
