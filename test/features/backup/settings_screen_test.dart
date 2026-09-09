import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/reminders/local_notification_reminder_repository.dart';
import 'package:meter_reading_log/features/backup/application/backup_file_exporter.dart';
import 'package:meter_reading_log/features/backup/application/backup_file_picker.dart';
import 'package:meter_reading_log/features/backup/application/encrypted_backup_service.dart';
import 'package:meter_reading_log/features/backup/presentation/settings_screen.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('privacy policy opens the dedicated German URL', (tester) async {
    Uri? openedUri;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(
            privacyPolicyLauncher: (uri) async {
              openedUri = uri;
              return true;
            },
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('open-privacy-policy'));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();

    expect(
      openedUri,
      Uri.parse(
        'https://www.appfabrik-ai.de/de/apps/zaehlerstandlog/datenschutz/',
      ),
    );
    expect(find.textContaining('contact@appfabrik-ai.de'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed privacy policy launch shows a helpful message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(privacyPolicyLauncher: (_) async => false),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('open-privacy-policy'));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();

    expect(
      find.text(
        'Die Datenschutzerklärung konnte nicht geöffnet werden. Bitte versuche es erneut.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('backup password dialog closes cleanly when cancelled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );

    await tester.tap(find.text('Verschlüsseltes Backup erstellen'));
    await tester.pumpAndSettle();
    expect(find.text('Backup-Passwort festlegen'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Passwort'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Passwort wiederholen'),
      findsOneWidget,
    );
    expect(find.text('Mindestens 6 Zeichen'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
    await tester.pumpAndSettle();

    expect(find.text('Backup-Passwort festlegen'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valid backup selection opens the password dialog', (
    tester,
  ) async {
    final picker = _FakeBackupFilePicker(['/tmp/import.zslbackup']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupFilePickerProvider.overrideWithValue(picker)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Backup wiederherstellen'));
    await tester.pumpAndSettle();

    expect(picker.pickCalls, 1);
    expect(find.text('Backup-Passwort'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Passwort'), findsOneWidget);
  });

  testWidgets('foreign backup selection is rejected before password entry', (
    tester,
  ) async {
    final picker = _FakeBackupFilePicker([
      const BackupFilePickException(BackupFilePickFailure.invalidExtension),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupFilePickerProvider.overrideWithValue(picker)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Backup wiederherstellen'));
    await tester.pumpAndSettle();

    expect(find.text('Backup-Passwort'), findsNothing);
    expect(
      find.text('Bitte wähle eine ZählerstandLog-Backup-Datei (.zslbackup).'),
      findsOneWidget,
    );
  });

  testWidgets('cancelled backup selection stays on settings', (tester) async {
    final picker = _FakeBackupFilePicker([null]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupFilePickerProvider.overrideWithValue(picker)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Backup wiederherstellen'));
    await tester.pumpAndSettle();

    expect(picker.pickCalls, 1);
    expect(find.text('Backup-Passwort'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Android backup saving returns from progress and offers sharing',
    (tester) async {
      final exporter = _FakeBackupFileExporter([
        const BackupSaveResult.saved('gesichertes-backup.zslbackup'),
      ]);
      final service = _ControlledBackupService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            encryptedBackupServiceProvider.overrideWithValue(service),
            backupFileExporterProvider.overrideWithValue(exporter),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.tap(find.text('Verschlüsseltes Backup erstellen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '123456');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey('backup-progress-overlay')),
        findsOneWidget,
      );
      expect(find.text('Backup wird verschlüsselt'), findsOneWidget);
      expect(find.text('1 von 2 Dateien'), findsOneWidget);
      expect(find.text('50 %'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('backup-linear-progress')),
        findsOneWidget,
      );

      service.complete();
      await tester.pumpAndSettle();

      expect(exporter.saved, hasLength(1));
      expect(
        find.byKey(const ValueKey('backup-progress-overlay')),
        findsNothing,
      );
      expect(find.text('Backup gespeichert'), findsOneWidget);
      expect(
        find.textContaining('gesichertes-backup.zslbackup'),
        findsOneWidget,
      );
      final doneButton = find.widgetWithText(FilledButton, 'Fertig');
      final shareButton = find.widgetWithText(OutlinedButton, 'Teilen');
      expect(doneButton, findsOneWidget);
      expect(shareButton, findsOneWidget);
      expect(
        tester.getSize(doneButton).width,
        tester.getSize(shareButton).width,
      );
      expect(
        tester.getTopLeft(doneButton).dy,
        lessThan(tester.getTopLeft(shareButton).dy),
      );

      await tester.tap(find.text('Teilen'));
      await tester.pumpAndSettle();

      expect(exporter.shared, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelled save can choose a destination again', (tester) async {
    final exporter = _FakeBackupFileExporter([
      const BackupSaveResult.cancelled(),
      const BackupSaveResult.saved('zweiter-versuch.zslbackup'),
    ]);
    final service = _ControlledBackupService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          encryptedBackupServiceProvider.overrideWithValue(service),
          backupFileExporterProvider.overrideWithValue(exporter),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await _startBackup(tester, service);

    expect(find.text('Backup noch nicht gespeichert'), findsOneWidget);
    expect(find.text('Speicherort wählen'), findsOneWidget);
    final discardButton = find.widgetWithText(FilledButton, 'Backup verwerfen');
    final chooseLocationButton = find.widgetWithText(
      OutlinedButton,
      'Speicherort wählen',
    );
    expect(discardButton, findsOneWidget);
    expect(chooseLocationButton, findsOneWidget);
    expect(
      tester.getSize(discardButton).width,
      tester.getSize(chooseLocationButton).width,
    );
    expect(
      tester.getTopLeft(discardButton).dy,
      lessThan(tester.getTopLeft(chooseLocationButton).dy),
    );

    await tester.tap(find.text('Speicherort wählen'));
    await tester.pumpAndSettle();

    expect(exporter.saved, hasLength(2));
    expect(find.text('Backup gespeichert'), findsOneWidget);
    expect(find.textContaining('zweiter-versuch.zslbackup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save can be retried without recreating the backup', (
    tester,
  ) async {
    final exporter = _FakeBackupFileExporter([
      StateError('Speichern fehlgeschlagen'),
      const BackupSaveResult.saved('nach-fehler.zslbackup'),
    ]);
    final service = _ControlledBackupService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          encryptedBackupServiceProvider.overrideWithValue(service),
          backupFileExporterProvider.overrideWithValue(exporter),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await _startBackup(tester, service);

    expect(find.text('Backup konnte nicht gespeichert werden'), findsOneWidget);
    await tester.tap(find.text('Speicherort wählen'));
    await tester.pumpAndSettle();

    expect(exporter.saved, hasLength(2));
    expect(find.text('Backup gespeichert'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discard removes a backup that was not saved', (tester) async {
    final exporter = _FakeBackupFileExporter([
      const BackupSaveResult.cancelled(),
    ]);
    final service = _ControlledBackupService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          encryptedBackupServiceProvider.overrideWithValue(service),
          backupFileExporterProvider.overrideWithValue(exporter),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await _startBackup(tester, service);
    await tester.tap(find.text('Backup verwerfen'));
    await tester.pumpAndSettle();

    expect(exporter.discarded, hasLength(1));
    expect(find.text('Backup noch nicht gespeichert'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _startBackup(
  WidgetTester tester,
  _ControlledBackupService service,
) async {
  await tester.tap(find.text('Verschlüsseltes Backup erstellen'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), '123456');
  await tester.enterText(find.byType(TextField).at(1), '123456');
  await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
  await tester.pump();
  service.complete();
  await tester.pumpAndSettle();
}

class _FakeBackupFileExporter implements BackupFileExporter {
  _FakeBackupFileExporter(this._saveOutcomes);

  final List<Object> _saveOutcomes;
  final List<CreatedBackup> saved = [];
  final List<CreatedBackup> shared = [];
  final List<CreatedBackup> discarded = [];

  @override
  bool get supportsDirectSave => true;

  @override
  Future<BackupSaveResult> save(CreatedBackup backup) async {
    saved.add(backup);
    final outcome = _saveOutcomes.removeAt(0);
    if (outcome is BackupSaveResult) return outcome;
    throw outcome;
  }

  @override
  Future<void> share(CreatedBackup backup) async => shared.add(backup);

  @override
  Future<void> discard(CreatedBackup backup) async => discarded.add(backup);
}

class _FakeBackupFilePicker implements BackupFilePicker {
  _FakeBackupFilePicker(this._outcomes);

  final List<Object?> _outcomes;
  int pickCalls = 0;

  @override
  Future<String?> pick() async {
    pickCalls++;
    final outcome = _outcomes.removeAt(0);
    if (outcome is Exception) throw outcome;
    return outcome as String?;
  }
}

class _ControlledBackupService extends EncryptedBackupService {
  _ControlledBackupService()
    : super(
        meters: MemoryMeterRepository(),
        readings: MemoryReadingRepository(),
        exports: MemoryEvidenceExportRepository(),
        reminders: LocalNotificationReminderRepository.instance,
      );

  final _completer = Completer<CreatedBackup>();

  @override
  Future<CreatedBackup> create(
    String password, {
    void Function(BackupProgress progress)? onProgress,
  }) {
    onProgress?.call(
      const BackupProgress(
        phase: BackupProgressPhase.encrypting,
        processedBytes: 50,
        totalBytes: 100,
        completedItems: 1,
        totalItems: 2,
      ),
    );
    return _completer.future;
  }

  void complete() {
    _completer.complete(
      CreatedBackup(
        path: '/tmp/test.zslbackup',
        sizeBytes: 8 * 1024 * 1024,
        preview: BackupPreview(
          createdAt: DateTime.utc(2026, 9, 7),
          meterCount: 2,
          readingCount: 4,
          exportCount: 2,
        ),
      ),
    );
  }
}
