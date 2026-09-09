import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'encrypted_backup_service.dart';

enum BackupFilePickFailure { invalidExtension, unreadableFile }

class BackupFilePickException implements Exception {
  const BackupFilePickException(this.failure);

  final BackupFilePickFailure failure;
}

abstract interface class BackupFilePicker {
  Future<String?> pick();
}

class PlatformBackupFilePicker implements BackupFilePicker {
  const PlatformBackupFilePicker();

  @override
  Future<String?> pick() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensionsFor(
        platform: defaultTargetPlatform,
        isWeb: kIsWeb,
      ),
      allowMultiple: false,
    );
    if (picked == null) return null;

    final file = picked.files.single;
    if (!hasBackupExtension(file.name)) {
      throw const BackupFilePickException(
        BackupFilePickFailure.invalidExtension,
      );
    }
    final path = file.path;
    if (path == null || path.isEmpty) {
      throw const BackupFilePickException(BackupFilePickFailure.unreadableFile);
    }
    return path;
  }

  @visibleForTesting
  static List<String> allowedExtensionsFor({
    required TargetPlatform platform,
    required bool isWeb,
  }) {
    // Android filters custom extensions through its MIME type registry.
    // `.zslbackup` is unknown there and file_picker would fall back to */*.
    // Existing backups are stored as application/octet-stream, represented by
    // the known `.bin` extension, so this keeps them selectable while normal
    // documents, images and videos remain disabled in the system picker.
    if (!isWeb && platform == TargetPlatform.android) {
      return const ['bin'];
    }
    return const [EncryptedBackupService.extension];
  }

  @visibleForTesting
  static bool hasBackupExtension(String fileName) =>
      fileName.toLowerCase().endsWith('.${EncryptedBackupService.extension}');
}
