import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../features/meters/domain/meter_reading.dart';

class IntegrityService {
  const IntegrityService();

  Future<String> sha256Bytes(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return _hex(hash.bytes);
  }

  Future<String> sha256Text(String text) {
    return sha256Bytes(utf8.encode(text));
  }

  Future<String> readingManifestHash(MeterReading reading) {
    final json = reading.toJson()
      ..remove('manifestSha256')
      ..remove('photoPath');
    return sha256Text(canonicalJson(json));
  }

  Future<String> readingsManifestHash(List<MeterReading> readings) {
    final payload = readings
        .map((reading) {
          final json = reading.toJson()
            ..remove('manifestSha256')
            ..remove('photoPath');
          return json;
        })
        .toList(growable: false);
    return sha256Text(canonicalJson(payload));
  }

  String canonicalJson(Object? value) => jsonEncode(_canonicalize(value));

  Object? _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    if (value is Iterable) {
      return value.map(_canonicalize).toList(growable: false);
    }
    return value;
  }

  String _hex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

Uint8List bytesOf(List<int> value) => Uint8List.fromList(value);
