import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/integrity/integrity_service.dart';

void main() {
  test('canonical JSON is stable across map insertion order', () {
    const service = IntegrityService();
    final left = service.canonicalJson({
      'b': 2,
      'a': {'z': 1, 'c': 3},
    });
    final right = service.canonicalJson({
      'a': {'c': 3, 'z': 1},
      'b': 2,
    });

    expect(left, right);
  });

  test('SHA-256 matches known vector', () async {
    const service = IntegrityService();
    expect(
      await service.sha256Text('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
