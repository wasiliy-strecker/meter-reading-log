import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/app/app_theme.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/presentation/meter_form_screen.dart';

import '../../support/fakes.dart';

const _hint =
    'Nach dem Speichern kannst du unter „Ablesen / Fotografieren“ '
    'deinen ersten Zählerstand erfassen und protokollieren.';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'create hint fits above save in $brightness at scale $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 700));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(_app(brightness: brightness, scale: scale));
          await tester.pumpAndSettle();

          final hint = find.byKey(const ValueKey('first-reading-hint'));
          final save = find.widgetWithText(FilledButton, 'Zähler speichern');
          expect(hint, findsOneWidget);
          expect(find.text(_hint), findsOneWidget);
          expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
          expect(
            tester
                .getBottomRight(
                  find.byKey(const ValueKey('first-reading-hint-viewport')),
                )
                .dy,
            lessThan(tester.getTopLeft(save).dy),
          );
          expect(tester.widget<FilledButton>(save).onPressed, isNull);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('editing a meter has no first-reading hint', (tester) async {
    await tester.pumpWidget(_app(editing: true));
    await tester.pumpAndSettle();
    expect(find.text('Zähler bearbeiten'), findsOneWidget);
    expect(find.byKey(const ValueKey('first-reading-hint')), findsNothing);
    expect(find.text(_hint), findsNothing);
    expect(find.text('Alles gespeichert'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  bool editing = false,
  Brightness brightness = Brightness.light,
  double scale = 1,
}) {
  final meter = Meter(
    id: 'meter',
    label: 'Testzaehler',
    type: MeterType.electricity,
    unit: 'kWh',
    meterNumber: '',
    location: '',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
  return ProviderScope(
    overrides: [
      meterRepositoryProvider.overrideWithValue(
        MemoryMeterRepository()..items[meter.id] = meter,
      ),
      meterReminderRepositoryProvider.overrideWithValue(
        NoopMeterReminderRepository(),
      ),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.light
          ? AppTheme.light()
          : AppTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: MeterFormScreen(meterId: editing ? meter.id : null),
    ),
  );
}
