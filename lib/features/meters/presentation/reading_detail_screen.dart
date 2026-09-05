import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/app_snack_bar.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../../../app/widgets/pdf_export_progress_dialog.dart';
import '../../../core/integrity/integrity_copy.dart';
import '../../../core/utils/formatters.dart';
import '../../evidence/application/evidence_report_service.dart';
import '../../evidence/domain/evidence_export.dart';
import '../../evidence/presentation/evidence_export_card.dart';
import '../application/reading_revision_photos.dart';
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
    final exportsAsync = ref.watch(evidenceForMeterProvider(reading.meterId));
    final singleExports = [
      ...?exportsAsync.value?.where(
        (export) =>
            export.kind == EvidenceExportKind.singleReading &&
            export.readingIds.contains(reading.id),
      ),
    ]..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final manifestAsync = singleExports.isEmpty
        ? const AsyncValue<String?>.data(null)
        : ref.watch(singleReadingEvidenceManifestProvider(reading.id));
    final availableFiles = <String, bool>{
      for (final export in singleExports)
        export.id: File(export.filePath).existsSync(),
    };
    final currentManifest = manifestAsync.value;
    final matchingExports = currentManifest == null
        ? const <EvidenceExportRecord>[]
        : singleExports
              .where((export) => export.manifestSha256 == currentManifest)
              .toList(growable: false);
    final checkingCurrentEvidence =
        exportsAsync.isLoading || manifestAsync.isLoading;
    final evidenceCheckFailed = exportsAsync.hasError || manifestAsync.hasError;
    final hasCurrentEvidence = matchingExports.any(
      (export) => availableFiles[export.id] == true,
    );
    final canCreateEvidence =
        !checkingCurrentEvidence && !evidenceCheckFailed && !hasCurrentEvidence;
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
          _CorrectionHistoryCard(reading: reading, revisions: revisions),
          const SizedBox(height: 20),
          if (singleExports.isNotEmpty) ...[
            Text(
              'Gespeicherte Einzelnachweise',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final export in singleExports)
              EvidenceExportCard(
                export: export,
                title: 'Einzelnachweis',
                detail:
                    'Zählerstand: ${reading.value.displayText} ${reading.meter.unit}',
                fileAvailable: availableFiles[export.id] == true,
                onTap: availableFiles[export.id] != true
                    ? null
                    : () => _openExport(export),
              ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: canCreateEvidence && !_exporting
                ? () => _export(reading)
                : null,
            icon: Icon(
              hasCurrentEvidence
                  ? Icons.check_circle_outline
                  : checkingCurrentEvidence
                  ? Icons.hourglass_top_rounded
                  : Icons.picture_as_pdf_outlined,
            ),
            label: Text(
              hasCurrentEvidence
                  ? 'Aktueller Einzelnachweis bereits erstellt'
                  : checkingCurrentEvidence
                  ? 'Vorhandene Nachweise werden geprüft'
                  : 'Einzelnachweis als PDF erstellen',
              textAlign: TextAlign.center,
            ),
          ),
          if (hasCurrentEvidence) ...[
            const SizedBox(height: 8),
            Text(
              'Seit diesem Nachweis wurde die Ablesung nicht geändert. Nach einer Korrektur kannst du einen neuen erstellen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (evidenceCheckFailed) ...[
            const SizedBox(height: 8),
            Text(
              'Die gespeicherten Nachweise konnten gerade nicht geprüft werden.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 10),
          const _PdfPurposeCard(),
        ],
      ),
    );
  }

  Future<void> _export(MeterReading reading) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final report = await runWithPdfExportProgress(
        context,
        description:
            'Foto und Nachweisdaten werden für die PDF zusammengestellt.',
        operation: () async {
          final revisions = await ref
              .read(meterReadingRepositoryProvider)
              .loadRevisions(reading.id);
          return ref
              .read(evidenceReportServiceProvider)
              .createSingle(reading: reading, revisions: revisions);
        },
      );
      if (!mounted) return;
      setState(() => _exporting = false);
      await context.pushNamed('evidencePreview', extra: report);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(message: 'PDF konnte nicht erstellt werden: $error'),
        );
      }
    } finally {
      if (mounted && _exporting) setState(() => _exporting = false);
    }
  }

  Future<void> _openExport(EvidenceExportRecord record) async {
    final file = File(record.filePath);
    if (!await file.exists()) {
      if (mounted) {
        setState(() {});
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

  Future<void> _delete(MeterReading reading) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Ablesung löschen?',
      message:
          'Ablesung, alle Foto-Versionen und der Korrekturverlauf werden dauerhaft gelöscht. Bereits erzeugte PDF-Nachweise bleiben als eigenständige Dateien erhalten.',
    );
    if (!confirmed) return;
    await ref.read(meterReadingServiceProvider).delete(reading);
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed('meterDetail', pathParameters: {'id': reading.meterId});
      }
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
                Icon(Icons.description_outlined, color: colors.primary),
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

class _CorrectionHistoryCard extends StatelessWidget {
  const _CorrectionHistoryCard({
    required this.reading,
    required this.revisions,
  });

  final MeterReading reading;
  final AsyncValue<List<ReadingRevision>> revisions;

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
                  Icons.history_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    correctionHistoryTitle,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(correctionHistoryText),
            const SizedBox(height: 12),
            revisions.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text(
                'Der Korrekturverlauf konnte nicht geladen werden.',
              ),
              data: (items) =>
                  _RevisionList(revisions: items, reading: reading),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevisionList extends StatelessWidget {
  const _RevisionList({required this.revisions, required this.reading});

  final List<ReadingRevision> revisions;
  final MeterReading reading;

  @override
  Widget build(BuildContext context) {
    if (revisions.isEmpty) {
      return const Text('Für diese Ablesung gibt es noch keine Korrekturen.');
    }

    final newestFirst = [...revisions]
      ..sort((left, right) => right.changedAt.compareTo(left.changedAt));
    return Column(
      children: [
        for (final entry in newestFirst.indexed) ...[
          if (entry.$1 > 0) const Divider(height: 24),
          _RevisionEntry(revision: entry.$2, reading: reading),
        ],
      ],
    );
  }
}

class _RevisionEntry extends StatelessWidget {
  const _RevisionEntry({required this.revision, required this.reading});

  final ReadingRevision revision;
  final MeterReading reading;

  @override
  Widget build(BuildContext context) {
    final visibleChanges = visibleRevisionChanges(
      revision,
    ).toList(growable: false);
    final revisionPhotos = photosForRevision(
      reading: reading,
      revision: revision,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Korrektur vom ${formatDateTime(revision.changedAt)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Grund: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: revision.reason),
            ],
          ),
        ),
        if (visibleChanges.isNotEmpty || revisionPhotos != null)
          const SizedBox(height: 10),
        for (final change in visibleChanges) ...[
          Text(change.key, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          _RevisionValue(
            label: 'Vorher',
            value: _displayValue(change.key, change.value.before),
          ),
          _RevisionValue(
            label: 'Neu',
            value: _displayValue(change.key, change.value.after),
          ),
          const SizedBox(height: 8),
        ],
        if (revisionPhotos != null)
          _RevisionPhotos(photos: revisionPhotos, revisionId: revision.id),
      ],
    );
  }

  String _displayValue(String key, String value) {
    if (value.trim().isEmpty) return 'Keine Angabe';
    if (key == 'Zeitpunkt der Ablesung') {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return formatDateTime(parsed);
    }
    if (key == 'Zählerstand') return '$value ${reading.meter.unit}';
    return value;
  }
}

class _RevisionValue extends StatelessWidget {
  const _RevisionValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _RevisionPhotos extends StatelessWidget {
  const _RevisionPhotos({required this.photos, required this.revisionId});

  final ReadingRevisionPhotos photos;
  final String revisionId;

  @override
  Widget build(BuildContext context) {
    final after = photos.after;
    final before = photos.before;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (after != null) ...[
          const Text(
            'Neues Foto',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _RevisionPhotoPreview(
            photo: after,
            semanticsLabel: 'Neues Foto der Korrektur $revisionId',
          ),
          const SizedBox(height: 6),
          Text(
            '${after.source.label} · hinzugefügt ${formatDateTime(after.addedAt)}',
          ),
        ] else
          const Row(
            children: [
              Icon(Icons.photo_camera_back_outlined, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nachweisfoto geändert',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        if (before != null) ...[
          const SizedBox(height: 4),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              shape: const RoundedRectangleBorder(),
              collapsedShape: const RoundedRectangleBorder(),
              leading: const Icon(Icons.compare_outlined),
              title: const Text('Vorheriges Foto anzeigen'),
              children: [
                _RevisionPhotoPreview(
                  photo: before,
                  semanticsLabel: 'Vorheriges Foto der Korrektur $revisionId',
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${before.source.label} · hinzugefügt ${formatDateTime(before.addedAt)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RevisionPhotoPreview extends StatelessWidget {
  const _RevisionPhotoPreview({
    required this.photo,
    required this.semanticsLabel,
  });

  final ReadingPhotoVersion photo;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.file(
            File(photo.path),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Colors.black12,
              child: Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        ),
      ),
    );
  }
}
