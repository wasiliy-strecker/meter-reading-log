import 'package:flutter/material.dart';

import '../domain/evidence_export.dart';

Future<EvidencePhotoMode?> showEvidencePhotoModeSheet(
  BuildContext context, {
  required EvidenceExportKind kind,
}) {
  return showModalBottomSheet<EvidencePhotoMode>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PDF-Inhalt wählen',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Du kannst jede PDF mit oder ohne Fotos erstellen.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _PhotoModeTile(
              mode: EvidencePhotoMode.withoutPhotos,
              kind: kind,
              icon: Icons.speed_outlined,
              description:
                  'Schnell und klein. Alle Angaben und Korrekturen bleiben enthalten.',
            ),
            const SizedBox(height: 8),
            _PhotoModeTile(
              mode: EvidencePhotoMode.currentPhotos,
              kind: kind,
              icon: Icons.photo_outlined,
              description: kind == EvidenceExportKind.singleReading
                  ? 'Enthält das aktuell zugeordnete Nachweisfoto.'
                  : 'Enthält pro Ablesung das aktuell zugeordnete Nachweisfoto.',
            ),
          ],
        ),
      ),
    ),
  );
}

class _PhotoModeTile extends StatelessWidget {
  const _PhotoModeTile({
    required this.mode,
    required this.kind,
    required this.icon,
    required this.description,
  });

  final EvidencePhotoMode mode;
  final EvidenceExportKind kind;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: ValueKey('evidence-photo-mode-${mode.name}'),
        leading: Icon(icon, color: colors.primary),
        title: Text(
          mode.labelFor(kind),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pop(context, mode),
      ),
    );
  }
}
