import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../domain/meter_reading_page.dart';
import 'reading_history_tile.dart';

class MeterHistoryScreen extends ConsumerStatefulWidget {
  const MeterHistoryScreen({super.key, required this.meterId});

  final String meterId;

  @override
  ConsumerState<MeterHistoryScreen> createState() => _MeterHistoryScreenState();
}

class _MeterHistoryScreenState extends ConsumerState<MeterHistoryScreen> {
  static const _pageSize = 20;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';
  int _offset = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showPage(int offset) {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() => _offset = offset);
  }

  void _search(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      setState(() {
        _query = value.trim();
        _offset = 0;
      });
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() {
      _query = '';
      _offset = 0;
    });
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('meterDetail', pathParameters: {'id': widget.meterId});
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = (
      meterId: widget.meterId,
      limit: _pageSize,
      offset: _offset,
      query: _query,
    );
    final provider = meterHistoryPageProvider(request);
    final pageAsync = ref.watch(provider);
    final page = pageAsync.value;
    // Deleting the last row on the final page must not strand the user there.
    if (page != null &&
        !pageAsync.isLoading &&
        _offset > 0 &&
        _offset >= page.matchingCount) {
      final lastOffset = page.matchingCount == 0
          ? 0
          : ((page.matchingCount - 1) ~/ _pageSize) * _pageSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _offset == request.offset && _query == request.query) {
          _showPage(lastOffset);
        }
      });
    }
    final meter = ref.watch(meterByIdProvider(widget.meterId)).value;
    return PopScope<void>(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _leave),
          title: const Text('Zählerverlauf'),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (meter != null) ...[
                      Text(
                        meter.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _HistorySearchField(
                      controller: _searchController,
                      onChanged: _search,
                      onClear: _clearSearch,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: pageAsync.when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Ablesungen konnten nicht geladen werden.'),
                        TextButton(
                          onPressed: () => ref.invalidate(provider),
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                  data: (page) => _buildPage(page, request),
                ),
              ),
              if (page != null && page.matchingCount > _pageSize)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      Text(
                        'Seite ${_offset ~/ _pageSize + 1} von ${(page.matchingCount / _pageSize).ceil()}',
                        key: const ValueKey('history-page-number'),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const ValueKey('history-previous-page'),
                              onPressed: !pageAsync.isLoading && _offset > 0
                                  ? () => _showPage(_offset - _pageSize)
                                  : null,
                              child: const Text('Zurück'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              key: const ValueKey('history-next-page'),
                              onPressed: !pageAsync.isLoading && page.hasMore
                                  ? () => _showPage(_offset + _pageSize)
                                  : null,
                              child: const Text('Weiter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(MeterReadingPage page, MeterHistoryPageRequest request) {
    if (page.matchingCount == 0) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _query.isNotEmpty
            ? _EmptyHistorySearch(onClear: _clearSearch)
            : const Center(child: Text('Noch keine Ablesungen vorhanden.')),
      );
    }
    final countLabel = _query.isNotEmpty ? 'Treffern' : 'Ablesungen';
    final resultLabel = page.matchingCount == 1
        ? (_query.isNotEmpty ? '1 Treffer' : '1 Ablesung')
        : '${page.offset + 1}–${page.offset + page.readings.length} von ${page.matchingCount} $countLabel';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            resultLabel,
            key: const ValueKey('history-result-count'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: page.readings.length,
            itemBuilder: (context, index) {
              final reading = page.readings[index];
              final older = index + 1 < page.readings.length
                  ? page.readings[index + 1]
                  : page.olderNeighbor;
              return ReadingHistoryTile(
                reading: reading,
                previous: older,
                showDelta: _query.isEmpty,
                onTap: () async {
                  await context.pushNamed(
                    'readingDetail',
                    pathParameters: {'id': reading.id},
                  );
                  if (!mounted) return;
                  ref.invalidate(meterHistoryPageProvider(request));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistorySearchField extends StatelessWidget {
  const _HistorySearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('history-search-field'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Ablesungen suchen',
        hintText: 'Datum, Zählerstand oder Notiz',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Suche löschen',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _EmptyHistorySearch extends StatelessWidget {
  const _EmptyHistorySearch({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.search_off_outlined, size: 36, color: colors.primary),
            const SizedBox(height: 10),
            const Text(
              'Keine passende Ablesung gefunden.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Suche nach Datum, Zählerstand oder einem Wort aus der Notiz.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              label: const Text('Suche löschen'),
            ),
          ],
        ),
      ),
    );
  }
}
