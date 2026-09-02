import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/widgets/confirm_dialog.dart';

void main() {
  testWidgets('destructive confirmation uses stacked full-width actions', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await confirmDestructiveAction(
                  context,
                  title: 'Eintrag löschen?',
                  message: 'Dieser Eintrag wird dauerhaft gelöscht.',
                );
              },
              child: const Text('Dialog öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();

    final confirmButton = find.widgetWithText(FilledButton, 'Löschen');
    final cancelButton = find.widgetWithText(OutlinedButton, 'Abbrechen');
    expect(confirmButton, findsOneWidget);
    expect(cancelButton, findsOneWidget);
    expect(
      tester.getSize(confirmButton).width,
      tester.getSize(cancelButton).width,
    );
    expect(
      tester.getTopLeft(confirmButton).dy,
      lessThan(tester.getTopLeft(cancelButton).dy),
    );

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
