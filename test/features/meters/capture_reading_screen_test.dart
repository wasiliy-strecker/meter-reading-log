import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/files/meter_photo_repository.dart';
import 'package:meter_reading_log/core/ocr/meter_ocr_repository.dart';
import 'package:meter_reading_log/features/evidence/application/evidence_report_service.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';
import 'package:meter_reading_log/features/meters/presentation/meter_photo_examples.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('capture flow clearly exposes photo, unit, time and keyboard UX', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final meter = Meter(
      id: 'meter_heat',
      label: 'Wärme Keller',
      type: MeterType.heat,
      unit: 'GJ',
      createdAt: DateTime.utc(2026, 9, 2),
      updatedAt: DateTime.utc(2026, 9, 2),
    );
    final meters = MemoryMeterRepository()..items[meter.id] = meter;
    final readings = MemoryReadingRepository();
    final photos = _FixedPhotoRepository();
    final reminders = NoopMeterReminderRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterPhotoExamplesEnabledProvider.overrideWithValue(true),
          meterRepositoryProvider.overrideWithValue(meters),
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(
            MemoryEvidenceExportRepository(),
          ),
          meterPhotoCaptureRepositoryProvider.overrideWithValue(photos),
          meterOcrRepositoryProvider.overrideWithValue(
            const _FixedOcrRepository(),
          ),
          meterReminderRepositoryProvider.overrideWithValue(reminders),
        ],
        child: const MeterReadingLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wärme Keller'));
    await tester.pumpAndSettle();
    final emptyHistoryAction = find.byKey(
      const ValueKey('empty-readings-action'),
    );
    expect(emptyHistoryAction, findsOneWidget);
    expect(find.text('Erste Ablesung erfassen'), findsOneWidget);
    await tester.tap(emptyHistoryAction);
    await tester.pumpAndSettle();
    expect(find.text('Ablesen / Fotografieren'), findsWidgets);

    final examplesButton = find.widgetWithText(TextButton, 'Beispiele ansehen');
    final cameraButton = find.widgetWithText(
      FilledButton,
      'Zähler fotografieren',
    );
    final guidanceCard = find.ancestor(
      of: find.text('Für eine gute Erkennung'),
      matching: find.byType(Card),
    );
    final guidanceSurface = find.descendant(
      of: guidanceCard,
      matching: find.byType(Material),
    );
    final examplesBounds = tester.getRect(examplesButton);
    final gapAbove =
        examplesBounds.top - tester.getRect(guidanceSurface).bottom;
    final gapBelow = tester.getRect(cameraButton).top - examplesBounds.bottom;
    expect(
      examplesBounds.center.dx,
      closeTo(tester.getCenter(cameraButton).dx, 0.01),
    );
    expect(gapAbove, closeTo(18, 0.01));
    expect(gapBelow, closeTo(gapAbove, 0.01));

    expect(find.text('Beispielfotos'), findsNothing);
    await tester.tap(find.text('Beispiele ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Beispielfotos'), findsOneWidget);
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(photos.captureCount, 0);
    expect(readings.items, isEmpty);

    await tester.tap(find.text('Zähler fotografieren'));
    await tester.pumpAndSettle();

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Ablesung verwerfen?'), findsOneWidget);
    expect(find.text('Ablesung verwerfen'), findsOneWidget);
    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Ablesen / Fotografieren'), findsWidgets);
    expect(find.text('Neues Foto aufnehmen oder auswählen'), findsOneWidget);

    await tester.tap(find.text('Neues Foto aufnehmen oder auswählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beispiele ansehen'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Neu fotografieren'), findsOneWidget);
    expect(find.text('Aus Galerie wählen'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(photos.captureCount, 1);

    expect(find.text('Ersetzen'), findsNothing);
    expect(find.text('Neues Foto aufnehmen oder auswählen'), findsOneWidget);
    expect(find.text('Einheit des Zählerstands'), findsOneWidget);
    expect(find.text('GJ'), findsWidgets);
    expect(find.text('Gigajoule – Einheit für Wärmeenergie'), findsOneWidget);
    expect(find.text('Datum & Uhrzeit ändern'), findsOneWidget);
    expect(
      tester.widget<ListView>(find.byType(ListView)).keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Weitere Einheit …'), findsOneWidget);
    await tester.tap(find.text('kWh').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Kilowattstunde – Energieverbrauch oder Erzeugung'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Ablesung bestätigen und speichern'));
    final confirmButton = find.widgetWithText(
      FilledButton,
      'Ablesung bestätigen und speichern',
    );
    expect(
      Theme.of(
        tester.element(confirmButton),
      ).filledButtonTheme.style?.shape?.resolve(const <WidgetState>{}),
      isA<StadiumBorder>(),
    );
    await tester.tap(find.text('Ablesung bestätigen und speichern'));
    for (var attempt = 0; attempt < 30 && readings.items.isEmpty; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (
      var attempt = 0;
      attempt < 30 && reminders.acknowledgedMeterIds.isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(meters.items[meter.id]!.unit, 'kWh');
    expect(readings.items.values.single.meter.unit, 'kWh');
    expect(reminders.acknowledgedMeterIds, [meter.id]);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, 'Korrigieren'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Ablesung löschen'),
      findsOneWidget,
    );
    expect(find.byType(PopupMenuButton<String>), findsNothing);

    await tester.tap(find.text('Korrigieren'));
    await tester.pumpAndSettle();
    expect(find.text('Aktuelles Nachweisfoto'), findsOneWidget);
    expect(find.text('Neues Foto für Korrektur'), findsOneWidget);
    expect(
      find.textContaining(
        'Nach dem Speichern findest du diese Änderung unter „Korrekturverlauf“',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Neues Foto für Korrektur'));
    await tester.tap(find.text('Neues Foto für Korrektur'));
    await tester.pumpAndSettle();
    expect(find.text('Neues Nachweisfoto'), findsOneWidget);
    final capturesBeforeExamples = photos.captureCount;
    await tester.tap(find.text('Beispiele ansehen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(find.text('Neues Nachweisfoto'), findsOneWidget);
    expect(photos.captureCount, capturesBeforeExamples);
    await tester.tap(find.text('Aus Galerie wählen'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Das bisherige Foto bleibt als frühere Version'),
      findsOneWidget,
    );
    expect(find.textContaining('Der Ablesezeitpunkt'), findsNothing);
    expect(find.text('Erkannte Werte'), findsOneWidget);
    final changePhotoButton = find.widgetWithText(
      OutlinedButton,
      'Korrekturfoto ändern',
    );
    expect(changePhotoButton, findsOneWidget);
    expect(
      tester.getTopLeft(changePhotoButton).dy,
      lessThan(
        tester
            .getTopLeft(
              find.textContaining(
                'Das bisherige Foto bleibt als frühere Version',
              ),
            )
            .dy,
      ),
    );

    final capturesBeforeChange = photos.captureCount;
    await tester.tap(changePhotoButton);
    await tester.pumpAndSettle();
    expect(find.text('Neues Nachweisfoto'), findsOneWidget);
    await tester.tap(find.text('Neu fotografieren'));
    await tester.pumpAndSettle();
    expect(photos.captureCount, capturesBeforeChange + 1);
    expect(
      find.widgetWithText(OutlinedButton, 'Korrekturfoto ändern'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Grund der Korrektur (optional)'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Grund der Korrektur *'), findsNothing);
    expect(find.text('Bitte den Korrekturgrund angeben.'), findsNothing);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Korrektur verwerfen?'), findsOneWidget);
    expect(find.text('Korrektur verwerfen'), findsOneWidget);
    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Grund der Korrektur (optional)'), findsOneWidget);

    final saveCorrection = find.text('Korrektur protokollieren');
    await tester.ensureVisible(saveCorrection);
    await tester.tap(saveCorrection);
    await tester.pumpAndSettle();

    expect(find.text('Ablesung'), findsOneWidget);
    expect(readings.revisions.values.single, hasLength(1));
    expect(readings.revisions.values.single.single.reason, isEmpty);
    expect(find.textContaining('Grund:'), findsNothing);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Zählerverlauf'), findsOneWidget);
    expect(find.text('Ablesen / Fotografieren'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets(
    'lower new reading needs no reason and does not load full history',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final meter = Meter(
        id: 'meter_lower_capture',
        label: 'Strom niedriger',
        type: MeterType.electricity,
        unit: 'kWh',
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
      );
      final meters = MemoryMeterRepository()..items[meter.id] = meter;
      final readings = _CountingHistoryReadingRepository();
      readings.items['previous_high'] = MeterReading(
        id: 'previous_high',
        meterId: meter.id,
        meter: MeterSnapshot.fromMeter(meter),
        value: ReadingValue.tryParse('900,0')!,
        capturedAt: DateTime.utc(2026, 9, 8, 10),
        timezoneOffsetMinutes: 120,
        storedAt: DateTime.utc(2026, 9, 8, 10),
        updatedAt: DateTime.utc(2026, 9, 8, 10),
        source: ReadingSource.camera,
        photoPath: '/tmp/previous-high.jpg',
        photoSha256: 'a' * 64,
        ocrRawText: '900,0',
        ocrCandidate: '900,0',
        manifestSha256: 'b' * 64,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            meterRepositoryProvider.overrideWithValue(meters),
            meterReadingRepositoryProvider.overrideWithValue(readings),
            evidenceExportRepositoryProvider.overrideWithValue(
              MemoryEvidenceExportRepository(),
            ),
            meterPhotoCaptureRepositoryProvider.overrideWithValue(
              _FixedPhotoRepository(),
            ),
            meterOcrRepositoryProvider.overrideWithValue(
              const _FixedOcrRepository(),
            ),
            meterReminderRepositoryProvider.overrideWithValue(
              NoopMeterReminderRepository(),
            ),
          ],
          child: const MeterReadingLogApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Strom niedriger'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ablesen / Fotografieren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zähler fotografieren'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Grund für niedrigeren'), findsNothing);
      expect(find.textContaining('niedrigeren Stand'), findsNothing);
      expect(find.textContaining('Vorheriger Stand'), findsNothing);
      expect(readings.watchForMeterCalls, 0);

      final save = find.text('Ablesung bestätigen und speichern');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final created = readings.items.values.singleWhere(
        (reading) => reading.id != 'previous_high',
      );
      expect(created.value.displayText, '123,4');
      expect(created.lowerReadingReason, isNull);
      expect(readings.watchForMeterCalls, 0);
    },
  );

  testWidgets(
    'lower correction needs no reason and preserves a historical reason',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final meter = Meter(
        id: 'meter_lower_edit',
        label: 'Gas niedriger',
        type: MeterType.gas,
        unit: 'm³',
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
      );
      final meters = MemoryMeterRepository()..items[meter.id] = meter;
      final readings = _CountingHistoryReadingRepository();
      readings.items['earlier_high'] = MeterReading(
        id: 'earlier_high',
        meterId: meter.id,
        meter: MeterSnapshot.fromMeter(meter),
        value: ReadingValue.tryParse('900,0')!,
        capturedAt: DateTime.utc(2026, 9, 1, 10),
        timezoneOffsetMinutes: 120,
        storedAt: DateTime.utc(2026, 9, 1, 10),
        updatedAt: DateTime.utc(2026, 9, 1, 10),
        source: ReadingSource.camera,
        photoPath: '/tmp/earlier-high.jpg',
        photoSha256: 'a' * 64,
        ocrRawText: '900,0',
        ocrCandidate: '900,0',
        manifestSha256: 'b' * 64,
      );
      readings.items['legacy_lower'] = MeterReading(
        id: 'legacy_lower',
        meterId: meter.id,
        meter: MeterSnapshot.fromMeter(meter),
        value: ReadingValue.tryParse('500,0')!,
        capturedAt: DateTime.utc(2026, 9, 2, 10),
        timezoneOffsetMinutes: 120,
        storedAt: DateTime.utc(2026, 9, 2, 10),
        updatedAt: DateTime.utc(2026, 9, 2, 10),
        source: ReadingSource.camera,
        photoPath: '/tmp/legacy-lower.jpg',
        photoSha256: 'c' * 64,
        ocrRawText: '500,0',
        ocrCandidate: '500,0',
        lowerReadingReason: LowerReadingReason.meterReplacement,
        manifestSha256: 'd' * 64,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            meterRepositoryProvider.overrideWithValue(meters),
            meterReadingRepositoryProvider.overrideWithValue(readings),
            evidenceExportRepositoryProvider.overrideWithValue(
              MemoryEvidenceExportRepository(),
            ),
            meterPhotoCaptureRepositoryProvider.overrideWithValue(
              _FixedPhotoRepository(),
            ),
            meterOcrRepositoryProvider.overrideWithValue(
              const _FixedOcrRepository(),
            ),
            meterReminderRepositoryProvider.overrideWithValue(
              NoopMeterReminderRepository(),
            ),
          ],
          child: const MeterReadingLogApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gas niedriger'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reading-card-legacy_lower')));
      await tester.pumpAndSettle();
      expect(find.text('Niedrigerer Stand'), findsOneWidget);
      expect(find.text('Zählerwechsel'), findsOneWidget);

      await tester.tap(find.text('Korrigieren'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '400,0');
      expect(find.textContaining('Grund für niedrigeren'), findsNothing);
      expect(find.textContaining('niedrigeren Stand'), findsNothing);
      expect(readings.watchForMeterCalls, 0);

      final save = find.text('Korrektur protokollieren');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(
        readings.items['legacy_lower']?.lowerReadingReason,
        LowerReadingReason.meterReplacement,
      );
      expect(readings.items['legacy_lower']?.value.displayText, '400,0');
      expect(find.text('Niedrigerer Stand'), findsOneWidget);
      expect(find.text('Zählerwechsel'), findsOneWidget);
      expect(readings.watchForMeterCalls, 0);
    },
  );

  testWidgets(
    'meter history loads 20 at a time and searches beyond the first page',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final meter = Meter(
        id: 'meter_long_history',
        label: 'Strom Langzeit',
        type: MeterType.electricity,
        unit: 'kWh',
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 1),
      );
      final meters = MemoryMeterRepository()..items[meter.id] = meter;
      final readings = MemoryReadingRepository();
      final base = DateTime.utc(2026, 7, 1, 12);
      for (var index = 0; index < 45; index++) {
        final capturedAt = base.add(Duration(days: index));
        readings.items['long_reading_$index'] = MeterReading(
          id: 'long_reading_$index',
          meterId: meter.id,
          meter: MeterSnapshot.fromMeter(meter),
          value: ReadingValue.tryParse('${1000 + index},0')!,
          capturedAt: capturedAt,
          timezoneOffsetMinutes: 120,
          storedAt: capturedAt,
          updatedAt: capturedAt,
          source: ReadingSource.camera,
          photoPath: '/tmp/long_reading_$index.jpg',
          photoSha256: 'a' * 64,
          ocrRawText: '${1000 + index},0',
          ocrCandidate: '${1000 + index},0',
          note: index == 3 ? 'Spezialfund im Heizraum' : '',
          manifestSha256: 'b' * 64,
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            meterRepositoryProvider.overrideWithValue(meters),
            meterReadingRepositoryProvider.overrideWithValue(readings),
            evidenceExportRepositoryProvider.overrideWithValue(
              MemoryEvidenceExportRepository(),
            ),
          ],
          child: const MeterReadingLogApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Strom Langzeit'));
      await tester.pumpAndSettle();

      expect(readings.lastPageLimit, 20);
      expect(readings.lastPageQuery, isEmpty);
      final historyPdfAction = find.text('PDF-Nachweis des Zählerverlaufs');
      final historyTitle = find.text('Zählerverlauf');
      expect(historyPdfAction, findsOneWidget);
      expect(
        tester.getTopLeft(historyPdfAction).dy,
        lessThan(tester.getTopLeft(historyTitle).dy),
      );
      expect(find.text('Gespeicherte PDF-Nachweise'), findsNothing);
      expect(find.text('20 von 45 Ablesungen'), findsOneWidget);
      final search = find.byKey(const ValueKey('history-search-field'));
      expect(search, findsOneWidget);

      await tester.enterText(search, 'SPEZIALFUND');
      await tester.pump(const Duration(milliseconds: 249));
      expect(readings.lastPageQuery, isEmpty);
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pumpAndSettle();

      expect(readings.lastPageLimit, 20);
      expect(readings.lastPageQuery, 'SPEZIALFUND');
      expect(find.text('1 Treffer'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('reading-card-long_reading_3')),
        findsOneWidget,
      );
      expect(find.text('Spezialfund im Heizraum'), findsOneWidget);
      expect(find.textContaining('Δ '), findsNothing);

      await tester.tap(find.byTooltip('Suche löschen'));
      await tester.pumpAndSettle();
      final showMore = find.byKey(const ValueKey('show-more-readings'));
      for (
        var attempt = 0;
        attempt < 20 && showMore.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -700));
        await tester.pump();
      }
      expect(showMore, findsOneWidget);
      await tester.tap(showMore);
      await tester.pumpAndSettle();

      expect(readings.lastPageLimit, 40);
      expect(readings.lastPageQuery, isEmpty);
    },
  );

  testWidgets('saved history PDFs keep both creation variants available', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final temp = Directory.systemTemp.createTempSync(
      'current_history_screen_test_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    final compactPdf = File('${temp.path}/compact.pdf');
    final photoPdf = File('${temp.path}/photos.pdf');
    compactPdf.writeAsBytesSync(const [0x25, 0x50, 0x44, 0x46]);
    photoPdf.writeAsBytesSync(const [0x25, 0x50, 0x44, 0x46]);
    final meter = Meter(
      id: 'meter_current_history',
      label: 'Gas Keller',
      type: MeterType.gas,
      unit: 'm³',
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
    );
    final meters = MemoryMeterRepository()..items[meter.id] = meter;
    final readings = MemoryReadingRepository();
    final reading = MeterReading(
      id: 'reading_current_history',
      meterId: meter.id,
      meter: MeterSnapshot.fromMeter(meter),
      value: ReadingValue.tryParse('84,2')!,
      capturedAt: DateTime.utc(2026, 9, 2, 10),
      timezoneOffsetMinutes: 120,
      storedAt: DateTime.utc(2026, 9, 2, 10),
      updatedAt: DateTime.utc(2026, 9, 2, 10),
      source: ReadingSource.camera,
      photoPath: '/tmp/current-history-photo.jpg',
      photoSha256: 'a' * 64,
      ocrRawText: '84,2',
      ocrCandidate: '84,2',
      manifestSha256: 'b' * 64,
    );
    readings.items[reading.id] = reading;
    final exports = MemoryEvidenceExportRepository();
    exports.items['history_compact'] = EvidenceExportRecord(
      id: 'history_compact',
      meterId: meter.id,
      kind: EvidenceExportKind.meterHistory,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 9, 5, 10),
      fileName: 'compact.pdf',
      filePath: compactPdf.path,
      pdfSha256: 'c' * 64,
      manifestSha256: 'compact-history-manifest',
      photoMode: EvidencePhotoMode.withoutPhotos,
    );
    exports.items['history_photos'] = EvidenceExportRecord(
      id: 'history_photos',
      meterId: meter.id,
      kind: EvidenceExportKind.meterHistory,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 9, 5, 10, 1),
      fileName: 'photos.pdf',
      filePath: photoPdf.path,
      pdfSha256: 'd' * 64,
      manifestSha256: 'photo-history-manifest',
      photoMode: EvidencePhotoMode.currentPhotos,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterRepositoryProvider.overrideWithValue(meters),
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(exports),
          evidenceReportServiceProvider.overrideWithValue(
            _SynchronousDeleteEvidenceReportService(exports),
          ),
        ],
        child: const MeterReadingLogApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gas Keller'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Zählerverlauf als PDF erstellen'),
      250,
      scrollable: find.byType(Scrollable).last,
    );

    final compactCard = find.byKey(
      const ValueKey('evidence-export-history_compact'),
    );
    final photoCard = find.byKey(
      const ValueKey('evidence-export-history_photos'),
    );
    expect(find.text('Gespeicherte PDF-Nachweise'), findsOneWidget);
    expect(find.text('2 Nachweise'), findsOneWidget);
    expect(compactCard, findsNothing);
    expect(photoCard, findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('saved-history-pdfs-expansion')),
    );
    await tester.pumpAndSettle();
    expect(compactCard, findsOneWidget);
    expect(photoCard, findsOneWidget);
    expect(
      find.descendant(
        of: compactCard,
        matching: find.text('Aktueller Zählerverlaufsnachweis'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: photoCard,
        matching: find.text('Aktueller Zählerverlaufsnachweis'),
      ),
      findsNothing,
    );
    expect(
      find.text('Beide aktuellen Varianten bereits erstellt'),
      findsNothing,
    );
    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Zählerverlauf als PDF erstellen'),
    );
    expect(createButton.onPressed, isNotNull);

    await tester.tap(find.text('Zählerverlauf als PDF erstellen'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('evidence-photo-mode-withoutPhotos')),
          )
          .enabled,
      isTrue,
    );
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('evidence-photo-mode-currentPhotos')),
          )
          .enabled,
      isTrue,
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
  });

  testWidgets('saved history PDFs remain accessible without readings', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final temp = Directory.systemTemp.createTempSync(
      'history_without_readings_test_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    final historyPdf = File('${temp.path}/history.pdf');
    historyPdf.writeAsBytesSync(const [0x25, 0x50, 0x44, 0x46]);
    final meter = Meter(
      id: 'meter_history_without_readings',
      label: 'Alter Gaszähler',
      type: MeterType.gas,
      unit: 'm³',
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
    );
    final meters = MemoryMeterRepository()..items[meter.id] = meter;
    final exports = MemoryEvidenceExportRepository();
    exports.items['orphaned_history_export'] = EvidenceExportRecord(
      id: 'orphaned_history_export',
      meterId: meter.id,
      kind: EvidenceExportKind.meterHistory,
      readingIds: const ['removed_reading'],
      createdAt: DateTime.utc(2026, 9, 5, 8, 30),
      fileName: 'alter_verlauf.pdf',
      filePath: historyPdf.path,
      pdfSha256: 'c' * 64,
      manifestSha256: 'd' * 64,
      photoMode: EvidencePhotoMode.withoutPhotos,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterRepositoryProvider.overrideWithValue(meters),
          meterReadingRepositoryProvider.overrideWithValue(
            MemoryReadingRepository(),
          ),
          evidenceExportRepositoryProvider.overrideWithValue(exports),
        ],
        child: const MeterReadingLogApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alter Gaszähler'));
    await tester.pumpAndSettle();

    expect(find.text('Zählerverlauf als PDF erstellen'), findsNothing);
    expect(find.text('Gespeicherte PDF-Nachweise'), findsOneWidget);
    expect(find.text('1 Nachweis'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('evidence-export-orphaned_history_export')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('saved-history-pdfs-expansion')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('evidence-export-orphaned_history_export')),
      findsOneWidget,
    );
    expect(find.textContaining('Noch keine Ablesung.'), findsOneWidget);
  });

  testWidgets('history PDFs precede readings and show progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final temp = Directory.systemTemp.createTempSync('history_screen_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final historyPdf = File('${temp.path}/history.pdf');
    historyPdf.writeAsBytesSync(const [0x25, 0x50, 0x44, 0x46]);
    final meter = Meter(
      id: 'meter_pdf',
      label: 'Wasser Bad',
      type: MeterType.water,
      unit: 'm³',
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
    );
    final meters = MemoryMeterRepository()..items[meter.id] = meter;
    final readings = _PendingRevisionRepository();
    final exports = MemoryEvidenceExportRepository();
    readings.items['reading_pdf'] = MeterReading(
      id: 'reading_pdf',
      meterId: meter.id,
      meter: MeterSnapshot.fromMeter(meter),
      value: ReadingValue.tryParse('42,1')!,
      capturedAt: DateTime.utc(2026, 9, 2, 10),
      timezoneOffsetMinutes: 120,
      storedAt: DateTime.utc(2026, 9, 2, 10),
      updatedAt: DateTime.utc(2026, 9, 2, 10),
      source: ReadingSource.camera,
      photoPath: '/tmp/photo.jpg',
      photoSha256: 'a' * 64,
      ocrRawText: '42,1',
      ocrCandidate: '42,1',
      manifestSha256: 'b' * 64,
    );
    exports.items['history_export'] = EvidenceExportRecord(
      id: 'history_export',
      meterId: meter.id,
      kind: EvidenceExportKind.meterHistory,
      readingIds: const ['reading_pdf'],
      createdAt: DateTime.utc(2026, 9, 5, 8, 30),
      fileName: 'zaehlerverlauf_wasser_bad_20260905_083000.pdf',
      filePath: historyPdf.path,
      pdfSha256: 'c' * 64,
      manifestSha256: 'd' * 64,
      photoMode: EvidencePhotoMode.withoutPhotos,
    );
    exports.items['single_export'] = EvidenceExportRecord(
      id: 'single_export',
      meterId: meter.id,
      kind: EvidenceExportKind.singleReading,
      readingIds: const ['reading_pdf'],
      createdAt: DateTime.utc(2026, 9, 5, 8),
      fileName: 'zaehlerstand_wasser_bad_20260905_080000.pdf',
      filePath: '/tmp/single.pdf',
      pdfSha256: 'e' * 64,
      manifestSha256: 'f' * 64,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterRepositoryProvider.overrideWithValue(meters),
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(exports),
          evidenceReportServiceProvider.overrideWithValue(
            _SynchronousDeleteEvidenceReportService(exports),
          ),
          meterPhotoCaptureRepositoryProvider.overrideWithValue(
            _FixedPhotoRepository(),
          ),
          meterOcrRepositoryProvider.overrideWithValue(
            const _FixedOcrRepository(),
          ),
          meterReminderRepositoryProvider.overrideWithValue(
            NoopMeterReminderRepository(),
          ),
        ],
        child: const MeterReadingLogApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wasser Bad'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Zählerverlauf als PDF erstellen'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('PDF-Nachweis des Zählerverlaufs'), findsOneWidget);
    expect(
      find.textContaining('kompakt ohne Fotos oder mit dem aktuellen'),
      findsOneWidget,
    );
    final readingCard = find.byKey(const ValueKey('reading-card-reading_pdf'));
    expect(readingCard, findsOneWidget);
    expect(
      find.descendant(of: readingCard, matching: find.text('Zählerstand')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: readingCard, matching: find.text('42,1 m³')),
      findsOneWidget,
    );
    final dateBadge = find.byKey(
      const ValueKey('reading-date-badge-reading_pdf'),
    );
    expect(dateBadge, findsOneWidget);
    expect(
      find.descendant(
        of: dateBadge,
        matching: find.byIcon(Icons.calendar_month_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dateBadge,
        matching: find.textContaining('Abgelesen ·'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(dateBadge).dy,
      lessThan(
        tester
            .getTopLeft(
              find.descendant(
                of: readingCard,
                matching: find.text('Zählerstand'),
              ),
            )
            .dy,
      ),
    );
    expect(
      find.descendant(of: readingCard, matching: find.text('Abgelesen am')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reading-thumbnail-reading_pdf')),
      findsOneWidget,
    );
    final savedEvidenceTitle = find.text('Gespeicherte PDF-Nachweise');
    final historyActionTitle = find.text('PDF-Nachweis des Zählerverlaufs');
    final historySectionTitle = find.text('Zählerverlauf');
    final historyExportCard = find.byKey(
      const ValueKey('evidence-export-history_export'),
    );
    expect(savedEvidenceTitle, findsOneWidget);
    expect(find.text('1 Nachweis'), findsOneWidget);
    expect(historyExportCard, findsNothing);
    expect(
      tester.getTopLeft(historyActionTitle).dy,
      lessThan(tester.getTopLeft(savedEvidenceTitle).dy),
    );
    expect(
      tester.getTopLeft(savedEvidenceTitle).dy,
      lessThan(tester.getTopLeft(historySectionTitle).dy),
    );
    expect(
      tester.getTopLeft(historySectionTitle).dy,
      lessThan(tester.getTopLeft(readingCard).dy),
    );
    await tester.tap(
      find.byKey(const ValueKey('saved-history-pdfs-expansion')),
    );
    await tester.pumpAndSettle();
    expect(historyExportCard, findsOneWidget);
    expect(
      find.byKey(const ValueKey('current-evidence-badge-history_export')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('evidence-export-single_export')),
      findsNothing,
    );
    expect(find.text('Zählerverlaufsnachweis'), findsOneWidget);
    expect(find.textContaining('1 Ablesung enthalten'), findsOneWidget);
    expect(find.text('Einzelnachweis'), findsNothing);
    expect(find.text('Zählerstand: 42,1 m³'), findsNothing);
    expect(find.text('Lokal gespeichert'), findsOneWidget);
    expect(
      find.text('zaehlerverlauf_wasser_bad_20260905_083000.pdf'),
      findsNothing,
    );
    expect(find.textContaining('cccccccc'), findsNothing);
    expect(
      tester.getTopLeft(historyActionTitle).dy,
      lessThan(tester.getTopLeft(historyExportCard).dy),
    );
    final deleteHistory = find.byKey(
      const ValueKey('delete-evidence-history_export'),
    );
    expect(deleteHistory, findsOneWidget);
    expect(
      tester.widget<IconButton>(deleteHistory).tooltip,
      'PDF-Nachweis löschen',
    );
    await tester.tap(deleteHistory);
    await tester.pumpAndSettle();
    expect(find.text('Zählerverlaufsnachweis löschen?'), findsOneWidget);
    expect(
      find.textContaining('außerhalb der App gespeicherte Kopien'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Abbrechen'));
    await tester.pumpAndSettle();
    expect(exports.items, contains('history_export'));

    await tester.tap(deleteHistory);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(exports.items, isNot(contains('history_export')));
    expect(
      find.byKey(const ValueKey('evidence-export-history_export')),
      findsNothing,
    );
    expect(find.text('Gespeicherte PDF-Nachweise'), findsNothing);
    expect(find.text('PDF-Nachweis gelöscht.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Zählerverlauf als PDF erstellen'),
      -250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Zählerverlauf als PDF erstellen'));
    await tester.pumpAndSettle();
    expect(find.text('PDF-Inhalt wählen'), findsOneWidget);
    expect(find.text('Kompakt ohne Fotos'), findsOneWidget);
    expect(find.text('Mit aktuellen Fotos'), findsOneWidget);
    await tester.tap(find.text('Kompakt ohne Fotos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PDF-Nachweis wird erstellt'), findsOneWidget);
    expect(
      find.text(
        'Ablesungen und Korrekturen werden für die kompakte PDF zusammengestellt.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pdf-export-progress')), findsOneWidget);
    expect(find.text('Zählerverlauf als PDF erstellen'), findsOneWidget);
    expect(readings.loadForMeterCalls, 1);
  });
}

class _PendingRevisionRepository extends MemoryReadingRepository {
  final _pending = Completer<List<ReadingRevision>>();

  @override
  Future<List<ReadingRevision>> loadRevisions(String readingId) {
    return _pending.future;
  }
}

class _CountingHistoryReadingRepository extends MemoryReadingRepository {
  int watchForMeterCalls = 0;

  @override
  Stream<List<MeterReading>> watchForMeter(String meterId) {
    watchForMeterCalls++;
    return super.watchForMeter(meterId);
  }
}

class _SynchronousDeleteEvidenceReportService extends EvidenceReportService {
  _SynchronousDeleteEvidenceReportService(
    MemoryEvidenceExportRepository repository,
  ) : super(exports: repository);

  @override
  Future<void> delete(EvidenceExportRecord record) async {
    await exports.delete(record.id);
  }
}

class _FixedPhotoRepository implements MeterPhotoCaptureRepository {
  int captureCount = 0;

  final photo = StoredMeterPhoto(
    path: '/synthetic/meter.jpg',
    sha256: 'a' * 64,
    source: ReadingSource.camera,
    capturedAt: DateTime(2026, 9, 2, 10, 30),
  );

  @override
  Future<StoredMeterPhoto?> capture(ReadingSource source) async {
    captureCount++;
    return photo;
  }

  @override
  Future<void> delete(String path) async {}

  @override
  Future<StoredMeterPhoto?> recoverLostCapture() async => null;
}

class _FixedOcrRepository implements MeterOcrRepository {
  const _FixedOcrRepository();

  @override
  Future<MeterOcrResult> recognize(String imagePath) async {
    final value = ReadingValue.tryParse('123,4')!;
    return MeterOcrResult(
      rawText: '123,4 GJ',
      candidates: [
        OcrReadingCandidate(
          rawText: '123,4',
          value: value,
          confidence: 0.95,
          score: 0.95,
        ),
      ],
      confidence: 0.95,
    );
  }
}
