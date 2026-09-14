import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/features/backup/application/backup_restore_providers.dart';
import 'package:meter_reading_log/features/backup/application/encrypted_backup_service.dart';
import 'package:meter_reading_log/features/evidence/presentation/evidence_list_providers.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';

import '../../support/fakes.dart';
import '../../support/reading_fixtures.dart';

void main() {
  for (final fail in [false, true]) {
    test(
      'restore ${fail ? 'partial failure' : 'success'} refreshes previously loaded details and file checks',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'restore_providers_',
        );
        addTearDown(() => temp.delete(recursive: true));
        final file = File('${temp.path}/restored.pdf');
        final meters = MemoryMeterRepository()..items['meter'] = meterFixture();
        final readings = MemoryReadingRepository()
          ..items['reading'] = readingFixture();
        final container = ProviderContainer(
          overrides: [
            meterRepositoryProvider.overrideWithValue(meters),
            meterReadingRepositoryProvider.overrideWithValue(readings),
            evidenceExportRepositoryProvider.overrideWithValue(
              MemoryEvidenceExportRepository(),
            ),
            encryptedBackupServiceProvider.overrideWithValue(
              _RestoreFixture(meters, readings, file, fail),
            ),
          ],
        );
        addTearDown(container.dispose);
        final fileSubscription = container.listen(
          evidenceFileAvailableProvider(file.path),
          (_, _) {},
        );
        addTearDown(fileSubscription.close);
        expect(
          (await container.read(meterByIdProvider('meter').future))!.label,
          'Synthetischer Zähler',
        );
        expect(
          (await container.read(readingByIdProvider('reading').future))!.note,
          'Alt',
        );
        expect(
          await container.read(revisionsForReadingProvider('reading').future),
          isEmpty,
        );
        expect(
          await container.read(evidenceFileAvailableProvider(file.path).future),
          isFalse,
        );
        final restore = container.read(backupRestoreActionProvider);
        if (fail) {
          await expectLater(
            restore('synthetic-backup', '123456'),
            throwsStateError,
          );
        } else {
          await restore('synthetic-backup', '123456');
        }
        expect(
          (await container.read(meterByIdProvider('meter').future))!.label,
          'Wiederhergestellt',
        );
        expect(
          (await container.read(readingByIdProvider('reading').future))!.note,
          'Wiederhergestellt',
        );
        expect(
          (await container.read(
            revisionsForReadingProvider('reading').future,
          )).single.reason,
          'Import',
        );
        expect(
          await container.read(evidenceFileAvailableProvider(file.path).future),
          isTrue,
        );
      },
    );
  }
}

class _RestoreFixture extends EncryptedBackupService {
  _RestoreFixture(
    MemoryMeterRepository meters,
    MemoryReadingRepository readings,
    this.file,
    this.fail,
  ) : super(
        meters: meters,
        readings: readings,
        exports: MemoryEvidenceExportRepository(),
        reminders: NoopMeterReminderRepository(),
      );
  final File file;
  final bool fail;
  @override
  Future<BackupImportResult> restore(String path, String password) async {
    await meters.save(meterFixture().copyWith(label: 'Wiederhergestellt'));
    await readings.save(readingFixture().copyWith(note: 'Wiederhergestellt'));
    await readings.saveRevision(
      ReadingRevision(
        id: 'revision',
        readingId: 'reading',
        changedAt: preciseTime,
        reason: 'Import',
        changes: const {},
      ),
    );
    await file.writeAsString('Synthetic restored PDF');
    if (fail) throw StateError('Synthetic import failure after data writes');
    return const BackupImportResult(
      meters: 1,
      readings: 1,
      exports: 0,
      skipped: 0,
    );
  }
}
