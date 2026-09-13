import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/app/app_theme.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export.dart';
import 'package:meter_reading_log/features/evidence/domain/evidence_export_page.dart';
import 'package:meter_reading_log/features/evidence/presentation/evidence_export_card.dart';
import 'package:meter_reading_log/features/evidence/presentation/evidence_list_providers.dart';
import 'package:meter_reading_log/features/evidence/presentation/saved_history_pdfs.dart';
import 'package:meter_reading_log/features/meters/data/in_memory_meter_repositories.dart';

import 'evidence_export_page_test.dart' show exportFixture;

const _expansion = ValueKey('saved-history-pdfs-expansion');
const _next = ValueKey('history-pdfs-next-page');
const _previous = ValueKey('history-pdfs-previous-page');

void main() {
  for (final count in [6, 10, 11, 12]) {
    testWidgets('$count PDFs: paginate only above ten records', (tester) async {
      final repository = _TrackingExports();
      addTearDown(repository.dispose);
      for (var i = 0; i < count; i++) {
        await repository.save(exportFixture(i));
      }
      final container = ProviderContainer(
        overrides: [
          evidenceExportRepositoryProvider.overrideWithValue(repository),
          evidenceFileAvailableProvider.overrideWith((ref, path) async => true),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, container);
      expect(find.text('$count Nachweise'), findsOneWidget);
      await _tap(tester, _expansion);
      expect(repository.requests.last.limit, 10);
      expect(repository.requests.last.offset, 0);
      expect(
        find.byType(EvidenceExportCard),
        findsNWidgets(count > 10 ? 10 : count),
      );
      if (count <= 10) {
        expect(find.byKey(_next), findsNothing);
        expect(find.byKey(_previous), findsNothing);
      } else {
        expect(find.text('Seite 1 von 2'), findsOneWidget);
        await _tap(tester, _next);
        expect(repository.requests.last.offset, 10);
        expect(find.byType(EvidenceExportCard), findsNWidgets(count - 10));
        expect(find.text('Seite 2 von 2'), findsOneWidget);
        expect(
          tester.widget<OutlinedButton>(find.byKey(_next)).onPressed,
          isNull,
        );
        await _tap(tester, _previous);
        expect(find.byType(EvidenceExportCard), findsNWidgets(10));
        expect(repository.requests.last.offset, 0);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    '100 PDFs: only ten metadata rows and ten async checks per page',
    (tester) async {
      final repository = _TrackingExports();
      addTearDown(repository.dispose);
      for (var i = 0; i < 100; i++) {
        await repository.save(exportFixture(i));
      }
      final checked = <String>[];
      final opened = <String>[];
      final container = ProviderContainer(
        overrides: [
          evidenceExportRepositoryProvider.overrideWithValue(repository),
          evidenceFileAvailableProvider.overrideWith((ref, path) async {
            checked.add(path);
            return true;
          }),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, container, onOpen: (e) async => opened.add(e.id));
      expect(find.text('100 Nachweise'), findsOneWidget);
      expect(checked, isEmpty);
      expect(find.byType(EvidenceExportCard), findsNothing);
      expect(repository.requests.single.limit, 10);
      await _tap(tester, _expansion);
      for (var page = 0; page < 10; page++) {
        expect(find.byType(EvidenceExportCard), findsNWidgets(10));
        expect(find.text('Seite ${page + 1} von 10'), findsOneWidget);
        expect(repository.requests.last.offset, page * 10);
        expect(checked.length, (page + 1) * 10);
        if (page < 9) await _tap(tester, _next);
      }
      expect(checked.toSet().length, 100);
      expect(opened, isEmpty);
      expect(
        tester.widget<OutlinedButton>(find.byKey(_next)).onPressed,
        isNull,
      );
      await _tap(tester, _previous);
      expect(find.text('Seite 9 von 10'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('evidence-export-export_019')),
      );
      await tester.tap(
        find.byKey(const ValueKey('evidence-export-export_019')),
      );
      await tester.pumpAndSettle();
      expect(opened, ['export_019']);
      await _tap(tester, _expansion);
      final before = checked.length;
      await repository.save(exportFixture(100));
      await tester.pumpAndSettle();
      expect(find.text('101 Nachweise'), findsOneWidget);
      expect(find.byType(EvidenceExportCard), findsNothing);
      expect(checked.length, before);
      expect(repository.unboundedWatches, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing PDF stays deletable, final page clamps, new export resets',
    (tester) async {
      final repository = _TrackingExports();
      addTearDown(repository.dispose);
      for (var i = 0; i < 21; i++) {
        await repository.save(exportFixture(i));
      }
      final reset = ValueNotifier(0);
      addTearDown(reset.dispose);
      final container = ProviderContainer(
        overrides: [
          evidenceExportRepositoryProvider.overrideWithValue(repository),
          evidenceFileAvailableProvider.overrideWith(
            (ref, path) async => path != '/synthetic/000.pdf',
          ),
        ],
      );
      addTearDown(container.dispose);
      await _pump(
        tester,
        container,
        reset: reset,
        onDelete: (e) => repository.delete(e.id),
      );
      await _tap(tester, _expansion);
      await _tap(tester, _next);
      await _tap(tester, _next);
      expect(find.text('Seite 3 von 3'), findsOneWidget);
      expect(find.text('Datei fehlt'), findsOneWidget);
      expect(
        tester
            .widget<EvidenceExportCard>(find.byType(EvidenceExportCard))
            .onTap,
        isNull,
      );
      await _tap(tester, const ValueKey('delete-evidence-export_000'));
      expect(find.text('Seite 2 von 2'), findsOneWidget);
      expect(find.byType(EvidenceExportCard), findsNWidgets(10));
      expect(repository.requests.last.offset, 10);
      await repository.save(exportFixture(21));
      reset.value++;
      await tester.pumpAndSettle();
      expect(find.text('Seite 1 von 3'), findsOneWidget);
      expect(repository.requests.last.offset, 0);
      expect(
        find.byKey(const ValueKey('evidence-export-export_021')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('page error and file error are retryable on narrow display', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _TrackingExports()..fail = true;
    addTearDown(repository.dispose);
    await repository.save(exportFixture(1));
    var fileFails = true;
    final container = ProviderContainer(
      overrides: [
        evidenceExportRepositoryProvider.overrideWithValue(repository),
        evidenceFileAvailableProvider.overrideWith((ref, path) async {
          if (fileFails) throw StateError('Synthetic file error');
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
    await _pump(tester, container);
    await _tap(tester, _expansion);
    expect(
      find.text('PDF-Nachweise konnten nicht geladen werden.'),
      findsOneWidget,
    );
    repository.fail = false;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Dateistatus konnte nicht geprüft werden.'),
      findsOneWidget,
    );
    expect(find.text('Datei fehlt'), findsNothing);
    fileFails = false;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('Lokal gespeichert'), findsOneWidget);
    expect(find.byKey(_next), findsNothing);
    for (var i = 2; i <= 11; i++) {
      await repository.save(exportFixture(i));
    }
    await tester.pumpAndSettle();
    await _tap(tester, _next);
    expect(find.text('Seite 2 von 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final finder = key == _expansion
      ? find.text('Gespeicherte PDF-Nachweise')
      : find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container, {
  ValueNotifier<int>? reset,
  Future<void> Function(EvidenceExportRecord)? onOpen,
  Future<void> Function(EvidenceExportRecord)? onDelete,
}) async {
  Widget content(int token) => SavedHistoryPdfs(
    meterId: 'meter',
    resetPageToken: token,
    deletingExportIds: const {},
    onOpen: onOpen ?? (_) async {},
    onDelete: onDelete ?? (_) async {},
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ListView(
            children: [
              if (reset == null)
                content(0)
              else
                ValueListenableBuilder<int>(
                  valueListenable: reset,
                  builder: (_, token, _) => content(token),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TrackingExports extends InMemoryEvidenceExportRepository {
  final requests = <({int limit, int offset})>[];
  int unboundedWatches = 0;
  bool fail = false;

  @override
  Stream<List<EvidenceExportRecord>> watchForMeter(String meterId) {
    unboundedWatches++;
    return super.watchForMeter(meterId);
  }

  @override
  Stream<EvidenceExportPage> watchPageForMeter(
    String meterId, {
    required EvidenceExportKind kind,
    required int limit,
    int offset = 0,
  }) {
    requests.add((limit: limit, offset: offset));
    if (fail) return Stream.error(StateError('Synthetic page error'));
    return super.watchPageForMeter(
      meterId,
      kind: kind,
      limit: limit,
      offset: offset,
    );
  }
}
