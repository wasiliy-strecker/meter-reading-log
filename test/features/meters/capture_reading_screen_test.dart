import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/files/meter_photo_repository.dart';
import 'package:meter_reading_log/core/ocr/meter_ocr_repository.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

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
    await tester.tap(find.text('Ablesen / Fotografieren'));
    await tester.pumpAndSettle();
    expect(find.text('Ablesen / Fotografieren'), findsWidgets);

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
      find.text('Grund der Korrektur *'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final reasonField = find.widgetWithText(
      TextFormField,
      'Grund der Korrektur *',
    );
    await tester.enterText(reasonField, 'Neues Nachweisfoto');

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Korrektur verwerfen?'), findsOneWidget);
    expect(find.text('Korrektur verwerfen'), findsOneWidget);
    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Grund der Korrektur *'), findsOneWidget);

    final saveCorrection = find.text('Korrektur protokollieren');
    await tester.ensureVisible(saveCorrection);
    await tester.tap(saveCorrection);
    await tester.pumpAndSettle();

    expect(find.text('Ablesung'), findsOneWidget);
    expect(readings.revisions.values.single, hasLength(1));

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Verlauf'), findsOneWidget);
    expect(find.text('Ablesen / Fotografieren'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('history PDF action shows immediate progress feedback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
      filePath: '/tmp/history.pdf',
      pdfSha256: 'c' * 64,
      manifestSha256: 'd' * 64,
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
      find.text('Verlauf als PDF erstellen'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('PDF-Nachweis des Verlaufs'), findsOneWidget);
    expect(
      find.textContaining('alle Ablesungen, Fotos und Korrekturen'),
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
    expect(
      find.descendant(of: readingCard, matching: find.text('Abgelesen am')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reading-thumbnail-reading_pdf')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Gespeicherte PDF-Nachweise'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(const ValueKey('evidence-export-history_export')),
      findsOneWidget,
    );
    expect(find.text('Verlaufsnachweis'), findsOneWidget);
    expect(find.text('Einzelnachweis'), findsOneWidget);
    expect(find.text('1 Ablesung enthalten'), findsOneWidget);
    expect(find.text('Zählerstand: 42,1 m³'), findsOneWidget);
    expect(find.text('Lokal gespeichert'), findsNWidgets(2));
    expect(
      find.text('zaehlerverlauf_wasser_bad_20260905_083000.pdf'),
      findsNothing,
    );
    expect(find.textContaining('cccccccc'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Verlauf als PDF erstellen'),
      -250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Verlauf als PDF erstellen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PDF-Nachweis wird erstellt'), findsOneWidget);
    expect(
      find.text(
        'Ablesungen, Fotos und Korrekturen werden für die PDF zusammengestellt.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pdf-export-progress')), findsOneWidget);
    expect(find.text('Verlauf als PDF erstellen'), findsOneWidget);
  });
}

class _PendingRevisionRepository extends MemoryReadingRepository {
  final _pending = Completer<List<ReadingRevision>>();

  @override
  Future<List<ReadingRevision>> loadRevisions(String readingId) {
    return _pending.future;
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
