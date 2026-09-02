import 'dart:async';
import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../core/files/meter_photo_repository.dart';
import '../../../core/ocr/meter_ocr_repository.dart';
import '../../../core/utils/formatters.dart';
import '../domain/meter.dart';
import '../domain/meter_reading.dart';
import '../domain/reading_value.dart';
import 'editable_reading_time_card.dart';

class CaptureReadingScreen extends ConsumerStatefulWidget {
  const CaptureReadingScreen({super.key, required this.meterId});

  final String meterId;

  @override
  ConsumerState<CaptureReadingScreen> createState() =>
      _CaptureReadingScreenState();
}

class _CaptureReadingScreenState extends ConsumerState<CaptureReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _note = TextEditingController();
  StoredMeterPhoto? _photo;
  MeterOcrResult? _ocr;
  String _selectedCandidate = '';
  String? _selectedUnit;
  DateTime _capturedAt = DateTime.now();
  LowerReadingReason? _lowerReason;
  bool _working = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostCapture());
  }

  @override
  void dispose() {
    if (!_saved && _photo != null) {
      unawaited(
        ref.read(meterPhotoCaptureRepositoryProvider).delete(_photo!.path),
      );
    }
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(meterByIdProvider(widget.meterId))
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
              : _buildContent(meter),
        );
  }

  Widget _buildContent(Meter meter) {
    final readings =
        ref.watch(readingsForMeterProvider(meter.id)).value ?? const [];
    final selectedUnit = _selectedUnit ?? meter.unit;
    final parsed = ReadingValue.tryParse(_value.text);
    final previous = _previousFor(readings, _capturedAt, selectedUnit);
    final isLower =
        parsed != null &&
        previous != null &&
        parsed.compareTo(previous.value) < 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Ablesen / Fotografieren')),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (_photo == null) ...[
              const _CaptureGuidance(),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _working
                    ? null
                    : () => _capture(ReadingSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Zähler fotografieren'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _working
                    ? null
                    : () => _capture(ReadingSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Foto aus Galerie'),
              ),
              if (_working) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                const Center(child: Text('Foto wird lokal ausgewertet …')),
              ],
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    File(_photo!.path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Colors.black12,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_photo!.source.label} · Original SHA-256 ${shortHash(_photo!.sha256)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _working ? null : _replacePhoto,
                  icon: const Icon(Icons.change_circle_outlined),
                  label: const Text('Neues Foto aufnehmen oder auswählen'),
                ),
              ),
              const SizedBox(height: 12),
              if (_ocr != null && _ocr!.candidates.isNotEmpty) ...[
                Text(
                  'Erkannte Werte',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final candidate in _ocr!.candidates)
                      ChoiceChip(
                        label: Text(candidate.rawText),
                        selected: _selectedCandidate == candidate.rawText,
                        onSelected: (_) {
                          setState(() {
                            _selectedCandidate = candidate.rawText;
                            _value.text = candidate.value.displayText;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ] else if (_ocr != null) ...[
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Kein sicherer Wert erkannt'),
                    subtitle: Text('Bitte den Zählerstand manuell eintragen.'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                key: ValueKey('reading-unit-${meter.id}-$selectedUnit'),
                initialValue: selectedUnit,
                decoration: InputDecoration(
                  labelText: 'Einheit des Zählerstands',
                  helperText: meterUnitDescription(selectedUnit),
                  prefixIcon: const Icon(Icons.straighten_outlined),
                ),
                items: [
                  for (final unit in _unitOptions(meter, selectedUnit))
                    DropdownMenuItem(value: unit, child: Text(unit)),
                ],
                onChanged: _working
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedUnit = value;
                          _lowerReason = null;
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _value,
                decoration: InputDecoration(
                  labelText: 'Bestätigter Zählerstand *',
                  suffixText: selectedUnit,
                  helperText: 'Bitte immer mit dem Foto vergleichen.',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                validator: (value) => ReadingValue.tryParse(value ?? '') == null
                    ? 'Bitte einen gültigen Zählerstand eingeben.'
                    : null,
              ),
              const SizedBox(height: 12),
              EditableReadingTimeCard(
                value: _capturedAt,
                onPressed: _pickCapturedAt,
              ),
              if (isLower) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<LowerReadingReason>(
                  initialValue: _lowerReason,
                  decoration: InputDecoration(
                    labelText: 'Grund für niedrigeren Stand *',
                    helperText:
                        'Vorheriger Stand: ${previous.value.displayText} $selectedUnit',
                  ),
                  items: [
                    for (final reason in LowerReadingReason.values)
                      DropdownMenuItem(
                        value: reason,
                        child: Text(reason.label),
                      ),
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
                decoration: const InputDecoration(
                  labelText: 'Notiz',
                  hintText: 'Optional, z. B. Wohnungsübergabe',
                ),
                maxLines: 3,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _working ? null : () => _save(meter),
                icon: _working
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined),
                label: const Text('Ablesung bestätigen und speichern'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  MeterReading? _previousFor(
    List<MeterReading> readings,
    DateTime capturedAt,
    String unit,
  ) {
    final earlier =
        readings
            .where(
              (reading) =>
                  reading.meter.unit == unit &&
                  reading.capturedAt.isBefore(capturedAt.toUtc()),
            )
            .toList()
          ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return earlier.firstOrNull;
  }

  Future<void> _capture(ReadingSource source) async {
    setState(() => _working = true);
    try {
      final photo = await ref
          .read(meterPhotoCaptureRepositoryProvider)
          .capture(source);
      if (photo == null || !mounted) return;
      await _processPhoto(photo);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto konnte nicht verarbeitet werden: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _recoverLostCapture() async {
    try {
      final photo = await ref
          .read(meterPhotoCaptureRepositoryProvider)
          .recoverLostCapture();
      if (photo != null && mounted) await _processPhoto(photo);
    } on Object {
      return;
    }
  }

  Future<void> _processPhoto(StoredMeterPhoto photo) async {
    final old = _photo;
    final ocr = await ref
        .read(meterOcrRepositoryProvider)
        .recognize(photo.path);
    if (old != null) {
      await ref.read(meterPhotoCaptureRepositoryProvider).delete(old.path);
    }
    final first = ocr.candidates.firstOrNull;
    setState(() {
      _photo = photo;
      _ocr = ocr;
      _capturedAt = photo.capturedAt;
      _selectedCandidate = first?.rawText ?? '';
      _value.text = first?.value.displayText ?? '';
    });
  }

  Future<void> _replacePhoto() async {
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<ReadingSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Neu fotografieren'),
              onTap: () => Navigator.pop(context, ReadingSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Aus Galerie wählen'),
              onTap: () => Navigator.pop(context, ReadingSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _capture(source);
  }

  Future<void> _pickCapturedAt() async {
    FocusScope.of(context).unfocus();
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
    if (time == null) return;
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

  Future<void> _save(Meter meter) async {
    if (!_formKey.currentState!.validate() || _photo == null || _ocr == null) {
      return;
    }
    final value = ReadingValue.tryParse(_value.text)!;
    final selectedUnit = _selectedUnit ?? meter.unit;
    setState(() => _working = true);
    try {
      var meterForReading = meter;
      if (selectedUnit != meter.unit) {
        meterForReading = meter.copyWith(unit: selectedUnit);
        await ref.read(meterServiceProvider).update(meterForReading);
      }
      final reading = await ref
          .read(meterReadingServiceProvider)
          .create(
            meter: meterForReading,
            photo: _photo!,
            ocr: _ocr!,
            value: value,
            selectedCandidate: _selectedCandidate,
            capturedAt: _capturedAt,
            note: _note.text,
            lowerReadingReason: _lowerReason,
          );
      if (selectedUnit != meter.unit) {
        ref.invalidate(meterByIdProvider(meter.id));
      }
      _saved = true;
      if (!mounted) return;
      context.goNamed('readingDetail', pathParameters: {'id': reading.id});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speichern fehlgeschlagen: $error')),
        );
        setState(() => _working = false);
      }
    }
  }

  List<String> _unitOptions(Meter meter, String selectedUnit) {
    final options = [...meter.type.availableUnits];
    if (!options.contains(selectedUnit)) options.add(selectedUnit);
    return options;
  }
}

class _CaptureGuidance extends StatelessWidget {
  const _CaptureGuidance();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Für eine gute Erkennung',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text('• Anzeige möglichst gerade und vollständig aufnehmen'),
            const Text('• Spiegelungen und Schatten vermeiden'),
            const Text('• Zählernummer nach Möglichkeit mitfotografieren'),
            const SizedBox(height: 10),
            Text(
              'Das Originalfoto wird unverändert lokal gespeichert. Der erkannte Wert muss vor dem Speichern bestätigt werden.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
