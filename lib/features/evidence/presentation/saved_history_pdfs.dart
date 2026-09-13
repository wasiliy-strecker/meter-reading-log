import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../domain/evidence_export.dart';
import 'evidence_export_card.dart';
import 'evidence_list_providers.dart';

class SavedHistoryPdfs extends ConsumerStatefulWidget {
  const SavedHistoryPdfs({
    super.key,
    required this.meterId,
    required this.deletingExportIds,
    required this.onOpen,
    required this.onDelete,
    this.resetPageToken = 0,
  });

  final String meterId;
  final Set<String> deletingExportIds;
  final Future<void> Function(EvidenceExportRecord) onOpen;
  final Future<void> Function(EvidenceExportRecord) onDelete;
  final int resetPageToken;

  @override
  ConsumerState<SavedHistoryPdfs> createState() => _SavedHistoryPdfsState();
}

class _SavedHistoryPdfsState extends ConsumerState<SavedHistoryPdfs>
    with AutomaticKeepAliveClientMixin {
  static const _pageSize = 10;
  final _headingKey = GlobalKey();
  int _offset = 0;
  bool _expanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant SavedHistoryPdfs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meterId != widget.meterId ||
        oldWidget.resetPageToken != widget.resetPageToken) {
      _offset = 0;
    }
  }

  void _showPage(int offset) {
    setState(() => _offset = offset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final headingContext = _headingKey.currentContext;
      if (mounted && _expanded && headingContext != null) {
        Scrollable.ensureVisible(headingContext, alignment: 0.1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final request = (
      meterId: widget.meterId,
      kind: EvidenceExportKind.meterHistory,
      limit: _pageSize,
      offset: _offset,
    );
    final pageAsync = ref.watch(evidenceExportPageProvider(request));
    final page = pageAsync.value;
    if (page != null && _offset > 0 && _offset >= page.totalCount) {
      final validOffset = page.totalCount == 0
          ? 0
          : ((page.totalCount - 1) ~/ _pageSize) * _pageSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _offset == request.offset) _showPage(validOffset);
      });
    }
    if (page != null && page.totalCount == 0 && !pageAsync.hasError) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        key: const ValueKey('saved-history-pdfs'),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('saved-history-pdfs-expansion'),
            initiallyExpanded: _expanded,
            onExpansionChanged: (value) => setState(() => _expanded = value),
            leading: Icon(Icons.folder_copy_outlined, color: colors.primary),
            title: Text(
              'Gespeicherte PDF-Nachweise',
              key: _headingKey,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              pageAsync.hasError
                  ? 'Nachweise konnten nicht geladen werden'
                  : page == null
                  ? 'Nachweise werden geladen …'
                  : page.totalCount == 1
                  ? '1 Nachweis'
                  : '${page.totalCount} Nachweise',
            ),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            shape: const RoundedRectangleBorder(),
            collapsedShape: const RoundedRectangleBorder(),
            // Do not subscribe to file checks while the section is collapsed.
            children: !_expanded
                ? const []
                : [
                    pageAsync.when(
                      skipLoadingOnRefresh: false,
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => _RetryNotice(
                        message: 'PDF-Nachweise konnten nicht geladen werden.',
                        onRetry: () =>
                            ref.invalidate(evidenceExportPageProvider(request)),
                      ),
                      data: (page) => Column(
                        children: [
                          for (final export in page.exports)
                            _HistoryExportTile(
                              key: ValueKey(export.id),
                              export: export,
                              deleting: widget.deletingExportIds.contains(
                                export.id,
                              ),
                              onOpen: () => widget.onOpen(export),
                              onDelete: () => widget.onDelete(export),
                            ),
                          if (page.totalCount > _pageSize) ...[
                            Text(
                              'Seite ${_offset ~/ _pageSize + 1} von ${(page.totalCount / _pageSize).ceil()}',
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: const ValueKey(
                                      'history-pdfs-previous-page',
                                    ),
                                    onPressed: _offset > 0
                                        ? () => _showPage(_offset - _pageSize)
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                    label: const Text('Zurück'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: const ValueKey(
                                      'history-pdfs-next-page',
                                    ),
                                    onPressed: page.hasMore
                                        ? () => _showPage(_offset + _pageSize)
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                    label: const Text('Weiter'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _HistoryExportTile extends ConsumerWidget {
  const _HistoryExportTile({
    super.key,
    required this.export,
    required this.deleting,
    required this.onOpen,
    required this.onDelete,
  });

  final EvidenceExportRecord export;
  final bool deleting;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(
      evidenceFileAvailableProvider(export.filePath),
    );
    return availability.when(
      skipLoadingOnRefresh: false,
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('PDF-Datei wird geprüft …')),
            ],
          ),
        ),
      ),
      error: (_, _) => Card(
        child: _RetryNotice(
          message:
              'Dateistatus konnte nicht geprüft werden.\nNachweis vom ${formatDateTime(export.createdAt)} Uhr',
          onRetry: () =>
              ref.invalidate(evidenceFileAvailableProvider(export.filePath)),
          onDelete: deleting ? null : onDelete,
        ),
      ),
      data: (available) => EvidenceExportCard(
        export: export,
        title: 'Zählerverlaufsnachweis',
        detail:
            '${export.readingIds.length == 1 ? '1 Ablesung enthalten' : '${export.readingIds.length} Ablesungen enthalten'}\n${export.photoMode.labelFor(export.kind)}',
        fileAvailable: available,
        onTap: available ? onOpen : null,
        deleting: deleting,
        onDelete: onDelete,
      ),
    );
  }
}

class _RetryNotice extends StatelessWidget {
  const _RetryNotice({
    required this.message,
    required this.onRetry,
    this.onDelete,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(message),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Erneut versuchen'),
        ),
        if (onDelete != null)
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('PDF-Nachweis löschen'),
          ),
      ],
    ),
  );
}
