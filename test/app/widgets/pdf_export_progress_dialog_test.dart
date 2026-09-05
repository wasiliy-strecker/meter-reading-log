import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/widgets/pdf_export_progress_dialog.dart';

void main() {
  testWidgets('PDF progress dialog blocks back and closes after completion', (
    tester,
  ) async {
    final operation = Completer<String>();
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await runWithPdfExportProgress(
                  context,
                  description: 'Nachweisdaten werden zusammengestellt.',
                  operation: () => operation.future,
                );
              },
              child: const Text('PDF erstellen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('PDF erstellen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PDF-Nachweis wird erstellt'), findsOneWidget);
    expect(find.byKey(const ValueKey('pdf-export-progress')), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(find.text('PDF-Nachweis wird erstellt'), findsOneWidget);

    operation.complete('fertig');
    await tester.pumpAndSettle();

    expect(find.text('PDF-Nachweis wird erstellt'), findsNothing);
    expect(result, 'fertig');
  });
}
