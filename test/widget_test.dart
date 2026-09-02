import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_log/app/app.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/files/meter_photo_repository.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('empty app opens meter creation flow', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Ersten Zähler anlegen'), findsOneWidget);
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();

    expect(find.text('Zählerart'), findsOneWidget);
    expect(find.text('Bezeichnung *'), findsOneWidget);
    expect(find.text('Einheit *'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Ableseerinnerung'), findsOneWidget);
  });

  testWidgets('meter form offers expanded types and matching units', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<MeterType>));
    await tester.pumpAndSettle();

    expect(find.text('Strom (Einspeisung / PV)'), findsOneWidget);
    expect(find.text('Warmwasser'), findsOneWidget);
    expect(find.text('Wärme / Fernwärme'), findsOneWidget);
    expect(find.text('Heizkostenverteiler'), findsOneWidget);
    expect(find.text('Heizöl / Tank'), findsOneWidget);
    expect(find.text('Sonstiger Zähler'), findsOneWidget);

    await tester.tap(find.text('Warmwasser'));
    await tester.pumpAndSettle();
    expect(find.text('m³'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Liter'), findsOneWidget);
  });

  testWidgets('new meter confirms that reading follows next', (tester) async {
    final meters = MemoryMeterRepository();
    await tester.pumpWidget(_testApp(meters: meters));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bezeichnung *'),
      'Strom Hauptzähler',
    );
    await tester.ensureVisible(find.text('Zähler speichern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler speichern'));
    const confirmation =
        'Zähler gespeichert. Das Ablesen des Zählerstands folgt im nächsten Schritt.';
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(confirmation).evaluate().isNotEmpty) break;
    }

    expect(meters.items.values.single.label, 'Strom Hauptzähler');
    expect(find.text(confirmation), findsWidgets);
    expect(find.text('Ablesen'), findsOneWidget);
  });
}

Widget _testApp({MemoryMeterRepository? meters}) {
  return ProviderScope(
    overrides: [
      meterRepositoryProvider.overrideWithValue(
        meters ?? MemoryMeterRepository(),
      ),
      meterReadingRepositoryProvider.overrideWithValue(
        MemoryReadingRepository(),
      ),
      evidenceExportRepositoryProvider.overrideWithValue(
        MemoryEvidenceExportRepository(),
      ),
      meterPhotoCaptureRepositoryProvider.overrideWithValue(
        const UnsupportedMeterPhotoCaptureRepository(),
      ),
      meterReminderRepositoryProvider.overrideWithValue(
        NoopMeterReminderRepository(),
      ),
    ],
    child: const MeterReadingLogApp(),
  );
}
