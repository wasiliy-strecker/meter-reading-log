import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../core/reminders/local_notification_reminder_repository.dart';
import '../../../core/utils/formatters.dart';
import '../domain/meter.dart';
import '../domain/meter_dashboard_item.dart';
import 'meter_visuals.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(meterReminderRepositoryProvider).refreshStatuses();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(meterReminderRepositoryProvider).refreshStatuses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardItems = ref.watch(meterDashboardItemsProvider);
    final reminderStatuses =
        ref.watch(reminderStatusesProvider).value ?? const {};
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
      body: dashboardItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(meterDashboardItemsProvider),
        ),
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : _MeterList(items: items, reminderStatuses: reminderStatuses),
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
  const _MeterList({required this.items, required this.reminderStatuses});

  final List<MeterDashboardItem> items;
  final Map<String, ReminderStatus> reminderStatuses;

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
    final entries = widget.items
        .where((entry) => _matches(entry, query))
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

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: entries.isEmpty ? 1 : entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Deine Zähler',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
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
              if (entries.isEmpty) const _NoSearchResults(),
            ],
          );
        }
        final entry = entries[index - 1];
        return _MeterCard(
          item: entry,
          reminderStatus: widget.reminderStatuses[entry.meter.id],
          onTap: () => _openMeter(
            entry.meter.id,
            widget.reminderStatuses[entry.meter.id],
          ),
        );
      },
    );
  }

  bool _matches(MeterDashboardItem entry, String query) {
    if (query.isEmpty) return true;
    return [
      entry.meter.label,
      entry.meter.type.label,
      entry.meter.meterNumber,
      entry.meter.location,
      entry.meter.unit,
      if (entry.latestValue != null) entry.latestValue!.displayText,
    ].any((value) => value.toLowerCase().contains(query));
  }

  Future<void> _openMeter(
    String meterId,
    ReminderStatus? reminderStatus,
  ) async {
    if (reminderStatus?.isNotificationActive ?? false) {
      try {
        await ref.read(meterReminderRepositoryProvider).acknowledge(meterId);
      } on Object {
        // Opening the meter must not be blocked by a platform notification.
      }
      ref.invalidate(reminderStatusesProvider);
    }
    if (!mounted) return;
    context.pushNamed('meterDetail', pathParameters: {'id': meterId});
  }
}

class _MeterCard extends StatelessWidget {
  const _MeterCard({
    required this.item,
    required this.onTap,
    this.reminderStatus,
  });

  final MeterDashboardItem item;
  final ReminderStatus? reminderStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meter = item.meter;
    final color = meterColor(meter.type);
    final reminder = meter.reminder;
    final nextReminder = reminder == null
        ? null
        : nextReminderDate(reminder, DateTime.now());
    return Card(
      key: ValueKey('dashboard-meter-${meter.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Badge(
                isLabelVisible: reminderStatus?.isNotificationActive ?? false,
                label: const Text('1'),
                child: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  foregroundColor: color,
                  child: Icon(meterIcon(meter.type)),
                ),
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
                      item.latestValue == null
                          ? 'Noch keine Ablesung'
                          : '${item.latestValue!.displayText} ${item.latestUnit ?? meter.unit}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zuletzt bearbeitet: ${formatDateTime(item.lastEdited)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (reminder != null && nextReminder != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Erinnern: ${_reminderSummary(reminder)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        key: ValueKey('next-reminder-${meter.id}'),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 20,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nächste Erinnerung',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    '${formatDateTime(nextReminder)} Uhr',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 19,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reminderStatus?.lastTriggeredAt == null
                                    ? 'Letzte Erinnerung: noch keine'
                                    : 'Letzte Erinnerung: ${formatDateTime(reminderStatus!.lastTriggeredAt!)} Uhr',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

String _reminderSummary(ReadingReminderSchedule reminder) {
  final time =
      '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')} Uhr';
  final schedule = switch (reminder.interval) {
    ReminderInterval.minutely => 'minütlich (Dev)',
    ReminderInterval.daily => 'täglich um $time',
    ReminderInterval.weekly =>
      'wöchentlich am ${reminderWeekdayLabel(reminder.day)} um $time',
    ReminderInterval.monthly => 'monatlich am ${reminder.day}. um $time',
    ReminderInterval.yearly =>
      'jährlich am ${reminder.day}.${(reminder.month ?? 1).toString().padLeft(2, '0')}. um $time',
  };
  return reminder.deliveryMode == ReminderDeliveryMode.punctualWithSound
      ? '$schedule · pünktlich mit Ton'
      : schedule;
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
              'Lege Strom-, Gas-, Wasser-, Wärme- oder weitere Haushaltszähler an. Die gesamte Verarbeitung findet lokal auf deinem Gerät statt. Deine Fotos und Zählerdaten werden von der App nicht an einen Server gesendet.',
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
