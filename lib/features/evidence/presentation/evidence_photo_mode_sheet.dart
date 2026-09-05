import 'package:flutter/material.dart';

import '../domain/evidence_export.dart';

Future<EvidencePhotoMode?> showEvidencePhotoModeSheet(
  BuildContext context, {
  required EvidenceExportKind kind,
  Set<EvidencePhotoMode> unavailableModes = const {},
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
              unavailable: unavailableModes.contains(
                EvidencePhotoMode.withoutPhotos,
              ),
            ),
            const SizedBox(height: 8),
            _PhotoModeTile(
              mode: EvidencePhotoMode.currentPhotos,
              kind: kind,
              icon: Icons.photo_outlined,
              description: kind == EvidenceExportKind.singleReading
                  ? 'Enthält das aktuell zugeordnete Nachweisfoto.'
                  : 'Enthält pro Ablesung das aktuell zugeordnete Nachweisfoto.',
              unavailable: unavailableModes.contains(
                EvidencePhotoMode.currentPhotos,
              ),
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
    required this.unavailable,
  });

  final EvidencePhotoMode mode;
  final EvidenceExportKind kind;
  final IconData icon;
  final String description;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: ValueKey('evidence-photo-mode-${mode.name}'),
        enabled: !unavailable,
        leading: Icon(icon, color: unavailable ? null : colors.primary),
        title: Text(
          mode.labelFor(kind),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          unavailable ? '$description Bereits erstellt.' : description,
        ),
        trailing: unavailable
            ? const Icon(Icons.check_circle_outline)
            : const Icon(Icons.chevron_right),
        onTap: unavailable ? null : () => Navigator.pop(context, mode),
      ),
    );
  }
}
