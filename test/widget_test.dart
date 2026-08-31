import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_log/app/app.dart';
import 'package:meter_reading_log/app/app_providers.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('empty app opens meter creation flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterRepositoryProvider.overrideWithValue(MemoryMeterRepository()),
        ],
        child: const MeterReadingLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ersten Zähler anlegen'), findsOneWidget);
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();

    expect(find.text('Zählerart'), findsOneWidget);
    expect(find.text('Bezeichnung *'), findsOneWidget);
    expect(find.text('Ableseerinnerung'), findsOneWidget);
  });
}
