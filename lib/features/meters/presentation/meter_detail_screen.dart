import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/confirm_dialog.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(meter.label),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                context.pushNamed(
                  'meterEdit',
                  pathParameters: {'id': meter.id},
                );
              } else if (value == 'delete') {
                _deleteMeter(meter);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
              PopupMenuItem(value: 'delete', child: Text('Zähler löschen')),
            ],
          ),
        ],
      ),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Ablesungen konnten nicht geladen werden.'),
        ),
        data: (readings) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
          children: [
            _MeterHeader(meter: meter, readings: readings),
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
    setState(() => _exporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final repository = ref.read(meterReadingRepositoryProvider);
      final revisions = <String, List<ReadingRevision>>{};
      for (final reading in readings) {
        revisions[reading.id] = await repository.loadRevisions(reading.id);
      }
      final report = await ref
          .read(evidenceReportServiceProvider)
          .createHistory(readings: readings, revisions: revisions);
      if (!mounted) return;
      await context.pushNamed('evidencePreview', extra: report);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF konnte nicht erstellt werden: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openExport(EvidenceExportRecord record) async {
    final file = File(record.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Die gespeicherte PDF-Datei fehlt.')),
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
    if (mounted) context.goNamed('home');
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
                      Text(
                        'Erstellt eine lokal prüfbare PDF mit allen Ablesungen, Fotos, Korrekturen und SHA-256-Prüfsummen.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (exporting) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: exporting ? null : onPressed,
              icon: exporting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                exporting ? 'PDF wird erstellt …' : 'Verlauf als PDF erstellen',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeterHeader extends StatelessWidget {
  const _MeterHeader({required this.meter, required this.readings});

  final Meter meter;
  final List<MeterReading> readings;

  @override
  Widget build(BuildContext context) {
    final color = meterColor(meter.type);
    final latest = readings.firstOrNull;
    return Card(
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
            if (meter.location.isNotEmpty) Text('Standort: ${meter.location}'),
            if (meter.reminder != null)
              Text(
                'Erinnerung: ${meter.reminder!.interval == ReminderInterval.monthly ? 'monatlich' : 'jährlich'} am ${meter.reminder!.day}. um ${meter.reminder!.hour.toString().padLeft(2, '0')}:${meter.reminder!.minute.toString().padLeft(2, '0')} Uhr',
              ),
          ],
        ),
      ),
    );
  }
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
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Icon(
            reading.source == ReadingSource.camera
                ? Icons.photo_camera_outlined
                : Icons.photo_library_outlined,
          ),
        ),
        title: Text(
          '${reading.value.displayText} ${reading.meter.unit}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${formatDateTime(reading.capturedAt)}'
          '${previous != null && !sameUnit ? ' · Einheit gewechselt' : ''}'
          '${delta == null ? '' : ' · Δ $delta ${reading.meter.unit}'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(
          'readingDetail',
          pathParameters: {'id': reading.id},
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
