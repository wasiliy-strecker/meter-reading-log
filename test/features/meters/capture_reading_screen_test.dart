import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/files/meter_photo_repository.dart';
import 'package:meter_reading_log/core/ocr/meter_ocr_repository.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets(
    'capture flow clearly exposes photo, unit, time and keyboard UX',
    (tester) async {
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

      await tester.tap(find.text('Wärme Keller'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ablesen / Fotografieren'));
      await tester.pumpAndSettle();
      expect(find.text('Ablesen / Fotografieren'), findsWidgets);

      await tester.tap(find.text('Zähler fotografieren'));
      await tester.pumpAndSettle();

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

      await tester.ensureVisible(
        find.text('Ablesung bestätigen und speichern'),
      );
      await tester.tap(find.text('Ablesung bestätigen und speichern'));
      for (var attempt = 0; attempt < 30 && readings.items.isEmpty; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(meters.items[meter.id]!.unit, 'kWh');
      expect(readings.items.values.single.meter.unit, 'kWh');
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(OutlinedButton, 'Korrigieren'),
        findsOneWidget,
      );
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
          'Korrekturen überschreiben den ursprünglichen Eintrag nicht',
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
      expect(find.text('Erkannte Werte'), findsOneWidget);
    },
  );

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
    await tester.tap(find.text('Verlauf als PDF erstellen'));
    await tester.pump();
    await tester.pump();

    expect(find.text('PDF wird erstellt …'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
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
  final photo = StoredMeterPhoto(
    path: '/synthetic/meter.jpg',
    sha256: 'a' * 64,
    source: ReadingSource.camera,
    capturedAt: DateTime(2026, 9, 2, 10, 30),
  );

  @override
  Future<StoredMeterPhoto?> capture(ReadingSource source) async => photo;

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
