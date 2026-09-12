import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/files/meter_photo_repository.dart';
import '../core/files/evidence_photo_asset_repository.dart';
import '../core/files/photo_capture_factory.dart';
import '../core/integrity/integrity_service.dart';
import '../core/ocr/meter_ocr_repository.dart';
import '../core/ocr/mlkit_meter_ocr_repository.dart';
import '../core/persistence/persistence_bundle.dart';
import '../core/persistence/persistence_factory.dart';
import '../core/reminders/local_notification_reminder_repository.dart';
import '../features/backup/application/backup_file_exporter.dart';
import '../features/backup/application/backup_file_picker.dart';
import '../features/backup/application/encrypted_backup_service.dart';
import '../features/evidence/application/evidence_report_service.dart';
import '../features/evidence/domain/evidence_export.dart';
import '../features/meters/application/meter_services.dart';
import '../features/meters/data/dashboard_repository_factory.dart';
import '../features/meters/domain/meter.dart';
import '../features/meters/domain/meter_dashboard_item.dart';
import '../features/meters/domain/meter_reading.dart';
import '../features/meters/domain/meter_reading_page.dart';
import '../features/meters/domain/meter_repositories.dart';

final appVersionProvider = Provider<String>((ref) => '');

final persistenceBundleProvider = Provider<PersistenceBundle>((ref) {
  final bundle = createPersistenceBundle();
  ref.onDispose(bundle.dispose);
  return bundle;
});

final meterRepositoryProvider = Provider<MeterRepository>(
  (ref) => ref.watch(persistenceBundleProvider).meters,
);

final meterReadingRepositoryProvider = Provider<MeterReadingRepository>(
  (ref) => ref.watch(persistenceBundleProvider).readings,
);

final evidenceExportRepositoryProvider = Provider<EvidenceExportRepository>(
  (ref) => ref.watch(persistenceBundleProvider).exports,
);

final meterDashboardRepositoryProvider = Provider<MeterDashboardRepository>(
  (ref) => createMeterDashboardRepository(
    meters: ref.watch(meterRepositoryProvider),
    readings: ref.watch(meterReadingRepositoryProvider),
  ),
);

final integrityServiceProvider = Provider<IntegrityService>(
  (ref) => const IntegrityService(),
);

final meterReminderRepositoryProvider = Provider<MeterReminderRepository>(
  (ref) => LocalNotificationReminderRepository.instance,
);

final meterPhotoCaptureRepositoryProvider =
    Provider<MeterPhotoCaptureRepository>(
      (ref) =>
          createPhotoCaptureRepository(ref.watch(integrityServiceProvider)),
    );

final evidencePhotoAssetRepositoryProvider =
    Provider<EvidencePhotoAssetRepository>(
      (ref) => LocalEvidencePhotoAssetRepository(),
    );

final meterOcrRepositoryProvider = Provider<MeterOcrRepository>((ref) {
  if (kIsWeb) {
    return const UnsupportedMeterOcrRepository();
  }
  return const MlKitMeterOcrRepository();
});

final meterServiceProvider = Provider<MeterService>(
  (ref) => MeterService(
    meters: ref.watch(meterRepositoryProvider),
    readings: ref.watch(meterReadingRepositoryProvider),
    exports: ref.watch(evidenceExportRepositoryProvider),
    photos: ref.watch(meterPhotoCaptureRepositoryProvider),
    reminders: ref.watch(meterReminderRepositoryProvider),
    evidencePhotos: ref.watch(evidencePhotoAssetRepositoryProvider),
  ),
);

final meterReadingServiceProvider = Provider<MeterReadingService>(
  (ref) => MeterReadingService(
    meters: ref.watch(meterRepositoryProvider),
    readings: ref.watch(meterReadingRepositoryProvider),
    photos: ref.watch(meterPhotoCaptureRepositoryProvider),
    integrity: ref.watch(integrityServiceProvider),
    reminders: ref.watch(meterReminderRepositoryProvider),
    evidencePhotos: ref.watch(evidencePhotoAssetRepositoryProvider),
  ),
);

final evidenceReportServiceProvider = Provider<EvidenceReportService>(
  (ref) => EvidenceReportService(
    exports: ref.watch(evidenceExportRepositoryProvider),
    integrity: ref.watch(integrityServiceProvider),
    photoAssets: ref.watch(evidencePhotoAssetRepositoryProvider),
  ),
);

final encryptedBackupServiceProvider = Provider<EncryptedBackupService>(
  (ref) => EncryptedBackupService(
    meters: ref.watch(meterRepositoryProvider),
    readings: ref.watch(meterReadingRepositoryProvider),
    exports: ref.watch(evidenceExportRepositoryProvider),
    reminders: ref.watch(meterReminderRepositoryProvider),
    integrity: ref.watch(integrityServiceProvider),
  ),
);

final backupFileExporterProvider = Provider<BackupFileExporter>(
  (ref) => const PlatformBackupFileExporter(),
);

final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => const PlatformBackupFilePicker(),
);

final metersProvider = StreamProvider<List<Meter>>(
  (ref) => ref.watch(meterRepositoryProvider).watchAll(),
);

final meterDashboardItemsProvider = StreamProvider<List<MeterDashboardItem>>(
  (ref) => ref.watch(meterDashboardRepositoryProvider).watchAll(),
);

final reminderStatusChangesProvider = StreamProvider<int>(
  (ref) => ref.watch(meterReminderRepositoryProvider).statusChanges,
);

final reminderStatusesProvider = FutureProvider<Map<String, ReminderStatus>>((
  ref,
) async {
  ref.watch(reminderStatusChangesProvider);
  final dashboardItems = await ref.watch(meterDashboardItemsProvider.future);
  return ref
      .watch(meterReminderRepositoryProvider)
      .loadStatuses(dashboardItems.map((item) => item.meter.id));
});

final meterByIdProvider = FutureProvider.family<Meter?, String>(
  (ref, id) => ref.watch(meterRepositoryProvider).findById(id),
);

final readingsForMeterProvider =
    StreamProvider.family<List<MeterReading>, String>(
      (ref, meterId) =>
          ref.watch(meterReadingRepositoryProvider).watchForMeter(meterId),
    );

typedef MeterHistoryPageRequest = ({
  String meterId,
  int limit,
  int offset,
  String query,
});

final meterHistoryPageProvider = StreamProvider.autoDispose
    .family<MeterReadingPage, MeterHistoryPageRequest>(
      (ref, request) => ref
          .watch(meterReadingRepositoryProvider)
          .watchPageForMeter(
            request.meterId,
            limit: request.limit,
            offset: request.offset,
            query: request.query,
          ),
    );

final readingByIdProvider = FutureProvider.family<MeterReading?, String>(
  (ref, id) => ref.watch(meterReadingRepositoryProvider).findById(id),
);

final revisionsForReadingProvider =
    FutureProvider.family<List<ReadingRevision>, String>(
      (ref, id) => ref.watch(meterReadingRepositoryProvider).loadRevisions(id),
    );

final evidenceForMeterProvider =
    StreamProvider.family<List<EvidenceExportRecord>, String>(
      (ref, id) =>
          ref.watch(evidenceExportRepositoryProvider).watchForMeter(id),
    );
