import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/integrity/integrity_copy.dart';
import 'package:meter_reading_log/core/utils/formatters.dart';
import 'package:meter_reading_log/features/evidence/application/evidence_report_service.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';
import 'package:meter_reading_log/features/meters/presentation/reading_detail_screen.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('hides OCR diagnostics and explains empty correction history', (
    tester,
  ) async {
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
    expect(find.text(integrityProtectionTitle), findsNothing);
    expect(find.text(technicalChecksTitle), findsOneWidget);
    expect(find.textContaining(reading.photoSha256), findsNothing);

    await tester.ensureVisible(find.text(technicalChecksTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(technicalChecksTitle));
    await tester.pumpAndSettle();
    expect(find.textContaining(reading.photoSha256), findsOneWidget);
    expect(find.textContaining(reading.manifestSha256), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(pdfPurposeTitle),
      250,
      scrollable: scrollable,
    );
    expect(find.text(pdfPurposeText), findsOneWidget);
    expect(find.text(privateDocumentationText), findsOneWidget);
    expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
  });

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

  testWidgets('previous photos expand without an extra top and bottom frame', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
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

    final historyTile = find.widgetWithText(ExpansionTile, 'Frühere Fotos (1)');
    final tile = tester.widget<ExpansionTile>(historyTile);
    expect((tile.shape as RoundedRectangleBorder).side.style, BorderStyle.none);
    expect(
      (tile.collapsedShape as RoundedRectangleBorder).side.style,
      BorderStyle.none,
    );

    await tester.tap(find.text('Frühere Fotos (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Ursprüngliches Foto'), findsOneWidget);
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
      find.text('Einzelnachweis als PDF'),
      250,
      scrollable: scrollable,
    );

    await tester.tap(find.text('Einzelnachweis als PDF'));
    await tester.pump();
    await tester.pump();

    expect(find.text('PDF wird erstellt …'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.text('Foto und Nachweisdaten werden verarbeitet.'),
      findsOneWidget,
    );
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
  }) {
    return pending.future;
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
