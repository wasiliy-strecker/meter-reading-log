import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/evidence/presentation/evidence_export_card.dart';

void main() {
  testWidgets(
    'keeps opening and deletion separate and blocks both while deleting',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var opened = 0;
      var deleted = 0;

      Widget buildCard({required bool deleting}) => MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: EvidenceExportCard(
              export: _record,
              title: 'Einzelnachweis',
              detail: 'Zählerstand: 42,1 m³\nKompakt ohne Fotos',
              onTap: () => opened++,
              onDelete: () => deleted++,
              deleting: deleting,
            ),
          ),
        ),
      );

      await tester.pumpWidget(buildCard(deleting: false));
      await tester.tap(find.text('Einzelnachweis'));
      expect(opened, 1);
      expect(deleted, 0);

      await tester.tap(
        find.byKey(const ValueKey('delete-evidence-evidence_1')),
      );
      expect(opened, 1);
      expect(deleted, 1);

      await tester.pumpWidget(buildCard(deleting: true));
      expect(
        find.byKey(const ValueKey('delete-evidence-evidence_1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('delete-evidence-progress-evidence_1')),
        findsOneWidget,
      );
      await tester.tap(find.text('Einzelnachweis'));
      expect(opened, 1);
      expect(deleted, 1);
    },
  );
}

final _record = EvidenceExportRecord(
  id: 'evidence_1',
  meterId: 'meter_1',
  kind: EvidenceExportKind.singleReading,
  readingIds: const ['reading_1'],
  createdAt: DateTime.utc(2026, 9, 7),
  fileName: 'single.pdf',
  filePath: '/tmp/single.pdf',
  pdfSha256: 'c' * 64,
  manifestSha256: 'd' * 64,
);
