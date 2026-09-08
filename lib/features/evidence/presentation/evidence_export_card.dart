import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../domain/evidence_export.dart';

class EvidenceExportCard extends StatelessWidget {
  const EvidenceExportCard({
    super.key,
    required this.export,
    required this.title,
    required this.detail,
    required this.onTap,
    required this.onDelete,
    this.fileAvailable = true,
    this.deleting = false,
    this.currentLabel,
  });

  final EvidenceExportRecord export;
  final String title;
  final String detail;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool fileAvailable;
  final bool deleting;
  final String? currentLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = fileAvailable ? colors.primary : colors.error;
    return Card(
      key: ValueKey('evidence-export-${export.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      color: colors.secondaryContainer.withValues(alpha: 0.38),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: deleting ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentLabel case final label?)
              Ink(
                key: ValueKey('current-evidence-badge-${export.id}'),
                color: colors.primaryContainer.withValues(alpha: 0.72),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 19,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: fileAvailable
                          ? colors.primaryContainer
                          : colors.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      fileAvailable
                          ? Icons.picture_as_pdf_outlined
                          : Icons.file_present_outlined,
                      color: fileAvailable
                          ? colors.onPrimaryContainer
                          : colors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Erstellt am ${formatDateTime(export.createdAt)} Uhr',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  fileAvailable
                                      ? Icons.verified_outlined
                                      : Icons.error_outline,
                                  size: 17,
                                  color: accent,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    fileAvailable
                                        ? 'Lokal gespeichert'
                                        : 'Datei fehlt',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: accent,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: deleting
                        ? Center(
                            child: SizedBox.square(
                              key: ValueKey(
                                'delete-evidence-progress-${export.id}',
                              ),
                              dimension: 22,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : IconButton(
                            key: ValueKey('delete-evidence-${export.id}'),
                            tooltip: 'PDF-Nachweis löschen',
                            onPressed: onDelete,
                            color: colors.error,
                            icon: const Icon(Icons.delete_outline),
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
