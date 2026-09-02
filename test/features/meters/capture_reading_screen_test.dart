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
    },
  );
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
