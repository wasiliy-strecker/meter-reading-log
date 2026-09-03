import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/widgets/app_snack_bar.dart';

void main() {
  testWidgets('centers snackbar messages across the available width', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Builder(builder: _showSnackBar)),
      ),
    );

    await tester.tap(find.text('Hinweis anzeigen'));
    await tester.pump();

    final text = tester.widget<Text>(find.text('Gespeichert'));
    expect(text.textAlign, TextAlign.center);
    final messageBox = find
        .ancestor(of: find.text('Gespeichert'), matching: find.byType(SizedBox))
        .first;
    expect(tester.getSize(messageBox).width, greaterThan(200));
  });
}

Widget _showSnackBar(BuildContext context) {
  return Center(
    child: FilledButton(
      onPressed: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar(message: 'Gespeichert')),
      child: const Text('Hinweis anzeigen'),
    ),
  );
}
