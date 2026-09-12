import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_io/io.dart';

import '../../../core/utils/formatters.dart';
import '../domain/meter_reading.dart';
import 'meter_visuals.dart';

class ReadingHistoryTile extends StatelessWidget {
  const ReadingHistoryTile({
    super.key,
    this.onTap,
    required this.reading,
    required this.showDelta,
    this.previous,
  });

  final VoidCallback? onTap;
  final MeterReading reading;
  final MeterReading? previous;
  final bool showDelta;

  @override
  Widget build(BuildContext context) {
    final meterAccent = meterColor(reading.meter.type);
    final sameUnit =
        previous == null || previous!.meter.unit == reading.meter.unit;
    final delta = !showDelta || previous == null || !sameUnit
        ? null
        : reading.value.difference(previous!.value).germanFormatted;
    return Card(
      key: ValueKey('reading-card-${reading.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            onTap ??
            () => context.pushNamed(
              'readingDetail',
              pathParameters: {'id': reading.id},
            ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Abgelesen am ${formatDateTime(reading.capturedAt)} Uhr',
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    key: ValueKey('reading-date-badge-${reading.id}'),
                    decoration: BoxDecoration(
                      color: meterAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 17,
                            color: meterAccent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Abgelesen · ${formatDateTime(reading.capturedAt)} Uhr',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: meterAccent,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ReadingPhotoThumbnail(reading: reading),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zählerstand',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${reading.value.displayText} ${reading.meter.unit}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        if (showDelta && previous != null && !sameUnit) ...[
                          const SizedBox(height: 8),
                          const Text('Einheit seit dieser Ablesung gewechselt'),
                        ] else if (delta != null) ...[
                          const SizedBox(height: 8),
                          Text('Δ $delta ${reading.meter.unit}'),
                        ],
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
              if (reading.note.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reading.note.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
