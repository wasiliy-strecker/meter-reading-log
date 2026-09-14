import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/app/app_router.dart';
import 'package:meter_reading_log/core/files/meter_photo_repository.dart';
import 'package:meter_reading_log/core/ocr/meter_ocr_repository.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import '../../support/fakes.dart';
import '../../support/reading_fixtures.dart';

void main() {
  testWidgets('OCR failure keeps photo and allows manually confirmed capture', (
    tester,
  ) async {
    final state = await startApp(tester);
    await tester.tap(find.text('Zähler fotografieren'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Texterkennung fehlgeschlagen.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).first, '7');
    await tester.ensureVisible(find.text('Ablesung bestätigen und speichern'));
    await tester.tap(find.text('Ablesung bestätigen und speichern'));
    for (var i = 0; i < 30 && state.readings.items.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    final saved = state.readings.items.values.single;
    expect(saved.value.canonical, '7');
    expect(saved.photoPath, '/synthetic/new.jpg');
    expect(saved.ocrRawText, isEmpty);
    expect(saved.ocrCandidate, isEmpty);
    expect(state.photos.deleted, isEmpty);
  });

  testWidgets('discarding a photo after OCR failure removes the unsaved file', (
    tester,
  ) async {
    final state = await startApp(tester);
    await tester.tap(find.text('Zähler fotografieren'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ablesung verwerfen'));
    await tester.pumpAndSettle();
    expect(state.photos.deleted, ['/synthetic/new.jpg']);
    expect(state.readings.items, isEmpty);
  });

  testWidgets(
    'replacement photo survives OCR failure and is saved with history',
    (tester) async {
      final state = await startApp(tester, editing: true);
      await tester.ensureVisible(find.text('Neues Foto für Korrektur'));
      await tester.tap(find.text('Neues Foto für Korrektur'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neu fotografieren'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Texterkennung fehlgeschlagen.'),
        250,
      );
      expect(
        find.textContaining('Texterkennung fehlgeschlagen.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, '12,8');
      await tester.ensureVisible(find.text('Korrektur protokollieren'));
      await tester.tap(find.text('Korrektur protokollieren'));
      for (var i = 0; i < 30 && state.readings.revisions.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      final reading = state.readings.items['reading']!;
      expect(reading.photoPath, '/synthetic/new.jpg');
      expect(reading.photoHistory, hasLength(2));
      expect(reading.value.canonical, '12.8');
      expect(reading.ocrCandidate, isEmpty);
      expect(state.photos.deleted, isEmpty);
    },
  );

  testWidgets(
    'note correction preserves legacy numeric meaning despite stricter parser',
    (tester) async {
      final legacy = readingFixture().copyWith(
        value: const ReadingValue(
          displayText: '1.234.567',
          digits: '1234567',
          scale: 3,
        ),
      );
      final state = await startApp(tester, editing: true, existing: legacy);
      final note = find.widgetWithText(TextFormField, 'Notiz');
      await tester.scrollUntilVisible(
        note,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(note, 'Nur Notiz geändert');
      await tester.ensureVisible(find.text('Korrektur protokollieren'));
      await tester.tap(find.text('Korrektur protokollieren'));
      for (var i = 0; i < 30 && state.readings.revisions.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(
        state.readings.items['reading']!.value.toJson(),
        legacy.value.toJson(),
      );
      expect(state.readings.revisions['reading']!.single.changes.keys, [
        'Notiz',
      ]);
    },
  );

  testWidgets(
    'leaving during OCR deletes the returned photo without updating disposed state',
    (tester) async {
      final ocr = PendingOcr();
      final state = await startApp(tester, ocr: ocr);
      await tester.tap(find.text('Zähler fotografieren'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      ocr.result.complete(
        const MeterOcrResult(rawText: '', candidates: [], confidence: 0),
      );
      await tester.pumpAndSettle();
      expect(state.photos.deleted, ['/synthetic/new.jpg']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recovered camera photo also supports manual input after OCR failure',
    (tester) async {
      final state = await startApp(tester, recovered: true);
      expect(
        find.textContaining('Texterkennung fehlgeschlagen.'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(state.photos.deleted, ['/synthetic/new.jpg']);
    },
  );
}

typedef AppState = ({MemoryReadingRepository readings, CapturePhotos photos});
Future<AppState> startApp(
  WidgetTester tester, {
  bool editing = false,
  MeterReading? existing,
  bool recovered = false,
  MeterOcrRepository? ocr,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final readings = MemoryReadingRepository();
  if (editing) readings.items['reading'] = existing ?? readingFixture();
  final photos = CapturePhotos(recovered);
  final container = ProviderContainer(
    overrides: [
      meterRepositoryProvider.overrideWithValue(
        MemoryMeterRepository()..items['meter'] = meterFixture(),
      ),
      meterReadingRepositoryProvider.overrideWithValue(readings),
      evidenceExportRepositoryProvider.overrideWithValue(
        MemoryEvidenceExportRepository(),
      ),
      meterPhotoCaptureRepositoryProvider.overrideWithValue(photos),
      meterOcrRepositoryProvider.overrideWithValue(ocr ?? FailedOcr()),
      meterReminderRepositoryProvider.overrideWithValue(
        NoopMeterReminderRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MeterReadingLogApp(),
    ),
  );
  await tester.pumpAndSettle();
  container
      .read(appRouterProvider)
      .go(editing ? '/reading/reading/edit' : '/meter/meter/capture');
  await tester.pumpAndSettle();
  return (readings: readings, photos: photos);
}

class CapturePhotos implements MeterPhotoCaptureRepository {
  CapturePhotos(this.recovered);
  final bool recovered;
  final deleted = <String>[];
  StoredMeterPhoto get photo => StoredMeterPhoto(
    path: '/synthetic/new.jpg',
    sha256: 'c' * 64,
    source: ReadingSource.camera,
    capturedAt: preciseTime,
  );
  @override
  Future<StoredMeterPhoto?> capture(ReadingSource source) async => photo;
  @override
  Future<StoredMeterPhoto?> recoverLostCapture() async =>
      recovered ? photo : null;
  @override
  Future<void> delete(String path) async {
    deleted.add(path);
  }
}

class FailedOcr implements MeterOcrRepository {
  @override
  Future<MeterOcrResult> recognize(String path) async =>
      throw StateError('Synthetic OCR failure');
}

class PendingOcr implements MeterOcrRepository {
  final result = Completer<MeterOcrResult>();
  @override
  Future<MeterOcrResult> recognize(String path) => result.future;
}
