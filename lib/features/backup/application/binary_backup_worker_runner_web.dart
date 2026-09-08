import 'binary_backup_codec.dart';

Future<Map<String, dynamic>> runBinaryBackupWorker(
  Map<String, dynamic> input,
  void Function(Map<String, dynamic>) onProgress,
) {
  return createBinaryBackupArchive(input, onProgress);
}
