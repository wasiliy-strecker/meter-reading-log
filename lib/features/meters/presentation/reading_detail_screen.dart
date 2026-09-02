import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../../../core/integrity/integrity_copy.dart';
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
      appBar: AppBar(title: const Text('Ablesung')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            reading.photoHistory.isEmpty
                ? 'Nachweisfoto'
                : 'Aktuelles Nachweisfoto',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
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
          if (reading.photoHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PhotoHistoryCard(versions: reading.photoHistory),
          ],
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
          const SizedBox(height: 16),
          _ReadingActions(
            onEdit: () => context.pushNamed(
              'readingEdit',
              pathParameters: {'id': reading.id},
            ),
            onDelete: () => _delete(reading),
          ),
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
          const _PdfPurposeCard(),
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
          'Ablesung, alle Foto-Versionen und das Änderungsprotokoll werden dauerhaft gelöscht. Bereits erzeugte PDF-Nachweise bleiben als eigenständige Dateien erhalten.',
    );
    if (!confirmed) return;
    await ref.read(meterReadingServiceProvider).delete(reading);
    if (mounted) {
      context.goNamed('meterDetail', pathParameters: {'id': reading.meterId});
    }
  }
}

class _PdfPurposeCard extends StatelessWidget {
  const _PdfPurposeCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fact_check_outlined, color: colors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    pdfPurposeTitle,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(pdfPurposeText),
            const SizedBox(height: 8),
            Text(
              privateDocumentationText,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingActions extends StatelessWidget {
  const _ReadingActions({required this.onEdit, required this.onDelete});

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
          label: const Text('Korrigieren'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.error,
            side: BorderSide(color: colors.error),
          ),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Ablesung löschen'),
        ),
      ],
    );
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
                const Expanded(
                  child: Text(
                    integrityProtectionTitle,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(integrityBenefitText),
            const SizedBox(height: 8),
            Text(
              integrityLimitationText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                leading: const Icon(Icons.fingerprint),
                title: const Text(technicalChecksTitle),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      'Prüfwert des Fotos (SHA-256)\n${reading.photoSha256}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      'Prüfwert der Ablesung (SHA-256)\n${reading.manifestSha256}',
                    ),
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
                          '${change.key}: „${_displayValue(change.key, change.value.before)}“ → „${_displayValue(change.key, change.value.after)}“',
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _displayValue(String key, String value) {
    if (key.contains('SHA-256') && value.length > 12) return shortHash(value);
    return value;
  }
}

class _PhotoHistoryCard extends StatelessWidget {
  const _PhotoHistoryCard({required this.versions});

  final List<ReadingPhotoVersion> versions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.photo_library_outlined),
        title: Text('Frühere Fotos (${versions.length})'),
        subtitle: const Text('Originale bleiben unverändert erhalten'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final entry in versions.indexed) ...[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                entry.$1 == 0
                    ? 'Ursprüngliches Foto'
                    : 'Frühere Foto-Version ${entry.$1 + 1}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(
                  File(entry.$2.path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Colors.black12,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${entry.$2.source.label} · hinzugefügt ${formatDateTime(entry.$2.addedAt)}',
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                'Prüfwert des Fotos (SHA-256)\n${entry.$2.sha256}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
