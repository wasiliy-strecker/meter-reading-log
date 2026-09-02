import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../domain/meter.dart';
import '../domain/meter_reading.dart';
import 'meter_visuals.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meters = ref.watch(metersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Einstellungen',
            onPressed: () => context.pushNamed('settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: meters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _ErrorState(onRetry: () => ref.invalidate(metersProvider)),
        data: (items) =>
            items.isEmpty ? const _EmptyState() : _MeterList(meters: items),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('meterNew'),
        icon: const Icon(Icons.add),
        label: const Text('Zähler anlegen'),
      ),
    );
  }
}

enum _MeterSort { lastEdited, name, type }

extension on _MeterSort {
  String get label => switch (this) {
    _MeterSort.lastEdited => 'Zuletzt bearbeitet',
    _MeterSort.name => 'Name A–Z',
    _MeterSort.type => 'Zählerart',
  };
}

class _MeterList extends ConsumerStatefulWidget {
  const _MeterList({required this.meters});

  final List<Meter> meters;

  @override
  ConsumerState<_MeterList> createState() => _MeterListState();
}

class _MeterListState extends ConsumerState<_MeterList> {
  final _search = TextEditingController();
  _MeterSort _sort = _MeterSort.lastEdited;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final entries = widget.meters
        .map((meter) {
          final readings =
              ref.watch(readingsForMeterProvider(meter.id)).value ?? const [];
          return _MeterListEntry(meter: meter, readings: readings);
        })
        .where((entry) => entry.matches(query))
        .toList();
    entries.sort(
      (left, right) => switch (_sort) {
        _MeterSort.lastEdited => right.lastEdited.compareTo(left.lastEdited),
        _MeterSort.name => left.meter.label.toLowerCase().compareTo(
          right.meter.label.toLowerCase(),
        ),
        _MeterSort.type => left.meter.type.label.compareTo(
          right.meter.type.label,
        ),
      },
    );

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Text(
          'Deine Zähler',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Fotografieren, lokal erkennen und nachvollziehbar dokumentieren.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: 'Zähler suchen',
            hintText: 'Name, Art, Nummer, Standort oder Einheit',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Suche löschen',
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                query.isEmpty
                    ? '${entries.length} Zähler'
                    : '${entries.length} Treffer',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            MenuAnchor(
              builder: (context, controller, _) => OutlinedButton.icon(
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                icon: const Icon(Icons.sort, size: 19),
                label: Text(_sort.label),
              ),
              menuChildren: [
                for (final option in _MeterSort.values)
                  MenuItemButton(
                    leadingIcon: option == _sort
                        ? const Icon(Icons.check)
                        : const SizedBox(width: 24),
                    onPressed: () => setState(() => _sort = option),
                    child: Text(option.label),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const _NoSearchResults()
        else
          for (final entry in entries)
            _MeterCard(meter: entry.meter, readings: entry.readings),
      ],
    );
  }
}

class _MeterListEntry {
  const _MeterListEntry({required this.meter, required this.readings});

  final Meter meter;
  final List<MeterReading> readings;

  MeterReading? get latestReading {
    if (readings.isEmpty) return null;
    return readings.reduce(
      (left, right) => left.capturedAt.isAfter(right.capturedAt) ? left : right,
    );
  }

  DateTime get lastEdited => readings.fold<DateTime>(
    meter.updatedAt,
    (latest, reading) =>
        reading.updatedAt.isAfter(latest) ? reading.updatedAt : latest,
  );

  bool matches(String query) {
    if (query.isEmpty) return true;
    final latest = latestReading;
    return [
      meter.label,
      meter.type.label,
      meter.meterNumber,
      meter.location,
      meter.unit,
      if (latest != null) latest.value.displayText,
    ].any((value) => value.toLowerCase().contains(query));
  }
}

class _MeterCard extends StatelessWidget {
  const _MeterCard({required this.meter, required this.readings});

  final Meter meter;
  final List<MeterReading> readings;

  @override
  Widget build(BuildContext context) {
    final entry = _MeterListEntry(meter: meter, readings: readings);
    final latest = entry.latestReading;
    final color = meterColor(meter.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () =>
            context.pushNamed('meterDetail', pathParameters: {'id': meter.id}),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(meterIcon(meter.type)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meter.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        meter.type.label,
                        if (meter.location.isNotEmpty) meter.location,
                      ].join(' · '),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      latest == null
                          ? 'Noch keine Ablesung'
                          : '${latest.value.displayText} ${latest.meter.unit}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zuletzt bearbeitet: ${formatDateTime(entry.lastEdited)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            const Text(
              'Keine passenden Zähler gefunden.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.speed_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Ersten Zähler anlegen',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lege Strom-, Gas-, Wasser-, Wärme- oder weitere Haushaltszähler an. Fotos und OCR-Daten bleiben lokal auf deinem Gerät.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Erneut laden'),
      ),
    );
  }
}
