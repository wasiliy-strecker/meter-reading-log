import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/features/backup/presentation/settings_screen.dart';

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

    await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
    await tester.pumpAndSettle();

    expect(find.text('Backup-Passwort festlegen'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
