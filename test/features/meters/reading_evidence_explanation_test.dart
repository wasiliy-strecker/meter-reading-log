import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/integrity/integrity_copy.dart';
import 'package:meter_reading_log/core/utils/formatters.dart';
import 'package:meter_reading_log/features/evidence/application/evidence_report_service.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';
import 'package:meter_reading_log/features/meters/presentation/reading_detail_screen.dart';

import '../../support/fakes.dart';

void main() {
  const unchangedReadingManifest = 'unchanged-reading-manifest';

  testWidgets(
    'hides OCR and hash diagnostics and explains empty correction history',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final reading = _reading();
      final readings = MemoryReadingRepository()..items[reading.id] = reading;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            meterReadingRepositoryProvider.overrideWithValue(readings),
            evidenceExportRepositoryProvider.overrideWithValue(
              MemoryEvidenceExportRepository(),
            ),
          ],
          child: MaterialApp(home: ReadingDetailScreen(readingId: reading.id)),
        ),
      );
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      expect(scrollable, findsOneWidget);
      expect(find.text('OCR-Kandidat'), findsNothing);
      expect(find.text('OCR-Konfidenz'), findsNothing);
      expect(find.text('Manuell abweichend'), findsNothing);

      await tester.scrollUntilVisible(
        find.text(correctionHistoryTitle),
        250,
        scrollable: scrollable,
      );
      expect(find.text(correctionHistoryText), findsOneWidget);
      expect(
        find.text('Für diese Ablesung gibt es noch keine Korrekturen.'),
        findsOneWidget,
      );
      expect(find.textContaining('Schutz vor nachträglichen'), findsNothing);
      expect(find.text('Technische Prüfwerte anzeigen'), findsNothing);
      expect(find.textContaining('SHA-256'), findsNothing);
      expect(find.textContaining(reading.photoSha256), findsNothing);
      expect(find.textContaining(reading.manifestSha256), findsNothing);

      await tester.scrollUntilVisible(
        find.text(pdfPurposeTitle),
        250,
        scrollable: scrollable,
      );
      expect(find.text(pdfPurposeText), findsOneWidget);
      expect(find.text(privateDocumentationText), findsNothing);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    },
  );

  testWidgets('shows correction reason and newest changes first', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final reading = _reading();
    final olderChange = DateTime.utc(2026, 9, 3, 8);
    final newerChange = DateTime.utc(2026, 9, 4, 9);
    final readings = MemoryReadingRepository()
      ..items[reading.id] = reading
      ..revisions[reading.id] = [
        ReadingRevision(
          id: 'revision_older',
          readingId: reading.id,
          changedAt: olderChange,
          reason: 'Zahlendreher berichtigt',
          changes: const {
            'Zählerstand': ReadingChange(before: '24,1', after: '42,1'),
          },
        ),
        ReadingRevision(
          id: 'revision_newer',
          readingId: reading.id,
          changedAt: newerChange,
          reason: 'Unscharfes Foto ausgetauscht',
          changes: {
            'Prüfwert des Fotos (SHA-256)': ReadingChange(
              before: 'c' * 64,
              after: 'd' * 64,
            ),
            'OCR-Kandidat': const ReadingChange(before: '24,1', after: '42,1'),
          },
        ),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(
            MemoryEvidenceExportRepository(),
          ),
        ],
        child: MaterialApp(home: ReadingDetailScreen(readingId: reading.id)),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(correctionHistoryTitle),
      250,
      scrollable: scrollable,
    );

    final newerTitle = find.text(
      'Korrektur vom ${formatDateTime(newerChange)}',
    );
    final olderTitle = find.text(
      'Korrektur vom ${formatDateTime(olderChange)}',
    );
    expect(newerTitle, findsOneWidget);
    expect(olderTitle, findsOneWidget);
    expect(
      tester.getTopLeft(newerTitle).dy,
      lessThan(tester.getTopLeft(olderTitle).dy),
    );
    expect(find.text('Grund: Unscharfes Foto ausgetauscht'), findsOneWidget);
    expect(find.text('Grund: Zahlendreher berichtigt'), findsOneWidget);
    expect(find.text('Vorher:'), findsOneWidget);
    expect(find.text('Neu:'), findsOneWidget);
    expect(find.text('24,1 m³'), findsOneWidget);
    expect(find.text('42,1 m³'), findsWidgets);
    expect(find.text('Nachweisfoto geändert'), findsOneWidget);
    expect(find.text('OCR-Kandidat'), findsNothing);
    expect(find.textContaining('c' * 64), findsNothing);
    expect(find.textContaining('d' * 64), findsNothing);
  });

  testWidgets('shows correction photo and expands its previous photo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final reading = _reading(
      photoHistory: [
        ReadingPhotoVersion(
          id: 'original_photo',
          path: '/tmp/original.jpg',
          sha256: 'c' * 64,
          source: ReadingSource.gallery,
          addedAt: DateTime.utc(2026, 9, 1, 10),
          ocrRawText: '41,9',
          ocrCandidate: '41,9',
        ),
      ],
    );
    final readings = MemoryReadingRepository()
      ..items[reading.id] = reading
      ..revisions[reading.id] = [
        ReadingRevision(
          id: 'revision_photo',
          readingId: reading.id,
          changedAt: reading.effectivePhotoAddedAt,
          reason: 'Foto war unscharf',
          changes: {
            'Prüfwert des Fotos (SHA-256)': ReadingChange(
              before: 'c' * 64,
              after: 'a' * 64,
            ),
          },
        ),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(
            MemoryEvidenceExportRepository(),
          ),
        ],
        child: MaterialApp(home: ReadingDetailScreen(readingId: reading.id)),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Neues Foto'),
      250,
      scrollable: scrollable,
    );

    expect(find.textContaining('Frühere Fotos'), findsNothing);
    expect(
      find.bySemanticsLabel('Neues Foto der Korrektur revision_photo'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Vorheriges Foto der Korrektur revision_photo'),
      findsNothing,
    );

    final previousPhotoTile = find.widgetWithText(
      ExpansionTile,
      'Vorheriges Foto anzeigen',
    );
    final tile = tester.widget<ExpansionTile>(previousPhotoTile);
    expect((tile.shape as RoundedRectangleBorder).side.style, BorderStyle.none);
    expect(
      (tile.collapsedShape as RoundedRectangleBorder).side.style,
      BorderStyle.none,
    );

    await tester.scrollUntilVisible(
      find.text('Vorheriges Foto anzeigen'),
      250,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Vorheriges Foto anzeigen'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Vorheriges Foto der Korrektur revision_photo'),
      findsOneWidget,
    );
  });

  testWidgets('single PDF action immediately shows indeterminate progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final reading = _reading();
    final readings = MemoryReadingRepository()..items[reading.id] = reading;
    final pendingReports = _PendingEvidenceReportService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(
            MemoryEvidenceExportRepository(),
          ),
          evidenceReportServiceProvider.overrideWithValue(pendingReports),
        ],
        child: MaterialApp(home: ReadingDetailScreen(readingId: reading.id)),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Einzelnachweis als PDF erstellen'),
      250,
      scrollable: scrollable,
    );

    await tester.tap(find.text('Einzelnachweis als PDF erstellen'));
    await tester.pumpAndSettle();
    expect(find.text('PDF-Inhalt wählen'), findsOneWidget);
    expect(find.text('Kompakt ohne Fotos'), findsOneWidget);
    expect(find.text('Mit aktuellem Foto'), findsOneWidget);
    await tester.tap(find.text('Mit aktuellem Foto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PDF-Nachweis wird erstellt'), findsOneWidget);
    expect(find.byKey(const ValueKey('pdf-export-progress')), findsOneWidget);
    expect(
      find.text(
        'Das aktuelle Foto und die Nachweisdaten werden für die PDF zusammengestellt.',
      ),
      findsOneWidget,
    );
    expect(find.text('Einzelnachweis als PDF erstellen'), findsOneWidget);
  });

  testWidgets('shows saved single evidence and keeps creation available', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('saved_single_evidence_'),
    ))!;
    addTearDown(() => temp.delete(recursive: true));
    final pdf = File('${temp.path}/single.pdf');
    final photoPdf = File('${temp.path}/single-photo.pdf');
    await tester.runAsync(
      () => Future.wait([
        pdf.writeAsBytes(const [0x25, 0x50, 0x44, 0x46]),
        photoPdf.writeAsBytes(const [0x25, 0x50, 0x44, 0x46]),
      ]),
    );
    final reading = _reading();
    final readings = MemoryReadingRepository()..items[reading.id] = reading;
    final exports = MemoryEvidenceExportRepository();
    exports.items['single_current'] = EvidenceExportRecord(
      id: 'single_current',
      meterId: reading.meterId,
      kind: EvidenceExportKind.singleReading,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 9, 5, 10),
      fileName: 'single.pdf',
      filePath: pdf.path,
      pdfSha256: 'c' * 64,
      manifestSha256: unchangedReadingManifest,
      photoMode: EvidencePhotoMode.withoutPhotos,
    );
    exports.items['single_current_photo'] = EvidenceExportRecord(
      id: 'single_current_photo',
      meterId: reading.meterId,
      kind: EvidenceExportKind.singleReading,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 9, 5, 10, 1),
      fileName: 'single-photo.pdf',
      filePath: photoPdf.path,
      pdfSha256: 'f' * 64,
      manifestSha256: unchangedReadingManifest,
      photoMode: EvidencePhotoMode.currentPhotos,
    );
    exports.items['history'] = EvidenceExportRecord(
      id: 'history',
      meterId: reading.meterId,
      kind: EvidenceExportKind.meterHistory,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 9, 5, 9),
      fileName: 'history.pdf',
      filePath: '${temp.path}/history.pdf',
      pdfSha256: 'd' * 64,
      manifestSha256: 'e' * 64,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(exports),
          evidenceReportServiceProvider.overrideWithValue(
            _SynchronousDeleteEvidenceReportService(exports),
          ),
        ],
        child: MaterialApp(home: ReadingDetailScreen(readingId: reading.id)),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Gespeicherte Einzelnachweise'),
      250,
      scrollable: scrollable,
    );

    expect(
      find.byKey(const ValueKey('evidence-export-single_current')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('evidence-export-single_current_photo')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('evidence-export-history')), findsNothing);
    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Einzelnachweis als PDF erstellen'),
    );
    expect(createButton.onPressed, isNotNull);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('evidence-export-single_current')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.widgetWithText(
                FilledButton,
                'Einzelnachweis als PDF erstellen',
              ),
            )
            .dy,
      ),
    );
    expect(
      find.text('Beide aktuellen Varianten bereits erstellt'),
      findsNothing,
    );
    expect(find.text('Aktueller PDF-Nachweis'), findsNothing);
    expect(find.byKey(const ValueKey('current-evidence-status')), findsNothing);

    await tester.tap(find.text('Einzelnachweis als PDF erstellen'));
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

    final deletePhotoEvidence = find.byKey(
      const ValueKey('delete-evidence-single_current_photo'),
    );
    expect(deletePhotoEvidence, findsOneWidget);
    await tester.tap(deletePhotoEvidence);
    await tester.pumpAndSettle();
    expect(find.text('Einzelnachweis löschen?'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Abbrechen'));
    await tester.pumpAndSettle();
    expect(exports.items, contains('single_current_photo'));
    expect(photoPdf.existsSync(), isTrue);

    await tester.tap(deletePhotoEvidence);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(exports.items, isNot(contains('single_current_photo')));
    expect(
      find.byKey(const ValueKey('evidence-export-single_current_photo')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('evidence-export-single_current')),
      findsOneWidget,
    );
    final stillEnabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Einzelnachweis als PDF erstellen'),
    );
    expect(stillEnabledButton.onPressed, isNotNull);
    expect(find.text('Aktueller PDF-Nachweis'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('evidence-export-single_current')),
        matching: find.textContaining('Kompakt ohne Fotos'),
      ),
      findsOneWidget,
    );
    expect(find.text('PDF-Nachweis gelöscht.'), findsOneWidget);
  });

  testWidgets('keeps a single PDF visible when deletion fails', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final reading = _reading();
    final readings = MemoryReadingRepository()..items[reading.id] = reading;
    final exports = MemoryEvidenceExportRepository();
    exports.items['single_failed'] = EvidenceExportRecord(
      id: 'single_failed',
      meterId: reading.meterId,
      kind: EvidenceExportKind.singleReading,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 9, 7),
      fileName: 'single-failed.pdf',
      filePath: '/tmp/single-failed.pdf',
      pdfSha256: 'c' * 64,
      manifestSha256: unchangedReadingManifest,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(exports),
          evidenceReportServiceProvider.overrideWithValue(
            _FailingDeleteEvidenceReportService(),
          ),
        ],
        child: MaterialApp(home: ReadingDetailScreen(readingId: reading.id)),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('delete-evidence-single_failed')),
      250,
      scrollable: scrollable,
    );

    await tester.tap(
      find.byKey(const ValueKey('delete-evidence-single_failed')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(exports.items, contains('single_failed'));
    expect(
      find.byKey(const ValueKey('evidence-export-single_failed')),
      findsOneWidget,
    );
    expect(
      find.text(
        'PDF-Nachweis konnte nicht gelöscht werden. Bitte versuche es erneut.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('missing single evidence file does not block recreation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final reading = _reading();
    final readings = MemoryReadingRepository()..items[reading.id] = reading;
    final exports = MemoryEvidenceExportRepository();
    exports.items['single_missing'] = EvidenceExportRecord(
      id: 'single_missing',
      meterId: reading.meterId,
      kind: EvidenceExportKind.singleReading,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 9, 5, 10),
      fileName: 'missing.pdf',
      filePath: '/tmp/definitely-missing-meter-reading-log.pdf',
      pdfSha256: 'c' * 64,
      manifestSha256: unchangedReadingManifest,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(exports),
        ],
        child: MaterialApp(home: ReadingDetailScreen(readingId: reading.id)),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Einzelnachweis als PDF erstellen'),
      250,
      scrollable: scrollable,
    );

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Einzelnachweis als PDF erstellen'),
    );
    expect(createButton.onPressed, isNotNull);
    expect(find.text('Datei fehlt'), findsOneWidget);
    expect(find.byKey(const ValueKey('current-evidence-status')), findsNothing);
  });

  testWidgets('a correction enables a new single evidence PDF', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('corrected_single_evidence_'),
    ))!;
    addTearDown(() => temp.delete(recursive: true));
    final pdf = File('${temp.path}/old-single.pdf');
    await tester.runAsync(
      () => pdf.writeAsBytes(const [0x25, 0x50, 0x44, 0x46]),
    );
    final reading = _reading();
    final readings = MemoryReadingRepository()..items[reading.id] = reading;
    final exports = MemoryEvidenceExportRepository();
    readings.revisions[reading.id] = [
      ReadingRevision(
        id: 'revision_after_export',
        readingId: reading.id,
        changedAt: DateTime.utc(2026, 9, 5, 11),
        reason: 'Zählerstand korrigiert',
        changes: const {
          'Zählerstand': ReadingChange(before: '41,2', after: '42,1'),
        },
      ),
    ];
    exports.items['single_before_correction'] = EvidenceExportRecord(
      id: 'single_before_correction',
      meterId: reading.meterId,
      kind: EvidenceExportKind.singleReading,
      readingIds: [reading.id],
      createdAt: DateTime.utc(2026, 9, 5, 10),
      fileName: 'old-single.pdf',
      filePath: pdf.path,
      pdfSha256: 'c' * 64,
      manifestSha256: unchangedReadingManifest,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(exports),
        ],
        child: MaterialApp(home: ReadingDetailScreen(readingId: reading.id)),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Einzelnachweis als PDF erstellen'),
      250,
      scrollable: scrollable,
    );

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Einzelnachweis als PDF erstellen'),
    );
    expect(createButton.onPressed, isNotNull);
    expect(
      find.byKey(const ValueKey('evidence-export-single_before_correction')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('current-evidence-status')), findsNothing);
  });
}

class _PendingEvidenceReportService extends EvidenceReportService {
  _PendingEvidenceReportService()
    : super(exports: MemoryEvidenceExportRepository());

  final pending = Completer<GeneratedEvidenceReport>();

  @override
  Future<GeneratedEvidenceReport> createSingle({
    required MeterReading reading,
    required List<ReadingRevision> revisions,
    EvidencePhotoMode photoMode = EvidencePhotoMode.allPhotos,
  }) {
    return pending.future;
  }
}

class _FailingDeleteEvidenceReportService extends EvidenceReportService {
  _FailingDeleteEvidenceReportService()
    : super(exports: MemoryEvidenceExportRepository());

  @override
  Future<void> delete(EvidenceExportRecord record) {
    throw StateError('Löschen fehlgeschlagen');
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

MeterReading _reading({List<ReadingPhotoVersion> photoHistory = const []}) {
  final meter = Meter(
    id: 'meter_1',
    label: 'Wasser Bad',
    type: MeterType.water,
    unit: 'm³',
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 1),
  );
  return MeterReading(
    id: 'reading_1',
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
    photoHistory: photoHistory,
    manifestSha256: 'b' * 64,
  );
}
