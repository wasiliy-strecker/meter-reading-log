import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../../../core/utils/formatters.dart';
import '../domain/meter.dart';
import '../domain/meter_reading.dart';
import 'editable_reading_time_card.dart';

class ReadingDetailScreen extends ConsumerStatefulWidget {
  const ReadingDetailScreen({super.key, required this.readingId});

  final String readingId;

  @override
  ConsumerState<ReadingDetailScreen> createState() =>
      _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends ConsumerState<ReadingDetailScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(readingByIdProvider(widget.readingId))
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
              : _buildContent(reading),
        );
  }

  Widget _buildContent(MeterReading reading) {
    final revisions = ref.watch(revisionsForReadingProvider(reading.id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ablesung'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                context.pushNamed(
                  'readingEdit',
                  pathParameters: {'id': reading.id},
                );
              } else if (value == 'delete') {
                _delete(reading);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Korrigieren')),
              PopupMenuItem(value: 'delete', child: Text('Ablesung löschen')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(
                File(reading.photoPath),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${reading.value.displayText} ${reading.meter.unit}',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text('${reading.meter.type.label} · ${reading.meter.label}'),
          if (reading.wasFutureAtStorage) ...[
            const SizedBox(height: 12),
            const FutureReadingTimeNotice(
              message:
                  'Beim Speichern lag der angegebene Ablesezeitpunkt in der Zukunft. Der tatsächliche Speicherzeitpunkt bleibt separat erhalten.',
            ),
          ],
          const SizedBox(height: 18),
          _InfoCard(reading: reading),
          const SizedBox(height: 12),
          _IntegrityCard(reading: reading),
          const SizedBox(height: 12),
          revisions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Änderungsprotokoll nicht verfügbar.'),
            data: (items) => _RevisionCard(revisions: items),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _exporting ? null : () => _export(reading),
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Einzelnachweis als PDF'),
          ),
          const SizedBox(height: 10),
          Text(
            'Der PDF-Nachweis ist lokal manipulationsprüfbar. Er enthält keinen amtlichen Zeitstempel und keine qualifizierte elektronische Signatur.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(MeterReading reading) async {
    setState(() => _exporting = true);
    try {
      final revisions = await ref
          .read(meterReadingRepositoryProvider)
          .loadRevisions(reading.id);
      final report = await ref
          .read(evidenceReportServiceProvider)
          .createSingle(reading: reading, revisions: revisions);
      if (mounted) await context.pushNamed('evidencePreview', extra: report);
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

  Future<void> _delete(MeterReading reading) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Ablesung löschen?',
      message:
          'Ablesung, Originalfoto und Änderungsprotokoll werden dauerhaft gelöscht. Bereits erzeugte PDF-Nachweise bleiben als eigenständige Dateien erhalten.',
    );
    if (!confirmed) return;
    await ref.read(meterReadingServiceProvider).delete(reading);
    if (mounted) {
      context.goNamed('meterDetail', pathParameters: {'id': reading.meterId});
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.reading});

  final MeterReading reading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Zeitpunkt der Ablesung', formatDateTime(reading.capturedAt)),
            _row('Quelle', reading.source.label),
            _row(
              'OCR-Kandidat',
              reading.ocrCandidate.isEmpty ? 'Keiner' : reading.ocrCandidate,
            ),
            _row(
              'OCR-Konfidenz',
              reading.ocrConfidence == null
                  ? 'Nicht verfügbar'
                  : '${(reading.ocrConfidence! * 100).round()} %',
            ),
            _row(
              'Manuell abweichend',
              reading.wasManuallyCorrected ? 'Ja' : 'Nein',
            ),
            if (reading.lowerReadingReason != null)
              _row('Niedrigerer Stand', reading.lowerReadingReason!.label),
            if (reading.note.isNotEmpty) _row('Notiz', reading.note),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrityCard extends StatelessWidget {
  const _IntegrityCard({required this.reading});

  final MeterReading reading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Integritätsdaten',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText('Foto SHA-256\n${reading.photoSha256}'),
            const SizedBox(height: 8),
            SelectableText('Datensatz SHA-256\n${reading.manifestSha256}'),
          ],
        ),
      ),
    );
  }
}

class _RevisionCard extends StatelessWidget {
  const _RevisionCard({required this.revisions});

  final List<ReadingRevision> revisions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Änderungsprotokoll',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (revisions.isEmpty)
              const Text('Keine nachträglichen Änderungen.')
            else
              for (final revision in revisions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatDateTime(revision.changedAt)} · ${revision.reason}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      for (final change in revision.changes.entries)
                        Text(
                          '${change.key}: „${change.value.before}“ → „${change.value.after}“',
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
