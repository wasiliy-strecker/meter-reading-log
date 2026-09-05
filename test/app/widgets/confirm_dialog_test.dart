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

  testWidgets(
    'discard confirmation keeps editing unless explicitly discarded',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  result = await confirmDiscardChanges(
                    context,
                    title: 'Änderungen verwerfen?',
                    message: 'Die Änderungen wurden noch nicht gespeichert.',
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

      final discard = find.widgetWithText(FilledButton, 'Änderungen verwerfen');
      final keepEditing = find.widgetWithText(
        OutlinedButton,
        'Weiter bearbeiten',
      );
      expect(discard, findsOneWidget);
      expect(keepEditing, findsOneWidget);
      expect(tester.getSize(discard).width, tester.getSize(keepEditing).width);

      await tester.tap(find.text('Weiter bearbeiten'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    },
  );
}
