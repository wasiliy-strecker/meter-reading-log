import 'dart:isolate';

import 'binary_backup_codec.dart';

Future<Map<String, dynamic>> runBinaryBackupWorker(
  Map<String, dynamic> input,
  void Function(Map<String, dynamic>) onProgress,
) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_binaryBackupWorkerEntry, {
    'sendPort': receivePort.sendPort,
    'input': input,
  });
  await for (final rawMessage in receivePort) {
    final message = Map<String, dynamic>.from(rawMessage as Map);
    switch (message['type']) {
      case 'progress':
        onProgress(Map<String, dynamic>.from(message['value'] as Map));
      case 'result':
        receivePort.close();
        return Map<String, dynamic>.from(message['value'] as Map);
      case 'error':
        receivePort.close();
        throw BinaryBackupCodecException(
          message['code'] as String,
          message['detail'] as String? ?? '',
        );
    }
  }
  throw const BinaryBackupCodecException('invalidFormat');
}

@pragma('vm:entry-point')
Future<void> _binaryBackupWorkerEntry(Map<String, dynamic> message) async {
  final sendPort = message['sendPort'] as SendPort;
  try {
    final result = await createBinaryBackupArchive(
      Map<String, dynamic>.from(message['input'] as Map),
      (progress) => sendPort.send({'type': 'progress', 'value': progress}),
    );
    sendPort.send({'type': 'result', 'value': result});
  } on BinaryBackupCodecException catch (error) {
    sendPort.send({
      'type': 'error',
      'code': error.code,
      'detail': error.detail,
    });
  } on Object catch (error) {
    sendPort.send({
      'type': 'error',
      'code': 'invalidFormat',
      'detail': error.toString(),
    });
  }
}
