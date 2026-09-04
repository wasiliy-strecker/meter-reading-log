import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/app_snack_bar.dart';
import '../domain/meter.dart';
import 'meter_unit_field.dart';

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
  bool _saving = false;

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
  }

  @override
  void dispose() {
    _label.dispose();
    _number.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.meter != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Zähler bearbeiten' : 'Zähler anlegen'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            DropdownButtonFormField<MeterType>(
              initialValue: _type,
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
                        decoration: const InputDecoration(
                          labelText: 'Intervall',
                        ),
                        items: [
                          for (final interval in ReminderInterval.values)
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
                          decoration: const InputDecoration(labelText: 'Monat'),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                editing ? 'Änderungen speichern' : 'Zähler speichern',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final reminder = _reminderEnabled
        ? ReadingReminderSchedule(
            interval: _interval,
            day: switch (_interval) {
              ReminderInterval.weekly => _weekday,
              ReminderInterval.monthly ||
              ReminderInterval.yearly => _dayOfMonth,
              ReminderInterval.daily => 1,
            },
            month: _interval == ReminderInterval.yearly ? _month : null,
            hour: _time.hour,
            minute: _time.minute,
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
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed('meterDetail', pathParameters: {'id': meter.id});
        }
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
}
