import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../domain/meter_reading.dart';
import '../domain/reading_value.dart';

class EditReadingScreen extends ConsumerWidget {
  const EditReadingScreen({super.key, required this.readingId});

  final String readingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(readingByIdProvider(readingId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const Scaffold(
            body: Center(child: Text('Ablesung konnte nicht geladen werden.')),
          ),
          data: (reading) => reading == null
              ? const Scaffold(
                  body: Center(child: Text('Ablesung nicht gefunden.')),
                )
              : _EditReadingForm(reading: reading),
        );
  }
}

class _EditReadingForm extends ConsumerStatefulWidget {
  const _EditReadingForm({required this.reading});

  final MeterReading reading;

  @override
  ConsumerState<_EditReadingForm> createState() => _EditReadingFormState();
}

class _EditReadingFormState extends ConsumerState<_EditReadingForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _value;
  late final TextEditingController _note;
  final _reason = TextEditingController();
  late DateTime _capturedAt;
  LowerReadingReason? _lowerReason;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(text: widget.reading.value.displayText);
    _note = TextEditingController(text: widget.reading.note);
    _capturedAt = widget.reading.capturedAt.toLocal();
    _lowerReason = widget.reading.lowerReadingReason;
  }

  @override
  void dispose() {
    _value.dispose();
    _note.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readings =
        ref.watch(readingsForMeterProvider(widget.reading.meterId)).value ??
        const [];
    final parsed = ReadingValue.tryParse(_value.text);
    final previous = readings
        .where(
          (item) =>
              item.id != widget.reading.id &&
              item.capturedAt.isBefore(_capturedAt.toUtc()),
        )
        .fold<MeterReading?>(
          null,
          (latest, item) =>
              latest == null || item.capturedAt.isAfter(latest.capturedAt)
              ? item
              : latest,
        );
    final isLower =
        parsed != null &&
        previous != null &&
        parsed.compareTo(previous.value) < 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Ablesung korrigieren')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Korrekturen überschreiben den ursprünglichen Eintrag nicht. Alter und neuer Inhalt sowie der Grund bleiben im Änderungsprotokoll erhalten.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _value,
              decoration: InputDecoration(
                labelText: 'Zählerstand *',
                suffixText: widget.reading.meter.unit,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) => ReadingValue.tryParse(value ?? '') == null
                  ? 'Bitte einen gültigen Zählerstand eingeben.'
                  : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aufnahmezeit'),
              subtitle: Text(formatDateTime(_capturedAt)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
            if (isLower) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<LowerReadingReason>(
                initialValue: _lowerReason,
                decoration: const InputDecoration(
                  labelText: 'Grund für niedrigeren Stand *',
                ),
                items: [
                  for (final reason in LowerReadingReason.values)
                    DropdownMenuItem(value: reason, child: Text(reason.label)),
                ],
                onChanged: (value) => setState(() => _lowerReason = value),
                validator: (value) => isLower && value == null
                    ? 'Bitte den niedrigeren Stand begründen.'
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Notiz'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Grund der Korrektur *',
                hintText: 'z. B. Tippfehler beim Bestätigen',
              ),
              maxLines: 2,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Bitte den Korrekturgrund angeben.'
                  : null,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Korrektur protokollieren'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _capturedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_capturedAt),
    );
    if (time != null) {
      setState(() {
        _capturedAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(meterReadingServiceProvider)
          .update(
            existing: widget.reading,
            value: ReadingValue.tryParse(_value.text)!,
            capturedAt: _capturedAt,
            note: _note.text,
            reason: _reason.text,
            lowerReadingReason: _lowerReason,
          );
      ref.invalidate(readingByIdProvider(widget.reading.id));
      ref.invalidate(revisionsForReadingProvider(widget.reading.id));
      if (mounted) {
        context.goNamed('readingDetail', pathParameters: {'id': updated.id});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Korrektur fehlgeschlagen: $error')),
        );
        setState(() => _saving = false);
      }
    }
  }
}
