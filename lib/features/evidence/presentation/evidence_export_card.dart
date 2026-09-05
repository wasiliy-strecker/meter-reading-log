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
    this.fileAvailable = true,
  });

  final EvidenceExportRecord export;
  final String title;
  final String detail;
  final VoidCallback? onTap;
  final bool fileAvailable;

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
        onTap: onTap,
        child: Padding(
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
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
                            Text(
                              fileAvailable
                                  ? 'Lokal gespeichert'
                                  : 'Datei fehlt',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Icon(
                  fileAvailable
                      ? Icons.chevron_right
                      : Icons.warning_amber_rounded,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
