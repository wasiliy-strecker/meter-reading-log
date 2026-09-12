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
import '../../evidence/presentation/evidence_photo_mode_sheet.dart';
import '../domain/meter.dart';
import '../domain/meter_reading.dart';
import 'meter_visuals.dart';
import 'reading_history_tile.dart';

class MeterDetailScreen extends ConsumerStatefulWidget {
  const MeterDetailScreen({super.key, required this.meterId});

  final String meterId;

  @override
  ConsumerState<MeterDetailScreen> createState() => _MeterDetailScreenState();
}

class _MeterDetailScreenState extends ConsumerState<MeterDetailScreen> {
  static const _historyPreviewSize = 5;

  bool _exporting = false;
  final Set<String> _deletingExportIds = {};
  @override
  Widget build(BuildContext context) {
    final meterAsync = ref.watch(meterByIdProvider(widget.meterId));
    return PopScope<void>(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.goNamed('home');
      },
      child: meterAsync.when(
        loading: () => Scaffold(
          appBar: _appBar('Zähler'),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Scaffold(
          appBar: _appBar('Zähler'),
          body: const Center(
            child: Text('Zähler konnte nicht geladen werden.'),
          ),
        ),
        data: (meter) => meter == null
            ? Scaffold(
                appBar: _appBar('Zähler'),
                body: const Center(child: Text('Zähler nicht gefunden.')),
              )
            : _buildContent(meter),
      ),
    );
  }

  AppBar _appBar(String title) {
    return AppBar(
      leading: BackButton(onPressed: _leaveDetail),
      title: Text(title),
    );
  }

  void _leaveDetail() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('home');
    }
  }

  Widget _buildContent(Meter meter) {
    final historyPageAsync = ref.watch(
      meterHistoryPageProvider((
        meterId: meter.id,
        limit: _historyPreviewSize,
        offset: 0,
        query: '',
      )),
    );
    final exportsAsync = ref.watch(evidenceForMeterProvider(meter.id));
    final exports = exportsAsync.value ?? const [];
    final historyExports = exports
        .where((export) => export.kind == EvidenceExportKind.meterHistory)
        .toList(growable: false);
    final availableFiles = <String, bool>{
      for (final export in historyExports)
        export.id: File(export.filePath).existsSync(),
    };
    void openMeterEditor() =>
        context.pushNamed('meterEdit', pathParameters: {'id': meter.id});
    void captureReading() =>
        context.pushNamed('captureReading', pathParameters: {'id': meter.id});
    return Scaffold(
      appBar: _appBar(meter.label),
      body: historyPageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Ablesungen konnten nicht geladen werden.'),
        ),
        data: (page) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: page.readings.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MeterHeader(
                      meter: meter,
                      latestReading: page.latestReading,
                      onTap: openMeterEditor,
                    ),
                    const SizedBox(height: 12),
                    _MeterActions(
                      onEdit: openMeterEditor,
                      onDelete: () => _deleteMeter(meter),
                    ),
                    const SizedBox(height: 18),
                    if (page.totalCount > 0) ...[
                      _HistoryPdfAction(
                        exporting: _exporting,
                        onPressed: () => _exportHistory(meter),
                      ),
                      if (historyExports.isNotEmpty) const SizedBox(height: 10),
                    ],
                    if (historyExports.isNotEmpty)
                      _SavedHistoryPdfs(
                        exports: historyExports,
                        availableFiles: availableFiles,
                        deletingExportIds: _deletingExportIds,
                        onOpen: _openExport,
                        onDelete: _deleteExport,
                      ),
                    if (page.totalCount > 0 || historyExports.isNotEmpty)
                      const SizedBox(height: 22),
                    Text(
                      'Zählerverlauf',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (page.totalCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        page.totalCount == 1
                            ? '1 Ablesung'
                            : '${page.readings.length} von ${page.totalCount} Ablesungen',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (page.totalCount == 0)
                      _EmptyReadings(onTap: captureReading),
                  ],
                );
              }

              final readingIndex = index - 1;
              if (readingIndex < page.readings.length) {
                final previous = readingIndex + 1 < page.readings.length
                    ? page.readings[readingIndex + 1]
                    : page.olderNeighbor;
                return ReadingHistoryTile(
                  reading: page.readings[readingIndex],
                  previous: previous,
                  showDelta: true,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (page.totalCount > 0) ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      key: const ValueKey('open-meter-history'),
                      onPressed: () => context.pushNamed(
                        'meterHistory',
                        pathParameters: {'id': meter.id},
                      ),
                      icon: const Icon(Icons.manage_search_outlined),
                      label: const Text('Alle Ablesungen anzeigen'),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: captureReading,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Ablesen / Fotografieren'),
      ),
    );
  }

  Future<void> _exportHistory(Meter meter) async {
    if (_exporting) return;
    final photoMode = await showEvidencePhotoModeSheet(
      context,
      kind: EvidenceExportKind.meterHistory,
    );
    if (photoMode == null || !mounted) return;
    setState(() => _exporting = true);
    try {
      final report = await runWithPdfExportProgress(
        context,
        description: photoMode == EvidencePhotoMode.withoutPhotos
            ? 'Ablesungen und Korrekturen werden für die kompakte PDF zusammengestellt.'
            : 'Ablesungen, aktuelle Fotos und Korrekturen werden für die PDF zusammengestellt.',
        operation: () async {
          final repository = ref.read(meterReadingRepositoryProvider);
          final readings = await repository.loadForMeter(meter.id);
          final revisionLists = await Future.wait(
            readings.map((reading) => repository.loadRevisions(reading.id)),
          );
          final revisions = <String, List<ReadingRevision>>{
            for (var index = 0; index < readings.length; index++)
              readings[index].id: revisionLists[index],
          };
          return ref
              .read(evidenceReportServiceProvider)
              .createHistory(
                meter: meter,
                readings: readings,
                revisions: revisions,
                photoMode: photoMode,
              );
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

  Future<void> _deleteExport(EvidenceExportRecord record) async {
    if (_deletingExportIds.contains(record.id)) return;
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Zählerverlaufsnachweis löschen?',
      message:
          'Die PDF wird dauerhaft aus ZählerstandLog gelöscht. Bereits geteilte oder außerhalb der App gespeicherte Kopien bleiben erhalten.',
    );
    if (!confirmed || !mounted) return;
    setState(() => _deletingExportIds.add(record.id));
    try {
      await ref.read(evidenceReportServiceProvider).delete(record);
      ref.invalidate(evidenceForMeterProvider(record.meterId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar(message: 'PDF-Nachweis gelöscht.'));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(
            message:
                'PDF-Nachweis konnte nicht gelöscht werden. Bitte versuche es erneut.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletingExportIds.remove(record.id));
      }
    }
  }

  Future<void> _deleteMeter(Meter meter) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Zähler löschen?',
      message:
          'Alle Ablesungen, Nachweisfotos und lokal gespeicherten PDF-Nachweise dieses Zählers werden dauerhaft entfernt. Bereits extern geteilte Dateien bleiben bestehen.',
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
                        'PDF-Nachweis des Zählerverlaufs',
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
            FilledButton.icon(
              onPressed: exporting ? null : onPressed,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text(
                'Zählerverlauf als PDF erstellen',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedHistoryPdfs extends StatelessWidget {
  const _SavedHistoryPdfs({
    required this.exports,
    required this.availableFiles,
    required this.deletingExportIds,
    required this.onOpen,
    required this.onDelete,
  });

  final List<EvidenceExportRecord> exports;
  final Map<String, bool> availableFiles;
  final Set<String> deletingExportIds;
  final Future<void> Function(EvidenceExportRecord) onOpen;
  final Future<void> Function(EvidenceExportRecord) onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final countLabel = exports.length == 1
        ? '1 Nachweis'
        : '${exports.length} Nachweise';
    return Card(
      key: const ValueKey('saved-history-pdfs'),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('saved-history-pdfs-expansion'),
          initiallyExpanded: false,
          leading: Icon(Icons.folder_copy_outlined, color: colors.primary),
          title: const Text(
            'Gespeicherte PDF-Nachweise',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(countLabel),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          children: [
            for (final export in exports)
              EvidenceExportCard(
                export: export,
                title: 'Zählerverlaufsnachweis',
                detail:
                    '${_readingCountLabel(export.readingIds.length)}\n${export.photoMode.labelFor(export.kind)}',
                fileAvailable: availableFiles[export.id] == true,
                onTap: availableFiles[export.id] != true
                    ? null
                    : () => onOpen(export),
                deleting: deletingExportIds.contains(export.id),
                onDelete: () => onDelete(export),
              ),
          ],
        ),
      ),
    );
  }
}

String _readingCountLabel(int count) => switch (count) {
  1 => '1 Ablesung enthalten',
  _ => '$count Ablesungen enthalten',
};

class _MeterHeader extends StatelessWidget {
  const _MeterHeader({
    required this.meter,
    required this.latestReading,
    required this.onTap,
  });

  final Meter meter;
  final MeterReading? latestReading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = meterColor(meter.type);
    final latest = latestReading;
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
    ReminderInterval.hourly =>
      'stündlich ab ${formatDateTime(reminder.startsAt!)} Uhr',
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

class _EmptyReadings extends StatelessWidget {
  const _EmptyReadings({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('empty-readings-action'),
        onTap: onTap,
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Erste Ablesung erfassen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
