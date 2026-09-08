import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/features/backup/application/backup_file_exporter.dart';
import 'package:meter_reading_log/features/backup/application/encrypted_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.appfactory.meter_reading_log/backup_share',
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'saves the cache file with the native Android document picker',
    () async {
      MethodCall? receivedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            receivedCall = call;
            return <String, Object?>{
              'status': 'saved',
              'fileName': 'mein-backup.zslbackup',
            };
          });

      final result = await const PlatformBackupFileExporter().save(_backup());

      expect(receivedCall?.method, 'saveBackup');
      expect(
        (receivedCall?.arguments as Map<Object?, Object?>)['path'],
        '/tmp/test.zslbackup',
      );
      expect(result.status, BackupSaveStatus.saved);
      expect(result.fileName, 'mein-backup.zslbackup');
    },
  );

  test('reports a cancelled Android document picker', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => <String, Object?>{'status': 'cancelled'},
        );

    final result = await const PlatformBackupFileExporter().save(_backup());

    expect(result.status, BackupSaveStatus.cancelled);
    expect(result.fileName, isNull);
  });
}

CreatedBackup _backup() => CreatedBackup(
  path: '/tmp/test.zslbackup',
  sizeBytes: 8 * 1024 * 1024,
  preview: BackupPreview(
    createdAt: DateTime.utc(2026, 9, 8, 8, 30),
    meterCount: 2,
    readingCount: 4,
    exportCount: 2,
  ),
);
