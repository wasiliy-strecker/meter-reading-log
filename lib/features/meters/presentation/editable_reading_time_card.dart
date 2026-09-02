import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';

DateTime get firstSelectableReadingDate => DateTime(2000);

DateTime get lastSelectableReadingDate => DateTime(2100, 12, 31);

bool isFutureReadingTime(DateTime value, {DateTime? comparedTo}) {
  return value.isAfter(comparedTo ?? DateTime.now());
}

Future<bool> confirmFutureReadingTime(
  BuildContext context,
  DateTime value,
) async {
  if (!isFutureReadingTime(value)) return true;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Zukünftigen Zeitpunkt speichern?'),
          content: const Text(
            'Der Zeitpunkt der Ablesung liegt in der Zukunft. Diese Angabe wird im Datensatz und im PDF-Nachweis ausdrücklich gekennzeichnet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Trotzdem speichern'),
            ),
          ],
        ),
      ) ??
      false;
}

class EditableReadingTimeCard extends StatelessWidget {
  const EditableReadingTimeCard({
    super.key,
    required this.value,
    required this.onPressed,
  });

  final DateTime value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isFuture = isFutureReadingTime(value);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zeitpunkt der Ablesung',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(formatDateTime(value)),
                    ],
                  ),
                ),
              ],
            ),
            if (isFuture) ...[
              const SizedBox(height: 12),
              const FutureReadingTimeNotice(
                message:
                    'Dieser Ablesezeitpunkt liegt in der Zukunft. Er wird im PDF-Nachweis entsprechend gekennzeichnet.',
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Datum & Uhrzeit ändern'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FutureReadingTimeNotice extends StatelessWidget {
  const FutureReadingTimeNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.event_busy_outlined, color: colors.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
