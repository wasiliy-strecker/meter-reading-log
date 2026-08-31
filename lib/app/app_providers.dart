import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/files/meter_photo_repository.dart';
import '../core/files/photo_capture_factory.dart';
import '../core/integrity/integrity_service.dart';
import '../core/ocr/meter_ocr_repository.dart';
import '../core/ocr/mlkit_meter_ocr_repository.dart';
import '../core/persistence/persistence_bundle.dart';
import '../core/persistence/persistence_factory.dart';
import '../core/reminders/local_notification_reminder_repository.dart';
import '../features/evidence/application/evidence_report_service.dart';
import '../features/backup/application/encrypted_backup_service.dart';
import '../features/evidence/domain/evidence_export.dart';
import '../features/meters/application/meter_services.dart';
import '../features/meters/domain/meter.dart';
import '../features/meters/domain/meter_reading.dart';
import '../features/meters/domain/meter_repositories.dart';

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

final integrityServiceProvider = Provider<IntegrityService>(
  (ref) => const IntegrityService(),
);

final meterPhotoCaptureRepositoryProvider =
    Provider<MeterPhotoCaptureRepository>(
      (ref) =>
          createPhotoCaptureRepository(ref.watch(integrityServiceProvider)),
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
    reminders: LocalNotificationReminderRepository.instance,
  ),
);

final meterReadingServiceProvider = Provider<MeterReadingService>(
  (ref) => MeterReadingService(
    readings: ref.watch(meterReadingRepositoryProvider),
    photos: ref.watch(meterPhotoCaptureRepositoryProvider),
    integrity: ref.watch(integrityServiceProvider),
  ),
);

final evidenceReportServiceProvider = Provider<EvidenceReportService>(
  (ref) => EvidenceReportService(
    exports: ref.watch(evidenceExportRepositoryProvider),
    integrity: ref.watch(integrityServiceProvider),
  ),
);

final encryptedBackupServiceProvider = Provider<EncryptedBackupService>(
  (ref) => EncryptedBackupService(
    meters: ref.watch(meterRepositoryProvider),
    readings: ref.watch(meterReadingRepositoryProvider),
    exports: ref.watch(evidenceExportRepositoryProvider),
    reminders: LocalNotificationReminderRepository.instance,
    integrity: ref.watch(integrityServiceProvider),
  ),
);

final metersProvider = StreamProvider<List<Meter>>(
  (ref) => ref.watch(meterRepositoryProvider).watchAll(),
);

final meterByIdProvider = FutureProvider.family<Meter?, String>(
  (ref, id) => ref.watch(meterRepositoryProvider).findById(id),
);

final readingsForMeterProvider =
    StreamProvider.family<List<MeterReading>, String>(
      (ref, meterId) =>
          ref.watch(meterReadingRepositoryProvider).watchForMeter(meterId),
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
