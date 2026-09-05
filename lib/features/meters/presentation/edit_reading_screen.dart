import 'dart:async';

import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/app_snack_bar.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../../../core/files/meter_photo_repository.dart';
import '../../../core/ocr/meter_ocr_repository.dart';
import '../domain/meter_reading.dart';
import '../domain/reading_value.dart';
import 'editable_reading_time_card.dart';

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
  late final MeterPhotoCaptureRepository _photos;
  late final MeterOcrRepository _ocrRepository;
  late DateTime _capturedAt;
  LowerReadingReason? _lowerReason;
  StoredMeterPhoto? _replacementPhoto;
  MeterOcrResult? _replacementOcr;
  String _selectedCandidate = '';
  bool _processingPhoto = false;
  bool _saving = false;
  bool _saved = false;
  bool _discardDialogOpen = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _photos = ref.read(meterPhotoCaptureRepositoryProvider);
    _ocrRepository = ref.read(meterOcrRepositoryProvider);
    _value = TextEditingController(text: widget.reading.value.displayText);
    _note = TextEditingController(text: widget.reading.note);
    _capturedAt = widget.reading.capturedAt.toLocal();
    _lowerReason = widget.reading.lowerReadingReason;
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostCapture());
  }

  @override
  void dispose() {
    if (!_saved && _replacementPhoto != null) {
      unawaited(_photos.delete(_replacementPhoto!.path));
    }
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
              item.meter.unit == widget.reading.meter.unit &&
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
    final scaffold = Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _handleBack),
        title: const Text('Ablesung korrigieren'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Nach dem Speichern findest du diese Änderung unter „Korrekturverlauf“. Dort stehen der Grund und die geänderten Angaben mit „Vorher“ und „Neu“.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildPhotoCorrection(context),
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
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              validator: (value) => ReadingValue.tryParse(value ?? '') == null
                  ? 'Bitte einen gültigen Zählerstand eingeben.'
                  : null,
            ),
            const SizedBox(height: 12),
            EditableReadingTimeCard(value: _capturedAt, onPressed: _pickDate),
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
              onChanged: (_) => setState(() {}),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Grund der Korrektur *',
                hintText: 'z. B. Tippfehler beim Bestätigen',
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Bitte den Korrekturgrund angeben.'
                  : null,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _saving || _processingPhoto ? null : _save,
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
    return PopScope<void>(
      canPop:
          _allowPop || (!_hasUnsavedChanges && !_processingPhoto && !_saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: scaffold,
    );
  }

  bool get _hasUnsavedChanges =>
      _value.text.trim() != widget.reading.value.displayText ||
      _note.text.trim() != widget.reading.note ||
      _reason.text.trim().isNotEmpty ||
      _capturedAt != widget.reading.capturedAt.toLocal() ||
      _lowerReason != widget.reading.lowerReadingReason ||
      _replacementPhoto != null;

  Future<void> _handleBack() async {
    if (_saving || _processingPhoto || _discardDialogOpen) return;
    FocusScope.of(context).unfocus();
    if (!_hasUnsavedChanges) {
      _leaveForm();
      return;
    }

    _discardDialogOpen = true;
    final discard = await confirmDiscardChanges(
      context,
      title: 'Korrektur verwerfen?',
      message:
          'Deine Änderungen an dieser Ablesung wurden noch nicht gespeichert.',
      discardLabel: 'Korrektur verwerfen',
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
    } else {
      context.goNamed(
        'readingDetail',
        pathParameters: {'id': widget.reading.id},
      );
    }
  }

  Widget _buildPhotoCorrection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aktuelles Nachweisfoto',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _PhotoPreview(path: widget.reading.photoPath),
            const SizedBox(height: 8),
            Text(
              '${widget.reading.source.label} · bisheriges Foto',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_replacementPhoto != null) ...[
              const SizedBox(height: 16),
              Text(
                'Neues Foto für die Korrektur',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              _PhotoPreview(path: _replacementPhoto!.path),
              const SizedBox(height: 8),
              Text(
                '${_replacementPhoto!.source.label} · neues Foto',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _buildPhotoSelectionButton(hasReplacement: true),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.history_outlined, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Das bisherige Foto bleibt als frühere Version erhalten.',
                      ),
                    ),
                  ],
                ),
              ),
              if (_replacementOcr != null &&
                  _replacementOcr!.candidates.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Erkannte Werte',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final candidate in _replacementOcr!.candidates)
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
              ] else if (_replacementOcr != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Kein sicherer Wert erkannt. Bitte den Zählerstand manuell prüfen und eintragen.',
                ),
              ],
            ] else ...[
              const SizedBox(height: 12),
              _buildPhotoSelectionButton(hasReplacement: false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSelectionButton({required bool hasReplacement}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _processingPhoto ? null : _chooseReplacementSource,
          icon: _processingPhoto
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  hasReplacement
                      ? Icons.change_circle_outlined
                      : Icons.add_a_photo_outlined,
                ),
          label: Text(
            hasReplacement
                ? 'Korrekturfoto ändern'
                : 'Neues Foto für Korrektur',
          ),
        ),
        if (_processingPhoto) ...[
          const SizedBox(height: 8),
          const Center(child: Text('Foto wird lokal ausgewertet …')),
        ],
      ],
    );
  }

  Future<void> _chooseReplacementSource() async {
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<ReadingSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Neues Nachweisfoto',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Quelle für das Korrekturfoto auswählen'),
            ),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) await _captureReplacement(source);
  }

  Future<void> _captureReplacement(ReadingSource source) async {
    setState(() => _processingPhoto = true);
    try {
      final photo = await _photos.capture(source);
      if (photo != null && mounted) await _processReplacementPhoto(photo);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(message: 'Foto konnte nicht verarbeitet werden: $error'),
        );
      }
    } finally {
      if (mounted) setState(() => _processingPhoto = false);
    }
  }

  Future<void> _recoverLostCapture() async {
    try {
      final photo = await _photos.recoverLostCapture();
      if (photo != null && mounted) {
        setState(() => _processingPhoto = true);
        await _processReplacementPhoto(photo);
      }
    } on Object {
      return;
    } finally {
      if (mounted) setState(() => _processingPhoto = false);
    }
  }

  Future<void> _processReplacementPhoto(StoredMeterPhoto photo) async {
    MeterOcrResult ocr;
    try {
      ocr = await _ocrRepository.recognize(photo.path);
    } catch (_) {
      await _photos.delete(photo.path);
      rethrow;
    }
    final previousPending = _replacementPhoto;
    final first = ocr.candidates.firstOrNull;
    if (!mounted) {
      await _photos.delete(photo.path);
      return;
    }
    setState(() {
      _replacementPhoto = photo;
      _replacementOcr = ocr;
      _selectedCandidate = first?.rawText ?? '';
      if (first != null) _value.text = first.value.displayText;
    });
    if (previousPending != null && previousPending.path != photo.path) {
      await _photos.delete(previousPending.path);
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final date = await showDatePicker(
      context: context,
      initialDate: _capturedAt,
      firstDate: firstSelectableReadingDate,
      lastDate: lastSelectableReadingDate,
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
    final confirmed = await confirmFutureReadingTime(context, _capturedAt);
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(meterReadingServiceProvider)
          .update(
            existing: widget.reading,
            value: ReadingValue.tryParse(_value.text)!,
            capturedAt: _capturedAt,
            note: _note.text,
            reason: _reason.text,
            lowerReadingReason: _lowerReason,
            replacementPhoto: _replacementPhoto,
            replacementOcr: _replacementOcr,
            replacementCandidate: _selectedCandidate,
          );
      ref.invalidate(readingByIdProvider(widget.reading.id));
      ref.invalidate(revisionsForReadingProvider(widget.reading.id));
      _saved = true;
      if (mounted) {
        await _leaveWithoutGuard();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(message: 'Korrektur fehlgeschlagen: $error'),
        );
        setState(() => _saving = false);
      }
    }
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Colors.black12,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    );
  }
}
