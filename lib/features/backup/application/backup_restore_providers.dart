import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../evidence/presentation/evidence_list_providers.dart';
import 'encrypted_backup_service.dart';

typedef RestoreBackup =
    Future<BackupImportResult> Function(String path, String password);

/// Refreshes all cached views even when an import fails after partial writes.
final backupRestoreActionProvider = Provider<RestoreBackup>((ref) {
  return (path, password) async {
    try {
      return await ref
          .read(encryptedBackupServiceProvider)
          .restore(path, password);
    } finally {
      if (ref.mounted) {
        ref.invalidate(metersProvider);
        ref.invalidate(meterDashboardItemsProvider);
        ref.invalidate(meterByIdProvider);
        ref.invalidate(readingByIdProvider);
        ref.invalidate(revisionsForReadingProvider);
        ref.invalidate(readingsForMeterProvider);
        ref.invalidate(meterHistoryPageProvider);
        ref.invalidate(evidenceForMeterProvider);
        ref.invalidate(evidenceExportPageProvider);
        ref.invalidate(evidenceFileAvailableProvider);
        ref.invalidate(reminderStatusesProvider);
      }
    }
  };
});
