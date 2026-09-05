import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/app_snack_bar.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../domain/meter.dart';
import 'meter_unit_field.dart';

typedef _MeterFormSnapshot = ({
  MeterType type,
  String label,
  String meterNumber,
  String location,
  String unit,
  bool reminderEnabled,
  ReminderInterval? interval,
  int? day,
  int? month,
  int? hour,
  int? minute,
  ReminderDeliveryMode? deliveryMode,
});

class MeterFormScreen extends ConsumerWidget {
  const MeterFormScreen({super.key, this.meterId});

  final String? meterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = meterId;
    if (id == null) {
      return const _MeterForm();
    }
    return ref
        .watch(meterByIdProvider(id))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const Scaffold(
            body: Center(child: Text('Zähler konnte nicht geladen werden.')),
          ),
          data: (meter) => meter == null
              ? const Scaffold(
                  body: Center(child: Text('Zähler nicht gefunden.')),
                )
              : _MeterForm(meter: meter),
        );
  }
}

class _MeterForm extends ConsumerStatefulWidget {
  const _MeterForm({this.meter});

  final Meter? meter;

  @override
  ConsumerState<_MeterForm> createState() => _MeterFormState();
}

class _MeterFormState extends ConsumerState<_MeterForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _number;
  late final TextEditingController _location;
  late MeterType _type;
  late String _unit;
  late bool _reminderEnabled;
  late ReminderInterval _interval;
  late int _dayOfMonth;
  late int _weekday;
  late int _month;
  late TimeOfDay _time;
  late ReminderDeliveryMode _deliveryMode;
  late final _MeterFormSnapshot _initialSnapshot;
  bool _saving = false;
  bool _testingSound = false;
  bool _discardDialogOpen = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    final meter = widget.meter;
    _type = meter?.type ?? MeterType.electricity;
    _label = TextEditingController(text: meter?.label ?? '');
    _number = TextEditingController(text: meter?.meterNumber ?? '');
    _location = TextEditingController(text: meter?.location ?? '');
    final savedUnit = meter?.unit.trim();
    _unit = savedUnit == null || savedUnit.isEmpty
        ? _type.defaultUnit
        : savedUnit;
    final reminder = meter?.reminder;
    final now = DateTime.now();
    _reminderEnabled = reminder != null;
    _interval = reminder?.interval ?? ReminderInterval.monthly;
    if (!kDebugMode && _interval == ReminderInterval.minutely) {
      _interval = ReminderInterval.daily;
    }
    _dayOfMonth =
        reminder != null &&
            (reminder.interval == ReminderInterval.monthly ||
                reminder.interval == ReminderInterval.yearly)
        ? reminder.day.clamp(1, 28)
        : now.day.clamp(1, 28);
    _weekday = reminder?.interval == ReminderInterval.weekly
        ? reminder!.day.clamp(DateTime.monday, DateTime.sunday)
        : now.weekday;
    _month = reminder?.month ?? now.month;
    _time = TimeOfDay(hour: reminder?.hour ?? 9, minute: reminder?.minute ?? 0);
    _deliveryMode = reminder?.deliveryMode ?? ReminderDeliveryMode.normal;
    _initialSnapshot = _snapshot();
    _label.addListener(_handleTextChanged);
    _number.addListener(_handleTextChanged);
    _location.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _label.removeListener(_handleTextChanged);
    _number.removeListener(_handleTextChanged);
    _location.removeListener(_handleTextChanged);
    _label.dispose();
    _number.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.meter != null;
    final hasUnsavedChanges = _hasUnsavedChanges;
    return PopScope<void>(
      canPop: _allowPop || !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBack),
          title: Text(editing ? 'Zähler bearbeiten' : 'Zähler anlegen'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              DropdownButtonFormField<MeterType>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Zählerart'),
                items: [
                  for (final type in MeterType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _type = value;
                    _unit = value.defaultUnit;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _label,
                decoration: const InputDecoration(
                  labelText: 'Bezeichnung *',
                  hintText: 'z. B. Strom Hauptzähler',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Bitte eine Bezeichnung eingeben.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _number,
                decoration: const InputDecoration(labelText: 'Zählernummer'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Standort',
                  hintText: 'z. B. Keller',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              MeterUnitField(
                meterType: _type,
                value: _unit,
                labelText: 'Einheit *',
                enabled: !_saving,
                onChanged: (value) => setState(() => _unit = value),
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ableseerinnerung'),
                        subtitle: const Text(
                          'Optional und nur lokal auf diesem Gerät',
                        ),
                        value: _reminderEnabled,
                        onChanged: (value) =>
                            setState(() => _reminderEnabled = value),
                      ),
                      if (_reminderEnabled) ...[
                        const Divider(),
                        DropdownButtonFormField<ReminderInterval>(
                          initialValue: _interval,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Intervall',
                          ),
                          items: [
                            for (final interval in ReminderInterval.values)
                              if (kDebugMode ||
                                  interval != ReminderInterval.minutely)
                                DropdownMenuItem(
                                  value: interval,
                                  child: Text(interval.label),
                                ),
                          ],
                          onChanged: (value) =>
                              setState(() => _interval = value ?? _interval),
                        ),
                        const SizedBox(height: 12),
                        if (_interval == ReminderInterval.yearly)
                          DropdownButtonFormField<int>(
                            initialValue: _month,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Monat',
                            ),
                            items: [
                              for (var month = 1; month <= 12; month++)
                                DropdownMenuItem(
                                  value: month,
                                  child: Text(month.toString()),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _month = value ?? _month),
                          ),
                        if (_interval == ReminderInterval.yearly)
                          const SizedBox(height: 12),
                        if (_interval == ReminderInterval.weekly) ...[
                          DropdownButtonFormField<int>(
                            initialValue: _weekday,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Wochentag',
                            ),
                            items: [
                              for (
                                var weekday = DateTime.monday;
                                weekday <= DateTime.sunday;
                                weekday++
                              )
                                DropdownMenuItem(
                                  value: weekday,
                                  child: Text(reminderWeekdayLabel(weekday)),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _weekday = value ?? _weekday),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_interval == ReminderInterval.monthly ||
                            _interval == ReminderInterval.yearly) ...[
                          DropdownButtonFormField<int>(
                            initialValue: _dayOfMonth,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Tag'),
                            items: [
                              for (var day = 1; day <= 28; day++)
                                DropdownMenuItem(
                                  value: day,
                                  child: Text('$day.'),
                                ),
                            ],
                            onChanged: (value) => setState(
                              () => _dayOfMonth = value ?? _dayOfMonth,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_interval == ReminderInterval.minutely) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.science_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Dev-Modus: Die nächste Erinnerung wird zum Beginn der nächsten Minute geplant. Normale Erinnerungen kann Android verzögern.',
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Uhrzeit',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  _time.format(context),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _pickReminderTime,
                              icon: const Icon(Icons.schedule_outlined),
                              label: const Text('Uhrzeit ändern'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Art der Erinnerung',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ReminderModeCard(
                          title: 'Normale Erinnerung',
                          description:
                              'Android darf die Meldung etwas später anzeigen. „Nicht stören“ wird respektiert.',
                          icon: Icons.notifications_outlined,
                          selected:
                              _deliveryMode == ReminderDeliveryMode.normal,
                          onTap: _saving
                              ? null
                              : () => _selectDeliveryMode(
                                  ReminderDeliveryMode.normal,
                                ),
                        ),
                        const SizedBox(height: 8),
                        _ReminderModeCard(
                          title: 'Pünktlich mit Ton',
                          description:
                              'Wird möglichst genau zur gewählten Uhrzeit wie ein Alarm ausgelöst.',
                          icon: Icons.alarm_outlined,
                          selected:
                              _deliveryMode ==
                              ReminderDeliveryMode.punctualWithSound,
                          onTap: _saving
                              ? null
                              : () => _selectDeliveryMode(
                                  ReminderDeliveryMode.punctualWithSound,
                                ),
                        ),
                        if (_deliveryMode ==
                            ReminderDeliveryMode.punctualWithSound) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _saving || _testingSound
                                  ? null
                                  : _testAlarmSound,
                              icon: _testingSound
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.volume_up_outlined),
                              label: const Text('Ton jetzt testen'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Der Test verschwindet nach zehn Sekunden und zählt nicht als Zählererinnerung.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _saving || !hasUnsavedChanges ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    editing && !hasUnsavedChanges
                        ? Icons.check_circle_outline
                        : Icons.save_outlined,
                  ),
            label: Text(
              _saving
                  ? 'Wird gespeichert …'
                  : editing && !hasUnsavedChanges
                  ? 'Alles gespeichert'
                  : editing
                  ? 'Änderungen speichern'
                  : 'Zähler speichern',
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasUnsavedChanges => _snapshot() != _initialSnapshot;

  _MeterFormSnapshot _snapshot() {
    final interval = _reminderEnabled ? _interval : null;
    return (
      type: _type,
      label: _label.text.trim(),
      meterNumber: _number.text.trim(),
      location: _location.text.trim(),
      unit: _unit.trim(),
      reminderEnabled: _reminderEnabled,
      interval: interval,
      day: switch (interval) {
        ReminderInterval.weekly => _weekday,
        ReminderInterval.monthly || ReminderInterval.yearly => _dayOfMonth,
        ReminderInterval.minutely || ReminderInterval.daily || null => null,
      },
      month: interval == ReminderInterval.yearly ? _month : null,
      hour: interval == null || interval == ReminderInterval.minutely
          ? null
          : _time.hour,
      minute: interval == null || interval == ReminderInterval.minutely
          ? null
          : _time.minute,
      deliveryMode: interval == null ? null : _deliveryMode,
    );
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleBack() async {
    if (_saving || _discardDialogOpen) return;
    FocusScope.of(context).unfocus();
    if (!_hasUnsavedChanges) {
      _leaveForm();
      return;
    }

    _discardDialogOpen = true;
    final editing = widget.meter != null;
    final discard = await confirmDiscardChanges(
      context,
      title: editing ? 'Änderungen verwerfen?' : 'Eingaben verwerfen?',
      message: editing
          ? 'Deine Änderungen an diesem Zähler wurden noch nicht gespeichert.'
          : 'Deine Eingaben für den neuen Zähler wurden noch nicht gespeichert.',
      discardLabel: editing ? 'Änderungen verwerfen' : 'Eingaben verwerfen',
    );
    _discardDialogOpen = false;
    if (!mounted || !discard) return;
    await _leaveWithoutGuard();
  }

  Future<void> _leaveWithoutGuard() async {
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) _leaveForm();
  }

  void _leaveForm() {
    if (context.canPop()) {
      context.pop();
    } else if (widget.meter case final meter?) {
      context.goNamed('meterDetail', pathParameters: {'id': meter.id});
    } else {
      context.goNamed('home');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminderEnabled &&
        _deliveryMode == ReminderDeliveryMode.punctualWithSound &&
        !await ref
            .read(meterReminderRepositoryProvider)
            .canScheduleExactAlarms()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          message:
              'Für „Pünktlich mit Ton“ fehlt die Android-Berechtigung. Bitte den Modus erneut auswählen und erlauben.',
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final reminder = _reminderEnabled
        ? ReadingReminderSchedule(
            interval: _interval,
            day: switch (_interval) {
              ReminderInterval.weekly => _weekday,
              ReminderInterval.monthly ||
              ReminderInterval.yearly => _dayOfMonth,
              ReminderInterval.minutely || ReminderInterval.daily => 1,
            },
            month: _interval == ReminderInterval.yearly ? _month : null,
            hour: _time.hour,
            minute: _time.minute,
            deliveryMode: _deliveryMode,
          )
        : null;
    try {
      final service = ref.read(meterServiceProvider);
      final existing = widget.meter;
      late final Meter meter;
      if (existing == null) {
        meter = await service.create(
          label: _label.text,
          type: _type,
          unit: _unit,
          meterNumber: _number.text,
          location: _location.text,
          reminder: reminder,
        );
      } else {
        meter = existing.copyWith(
          label: _label.text.trim(),
          type: _type,
          unit: _unit,
          meterNumber: _number.text.trim(),
          location: _location.text.trim(),
          reminder: reminder,
          clearReminder: reminder == null,
        );
        await service.update(meter);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (existing == null) {
        setState(() => _allowPop = true);
        context.pushReplacementNamed(
          'meterDetail',
          pathParameters: {'id': meter.id},
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              AppSnackBar(
                message:
                    'Zähler gespeichert. Das Ablesen des Zählerstands folgt im nächsten Schritt.',
              ),
            );
        });
      } else {
        ref.invalidate(meterByIdProvider(meter.id));
        await _leaveWithoutGuard();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar(message: 'Speichern fehlgeschlagen: $error'));
      setState(() => _saving = false);
    }
  }

  Future<void> _pickReminderTime() async {
    FocusScope.of(context).unfocus();
    final value = await showTimePicker(context: context, initialTime: _time);
    if (value != null && mounted) setState(() => _time = value);
  }

  Future<void> _selectDeliveryMode(ReminderDeliveryMode mode) async {
    if (mode == ReminderDeliveryMode.normal) {
      setState(() => _deliveryMode = mode);
      return;
    }
    final reminders = ref.read(meterReminderRepositoryProvider);
    if (await reminders.canScheduleExactAlarms()) {
      if (mounted) setState(() => _deliveryMode = mode);
      return;
    }
    await reminders.requestExactAlarmPermission();
    if (!mounted) return;
    if (await reminders.canScheduleExactAlarms()) {
      if (!mounted) return;
      setState(() => _deliveryMode = mode);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar(
        message:
            'Erlaube „Alarme & Erinnerungen“ in Android und tippe danach erneut auf „Pünktlich mit Ton“.',
      ),
    );
  }

  Future<void> _testAlarmSound() async {
    setState(() => _testingSound = true);
    final reminders = ref.read(meterReminderRepositoryProvider);
    await reminders.showAlarmTest();
    if (!mounted) return;
    setState(() => _testingSound = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(AppSnackBar(message: 'Test-Erinnerung wurde ausgelöst.'));
  }
}

class _ReminderModeCard extends StatelessWidget {
  const _ReminderModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? scheme.primary : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(description),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
