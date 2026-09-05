import 'package:flutter/material.dart';

Future<T> runWithPdfExportProgress<T>(
  BuildContext context, {
  required String description,
  required Future<T> Function() operation,
}) async {
  BuildContext? dialogContext;
  final dialogClosed = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      dialogContext = context;
      return PdfExportProgressDialog(description: description);
    },
  );

  await WidgetsBinding.instance.endOfFrame;
  try {
    return await operation();
  } finally {
    final currentDialogContext = dialogContext;
    if (currentDialogContext != null && currentDialogContext.mounted) {
      Navigator.of(currentDialogContext).pop();
    }
    await dialogClosed;
  }
}

class PdfExportProgressDialog extends StatelessWidget {
  const PdfExportProgressDialog({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope<void>(
      canPop: false,
      child: AlertDialog(
        icon: Icon(
          Icons.picture_as_pdf_outlined,
          size: 36,
          color: colors.primary,
        ),
        title: const Text(
          'PDF-Nachweis wird erstellt',
          textAlign: TextAlign.center,
        ),
        content: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(description, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                key: const ValueKey('pdf-export-progress'),
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: colors.primary.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 10),
              Text(
                'Bitte kurz warten …',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
