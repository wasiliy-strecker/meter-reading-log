import 'dart:math';

String newLocalId(String prefix, {DateTime? now}) {
  final timestamp = (now ?? DateTime.now()).microsecondsSinceEpoch
      .toRadixString(36);
  final random = Random.secure();
  final suffix = List.generate(
    10,
    (_) => random.nextInt(36).toRadixString(36),
  ).join();
  return '${prefix}_$timestamp$suffix';
}
