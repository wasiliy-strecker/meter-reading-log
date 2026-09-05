import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../application/evidence_report_service.dart';

class EvidencePreviewScreen extends StatelessWidget {
  const EvidencePreviewScreen({super.key, required this.report});

  final GeneratedEvidenceReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF-Nachweis')),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (_) async => report.bytes,
              pdfFileName: report.record.fileName,
              allowSharing: false,
              allowPrinting: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Printing.layoutPdf(
                            name: report.record.fileName,
                            onLayout: (_) async => report.bytes,
                          ),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Drucken'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(
                              title: 'Zählerstand-Nachweis',
                              text: 'PDF-Nachweis aus ZählerstandLog',
                              files: [
                                XFile(
                                  File(report.record.filePath).path,
                                  mimeType: 'application/pdf',
                                  name: report.record.fileName,
                                ),
                              ],
                            ),
                          ),
                          icon: const Icon(Icons.ios_share_outlined),
                          label: const Text('Teilen'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
