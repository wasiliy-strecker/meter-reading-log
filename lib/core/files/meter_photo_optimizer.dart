import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:universal_io/io.dart';

typedef NativeMeterPhotoCompressor =
    Future<bool> Function(String sourcePath, String targetPath);

class MeterPhotoOptimizer {
  const MeterPhotoOptimizer({this.nativeCompressor});

  final NativeMeterPhotoCompressor? nativeCompressor;

  static const maxDimension = 1920;
  static const jpegQuality = 88;

  Future<bool> optimize({
    required String sourcePath,
    required String targetPath,
  }) async {
    final target = File(targetPath);
    if (await target.exists()) await target.delete();

    if (nativeCompressor != null ||
        (!kIsWeb && (Platform.isAndroid || Platform.isIOS))) {
      try {
        final compressed = await (nativeCompressor ?? _compressNative)(
          sourcePath,
          targetPath,
        );
        if (compressed &&
            await compute(_boundNativeMeterPhoto, <String, Object>{
              'sourcePath': targetPath,
              'targetPath': '$targetPath.bounded.jpg',
              'maxDimension': maxDimension,
              'jpegQuality': jpegQuality,
            }, debugLabel: 'meter-photo-bounds')) {
          return true;
        }
      } on MissingPluginException {
        // Unit tests and unsupported platforms use the Dart fallback below.
      } on Object {
        // A format rejected by the native codec can still work in Dart.
      }
    }

    try {
      return await compute(_optimizeMeterPhotoWithDart, <String, Object>{
        'sourcePath': sourcePath,
        'targetPath': targetPath,
        'maxDimension': maxDimension,
        'jpegQuality': jpegQuality,
      }, debugLabel: 'meter-photo-optimizer');
    } on Object {
      return false;
    }
  }

  static Future<bool> _compressNative(
    String sourcePath,
    String targetPath,
  ) async {
    return await FlutterImageCompress.compressAndGetFile(
          sourcePath,
          targetPath,
          minWidth: maxDimension,
          minHeight: maxDimension,
          quality: jpegQuality,
          autoCorrectionAngle: true,
          format: CompressFormat.jpeg,
          keepExif: false,
        ) !=
        null;
  }
}

Future<bool> _boundNativeMeterPhoto(Map<String, Object> input) async {
  final source = File(input['sourcePath']! as String);
  if (!await source.exists()) return false;
  final decoded = img.decodeImage(await source.readAsBytes());
  if (decoded == null) return false;
  final maxDimension = input['maxDimension']! as int;
  if (decoded.width <= maxDimension && decoded.height <= maxDimension) {
    return true;
  }
  final bounded = File(input['targetPath']! as String);
  try {
    if (!await _optimizeMeterPhotoWithDart(input)) return false;
    await bounded.rename(source.path);
    return true;
  } finally {
    if (await bounded.exists()) await bounded.delete();
  }
}

Future<bool> _optimizeMeterPhotoWithDart(Map<String, Object> input) async {
  final source = File(input['sourcePath']! as String);
  final target = File(input['targetPath']! as String);
  final decoded = img.decodeImage(await source.readAsBytes());
  if (decoded == null) return false;

  var normalized = img.bakeOrientation(decoded);
  final maxDimension = input['maxDimension']! as int;
  if (normalized.width > maxDimension || normalized.height > maxDimension) {
    normalized = normalized.width >= normalized.height
        ? img.copyResize(
            normalized,
            width: maxDimension,
            interpolation: img.Interpolation.linear,
          )
        : img.copyResize(
            normalized,
            height: maxDimension,
            interpolation: img.Interpolation.linear,
          );
  }
  normalized.exif.clear();
  normalized.iccProfile = null;
  await target.writeAsBytes(
    img.encodeJpg(normalized, quality: input['jpegQuality']! as int),
    flush: true,
  );
  return await target.exists() && await target.length() > 0;
}
