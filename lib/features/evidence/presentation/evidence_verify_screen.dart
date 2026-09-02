import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/integrity/integrity_copy.dart';
import '../../../core/utils/formatters.dart';
import '../../meters/application/meter_services.dart';

class EvidenceVerifyScreen extends ConsumerStatefulWidget {
  const EvidenceVerifyScreen({super.key});

  @override
  ConsumerState<EvidenceVerifyScreen> createState() =>
      _EvidenceVerifyScreenState();
}

class _EvidenceVerifyScreenState extends ConsumerState<EvidenceVerifyScreen> {
  EvidenceVerificationResult? _result;
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(pdfVerificationTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pdfVerificationTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(pdfVerificationText),
                  const SizedBox(height: 8),
                  Text(
                    privateDocumentationText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _working ? null : _pickAndVerify,
            icon: _working
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: const Text('PDF auswählen'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndVerify() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _working = true);
    try {
      final verification = await ref
          .read(evidenceReportServiceProvider)
          .verify(path);
      if (mounted) setState(() => _result = verification);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF konnte nicht geprüft werden: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final EvidenceVerificationResult result;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, message) = switch (result.status) {
      EvidenceVerificationStatus.unchanged => (
        Icons.verified_outlined,
        const Color(0xFF087F5B),
        pdfMatchesTitle,
        pdfMatchesText,
      ),
      EvidenceVerificationStatus.changed => (
        Icons.warning_amber_outlined,
        Theme.of(context).colorScheme.error,
        pdfChangedTitle,
        pdfChangedText,
      ),
      EvidenceVerificationStatus.unknown => (
        Icons.help_outline,
        Theme.of(context).colorScheme.tertiary,
        pdfUnknownTitle,
        pdfUnknownText,
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(message),
            if (result.record != null) ...[
              const SizedBox(height: 10),
              Text('Export: ${result.record!.fileName}'),
              Text('Erstellt: ${formatDateTime(result.record!.createdAt)}'),
            ],
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                leading: const Icon(Icons.fingerprint),
                title: const Text('Technischen PDF-Prüfwert anzeigen'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      'Prüfwert der PDF (SHA-256)\n${result.sha256}',
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
