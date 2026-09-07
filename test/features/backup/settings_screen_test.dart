import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/reminders/local_notification_reminder_repository.dart';
import 'package:meter_reading_log/features/backup/application/encrypted_backup_service.dart';
import 'package:meter_reading_log/features/backup/presentation/settings_screen.dart';

import '../../support/fakes.dart';

void main() {
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

  testWidgets('Android backup sharing returns from the progress state', (
    tester,
  ) async {
    const channel = MethodChannel(
      'com.appfactory.meter_reading_log/backup_share',
    );
    MethodCall? sharedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          sharedCall = call;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          encryptedBackupServiceProvider.overrideWithValue(
            _ImmediateBackupService(),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Verschlüsseltes Backup erstellen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '123456');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pumpAndSettle();

    expect(sharedCall?.method, 'shareBackup');
    expect(
      (sharedCall?.arguments as Map<Object?, Object?>)['path'],
      '/tmp/test.zslbackup',
    );
    expect(find.text('Backup wird verschlüsselt …'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _ImmediateBackupService extends EncryptedBackupService {
  _ImmediateBackupService()
    : super(
        meters: MemoryMeterRepository(),
        readings: MemoryReadingRepository(),
        exports: MemoryEvidenceExportRepository(),
        reminders: LocalNotificationReminderRepository.instance,
      );

  @override
  Future<CreatedBackup> create(String password) async {
    return CreatedBackup(
      path: '/tmp/test.zslbackup',
      preview: BackupPreview(
        createdAt: DateTime.utc(2026, 9, 7),
        meterCount: 2,
        readingCount: 4,
        exportCount: 2,
      ),
    );
  }
}
