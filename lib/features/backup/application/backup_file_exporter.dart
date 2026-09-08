import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_io/io.dart';

import 'encrypted_backup_service.dart';

enum BackupSaveStatus { saved, cancelled }

class BackupSaveResult {
  const BackupSaveResult._({required this.status, this.fileName});

  const BackupSaveResult.saved(String fileName)
    : this._(status: BackupSaveStatus.saved, fileName: fileName);

  const BackupSaveResult.cancelled()
    : this._(status: BackupSaveStatus.cancelled);

  final BackupSaveStatus status;
  final String? fileName;
}

abstract interface class BackupFileExporter {
  bool get supportsDirectSave;

  Future<BackupSaveResult> save(CreatedBackup backup);

  Future<void> share(CreatedBackup backup);

  Future<void> discard(CreatedBackup backup);
}

class PlatformBackupFileExporter implements BackupFileExporter {
  const PlatformBackupFileExporter();

  static const _channel = MethodChannel(
    'com.appfactory.meter_reading_log/backup_share',
  );

  @override
  bool get supportsDirectSave =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<BackupSaveResult> save(CreatedBackup backup) async {
    if (!supportsDirectSave) {
      throw UnsupportedError(
        'Die direkte Speicherortwahl ist auf dieser Plattform noch nicht verfügbar.',
      );
    }
    final value = await _channel.invokeMapMethod<String, Object?>(
      'saveBackup',
      {'path': backup.path},
    );
    if (value?['status'] == 'saved') {
      final fileName = value?['fileName'] as String?;
      return BackupSaveResult.saved(
        fileName?.isNotEmpty == true ? fileName! : _fileName(backup.path),
      );
    }
    return const BackupSaveResult.cancelled();
  }

  @override
  Future<void> share(CreatedBackup backup) {
    final title = 'ZählerstandLog Backup';
    final sizeInMb = backup.sizeBytes / (1024 * 1024);
    final text =
        '${backup.preview.meterCount} Zähler, ${backup.preview.readingCount} Ablesungen · ${sizeInMb.toStringAsFixed(1)} MB';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _channel.invokeMethod<void>('shareBackup', {
        'path': backup.path,
        'title': title,
        'text': text,
      });
    }
    return SharePlus.instance
        .share(
          ShareParams(
            title: title,
            text: text,
            files: [
              XFile(
                backup.path,
                mimeType: 'application/octet-stream',
                name: _fileName(backup.path),
              ),
            ],
          ),
        )
        .then((_) {});
  }

  @override
  Future<void> discard(CreatedBackup backup) async {
    final file = File(backup.path);
    if (await file.exists()) await file.delete();
  }

  static String _fileName(String path) => path.split(RegExp(r'[/\\]')).last;
}
