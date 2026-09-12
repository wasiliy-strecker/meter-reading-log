import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/app/app_router.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import '../../support/fakes.dart';

void main() {
  for (final count in [0, 1, 5, 6, 20, 21]) {
    testWidgets(
      '$count readings: five-item preview and always searchable full history',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixture = _fixture(count);
        addTearDown(fixture.container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: fixture.container,
            child: const MeterReadingLogApp(),
          ),
        );
        await tester.pumpAndSettle();
        final router = fixture.container.read(appRouterProvider);
        router.goNamed('meterDetail', pathParameters: {'id': 'meter'});
        await tester.pumpAndSettle();
        expect(fixture.readings.lastPageLimit, 5);
        final cards = find.byWidgetPredicate(
          (w) =>
              w is Card &&
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('reading-card-'),
        );
        expect(cards, findsNWidgets(count < 5 ? count : 5));
        expect(
          find.byKey(const ValueKey('history-search-field')),
          findsNothing,
        );
        if (count == 0) {
          expect(
            find.byKey(const ValueKey('empty-readings-action')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('open-meter-history')),
            findsNothing,
          );
          router.pushNamed('meterHistory', pathParameters: {'id': 'meter'});
        } else {
          await tester.tap(find.byKey(const ValueKey('open-meter-history')));
        }
        await tester.pumpAndSettle();
        expect(fixture.readings.lastPageLimit, 20);
        expect(
          find.byKey(const ValueKey('history-search-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('history-next-page')),
          count > 20 ? findsOneWidget : findsNothing,
        );
        if (count == 0) {
          expect(find.text('Noch keine Ablesungen vorhanden.'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'returning from a reading preserves search and page, deleted final page clamps',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _fixture(41);
      addTearDown(fixture.container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: fixture.container,
          child: const MeterReadingLogApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = fixture.container.read(appRouterProvider);
      router.goNamed('meterHistory', pathParameters: {'id': 'meter'});
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('history-search-field'));
      await tester.enterText(search, 'Kontrolle');
      await tester.pump(const Duration(milliseconds: 251));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('history-next-page')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reading-card-reading_20')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-search-field')), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, 'Kontrolle');
      expect(fixture.readings.lastPageOffset, 20);
      expect(find.text('Seite 2 von 3'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('history-next-page')));
      await tester.pumpAndSettle();
      expect(fixture.readings.lastPageOffset, 40);
      fixture.readings.items.remove('reading_0');
      fixture.container.invalidate(meterHistoryPageProvider);
      await tester.pumpAndSettle();
      expect(fixture.readings.lastPageOffset, 20);
      expect(find.text('Seite 2 von 2'), findsOneWidget);
      await tester.enterText(search, 'Kein Treffer');
      await tester.pump(const Duration(milliseconds: 251));
      await tester.pumpAndSettle();
      expect(fixture.readings.lastPageOffset, 0);
      expect(find.text('Keine passende Ablesung gefunden.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

({ProviderContainer container, MemoryReadingRepository readings}) _fixture(
  int count,
) {
  final meter = Meter(
    id: 'meter',
    label: 'Strom Verlauf',
    type: MeterType.electricity,
    unit: 'kWh',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final meters = MemoryMeterRepository()..items[meter.id] = meter;
  final readings = MemoryReadingRepository();
  for (var index = 0; index < count; index++) {
    final time = DateTime.utc(2026).add(Duration(days: index));
    final reading = MeterReading(
      id: 'reading_$index',
      meterId: meter.id,
      meter: MeterSnapshot.fromMeter(meter),
      value: ReadingValue.tryParse('$index,0')!,
      capturedAt: time,
      storedAt: time,
      updatedAt: time,
      timezoneOffsetMinutes: 0,
      source: ReadingSource.camera,
      photoPath: '/tmp/synthetic-missing-photo.jpg',
      photoSha256: 'a' * 64,
      ocrRawText: '',
      ocrCandidate: '',
      manifestSha256: 'b' * 64,
      note: 'Kontrolle',
    );
    readings.items[reading.id] = reading;
  }
  return (
    readings: readings,
    container: ProviderContainer(
      overrides: [
        meterRepositoryProvider.overrideWithValue(meters),
        meterReadingRepositoryProvider.overrideWithValue(readings),
        meterReminderRepositoryProvider.overrideWithValue(
          NoopMeterReminderRepository(),
        ),
        evidenceExportRepositoryProvider.overrideWithValue(
          MemoryEvidenceExportRepository(),
        ),
      ],
    ),
  );
}
