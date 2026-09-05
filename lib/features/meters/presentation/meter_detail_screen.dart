import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/app_snack_bar.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../../../core/integrity/integrity_copy.dart';
import '../../../core/utils/formatters.dart';
import '../../evidence/application/evidence_report_service.dart';
import '../../evidence/domain/evidence_export.dart';
import '../domain/meter.dart';
import '../domain/meter_reading.dart';
import 'meter_visuals.dart';

class MeterDetailScreen extends ConsumerStatefulWidget {
  const MeterDetailScreen({super.key, required this.meterId});

  final String meterId;

  @override
  ConsumerState<MeterDetailScreen> createState() => _MeterDetailScreenState();
}

class _MeterDetailScreenState extends ConsumerState<MeterDetailScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final meterAsync = ref.watch(meterByIdProvider(widget.meterId));
    return meterAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(
        body: Center(child: Text('Zähler konnte nicht geladen werden.')),
      ),
      data: (meter) => meter == null
          ? const Scaffold(body: Center(child: Text('Zähler nicht gefunden.')))
          : _buildContent(meter),
    );
  }

  Widget _buildContent(Meter meter) {
    final readingsAsync = ref.watch(readingsForMeterProvider(meter.id));
    final exports =
        ref.watch(evidenceForMeterProvider(meter.id)).value ?? const [];
    void openMeterEditor() =>
        context.pushNamed('meterEdit', pathParameters: {'id': meter.id});
    return Scaffold(
      appBar: AppBar(title: Text(meter.label)),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Ablesungen konnten nicht geladen werden.'),
        ),
        data: (readings) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
          children: [
            _MeterHeader(
              meter: meter,
              readings: readings,
              onTap: openMeterEditor,
            ),
            const SizedBox(height: 12),
            _MeterActions(
              onEdit: openMeterEditor,
              onDelete: () => _deleteMeter(meter),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Verlauf',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (readings.isNotEmpty) ...[
              _HistoryPdfAction(
                exporting: _exporting,
                onPressed: () => _exportHistory(readings),
              ),
              const SizedBox(height: 12),
            ],
            if (readings.isEmpty)
              const _EmptyReadings()
            else
              for (var index = 0; index < readings.length; index++)
                _ReadingTile(
                  reading: readings[index],
                  previous: index + 1 < readings.length
                      ? readings[index + 1]
                      : null,
                ),
            if (exports.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                'Gespeicherte PDF-Nachweise',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final export in exports)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(export.fileName),
                  subtitle: Text(
                    '${formatDateTime(export.createdAt)} · ${shortHash(export.pdfSha256)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openExport(export),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(
          'captureReading',
          pathParameters: {'id': meter.id},
        ),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Ablesen / Fotografieren'),
      ),
    );
  }

  Future<void> _exportHistory(List<MeterReading> readings) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final progressDialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PdfExportProgressDialog(),
    );
    GeneratedEvidenceReport? report;
    Object? failure;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final repository = ref.read(meterReadingRepositoryProvider);
      final revisions = <String, List<ReadingRevision>>{};
      for (final reading in readings) {
        revisions[reading.id] = await repository.loadRevisions(reading.id);
      }
      report = await ref
          .read(evidenceReportServiceProvider)
          .createHistory(readings: readings, revisions: revisions);
    } catch (error) {
      failure = error;
    }
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();
    await progressDialog;
    if (!mounted) return;
    setState(() => _exporting = false);

    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(message: 'PDF konnte nicht erstellt werden: $failure'),
      );
      return;
    }
    await context.pushNamed('evidencePreview', extra: report!);
  }

  Future<void> _openExport(EvidenceExportRecord record) async {
    final file = File(record.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(message: 'Die gespeicherte PDF-Datei fehlt.'),
        );
      }
      return;
    }
    final report = GeneratedEvidenceReport(
      record: record,
      bytes: await file.readAsBytes(),
    );
    if (mounted) await context.pushNamed('evidencePreview', extra: report);
  }

  Future<void> _deleteMeter(Meter meter) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Zähler löschen?',
      message:
          'Alle Ablesungen, Originalfotos und lokal gespeicherten PDF-Nachweise dieses Zählers werden dauerhaft entfernt. Bereits extern geteilte Dateien bleiben bestehen.',
    );
    if (!confirmed) return;
    await ref.read(meterServiceProvider).delete(meter.id);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('home');
    }
  }
}

class _MeterActions extends StatelessWidget {
  const _MeterActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Zähler & Erinnerung bearbeiten'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.error,
            side: BorderSide(color: colors.error),
          ),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Zähler löschen'),
        ),
      ],
    );
  }
}

class _HistoryPdfAction extends StatelessWidget {
  const _HistoryPdfAction({required this.exporting, required this.onPressed});

  final bool exporting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.picture_as_pdf_outlined, color: colors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF-Nachweis des Verlaufs',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(historyPdfPurposeText),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            IgnorePointer(
              ignoring: exporting,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Verlauf als PDF erstellen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfExportProgressDialog extends StatelessWidget {
  const _PdfExportProgressDialog();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope<void>(
      canPop: false,
      child: AlertDialog(
        icon: Icon(
          Icons.picture_as_pdf_outlined,
          size: 36,
          color: colors.primary,
        ),
        title: const Text(
          'PDF-Nachweis wird erstellt',
          textAlign: TextAlign.center,
        ),
        content: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ablesungen, Fotos und Korrekturen werden für die PDF zusammengestellt.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                key: const ValueKey('history-pdf-progress'),
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: colors.primary.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 10),
              Text(
                'Bitte kurz warten …',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeterHeader extends StatelessWidget {
  const _MeterHeader({
    required this.meter,
    required this.readings,
    required this.onTap,
  });

  final Meter meter;
  final List<MeterReading> readings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = meterColor(meter.type);
    final latest = readings.firstOrNull;
    return Card(
      key: ValueKey('meter-summary-${meter.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    foregroundColor: color,
                    child: Icon(meterIcon(meter.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      meter.type.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                latest == null
                    ? 'Noch kein Zählerstand'
                    : '${latest.value.displayText} ${latest.meter.unit}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (latest != null)
                Text('Zuletzt am ${formatDateTime(latest.capturedAt)}'),
              const SizedBox(height: 10),
              if (meter.meterNumber.isNotEmpty)
                Text('Zählernummer: ${meter.meterNumber}'),
              if (meter.location.isNotEmpty)
                Text('Standort: ${meter.location}'),
              if (meter.reminder != null)
                Text('Erinnerung: ${_reminderSummary(meter.reminder!)}'),
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

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading, this.previous});

  final MeterReading reading;
  final MeterReading? previous;

  @override
  Widget build(BuildContext context) {
    final sameUnit =
        previous == null || previous!.meter.unit == reading.meter.unit;
    final delta = previous == null || !sameUnit
        ? null
        : reading.value.difference(previous!.value).germanFormatted;
    return Card(
      key: ValueKey('reading-card-${reading.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          'readingDetail',
          pathParameters: {'id': reading.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _ReadingPhotoThumbnail(reading: reading),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zählerstand',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${reading.value.displayText} ${reading.meter.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Abgelesen am',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(formatDateTime(reading.capturedAt)),
                    if (previous != null && !sameUnit)
                      const Text('Einheit seit dieser Ablesung gewechselt')
                    else if (delta != null)
                      Text('Δ $delta ${reading.meter.unit}'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingPhotoThumbnail extends StatelessWidget {
  const _ReadingPhotoThumbnail({required this.reading});

  final MeterReading reading;

  @override
  Widget build(BuildContext context) {
    final fallbackColor = Theme.of(context).colorScheme.primaryContainer;
    return Semantics(
      label: 'Foto zur Ablesung ${reading.value.displayText}',
      image: true,
      child: ClipRRect(
        key: ValueKey('reading-thumbnail-${reading.id}'),
        borderRadius: BorderRadius.circular(14),
        child: SizedBox.square(
          dimension: 92,
          child: Image.file(
            File(reading.photoPath),
            fit: BoxFit.cover,
            cacheWidth: 240,
            errorBuilder: (_, _, _) => ColoredBox(
              color: fallbackColor,
              child: const Icon(Icons.broken_image_outlined, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyReadings extends StatelessWidget {
  const _EmptyReadings();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            const Text(
              'Noch keine Ablesung. Fotografiere den Zähler und bestätige den lokal erkannten Wert.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
