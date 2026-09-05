import 'dart:async';

import 'package:flutter/material.dart';

Future<T> runWithPdfExportProgress<T>(
  BuildContext context, {
  required String description,
  required Future<T> Function() operation,
}) async {
  BuildContext? dialogContext;
  final presented = Completer<void>();
  final dialogClosed = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      dialogContext = context;
      return PdfExportProgressDialog(
        description: description,
        onPresented: () {
          if (!presented.isCompleted) presented.complete();
        },
      );
    },
  );

  await presented.future;
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

class PdfExportProgressDialog extends StatefulWidget {
  const PdfExportProgressDialog({
    super.key,
    required this.description,
    this.onPresented,
  });

  final String description;
  final VoidCallback? onPresented;

  @override
  State<PdfExportProgressDialog> createState() =>
      _PdfExportProgressDialogState();
}

class _PdfExportProgressDialogState extends State<PdfExportProgressDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPresented?.call();
    });
  }

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
              Text(widget.description, textAlign: TextAlign.center),
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
