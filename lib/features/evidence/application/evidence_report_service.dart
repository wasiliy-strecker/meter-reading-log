import 'package:universal_io/io.dart';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/integrity/integrity_copy.dart';
import '../../../core/integrity/integrity_service.dart';
import '../../../core/utils/id_generator.dart';
import '../../meters/application/meter_services.dart';
import '../../meters/domain/meter.dart';
import '../../meters/domain/meter_reading.dart';
import '../../meters/domain/meter_repositories.dart';
import '../domain/evidence_export.dart';

class GeneratedEvidenceReport {
  const GeneratedEvidenceReport({required this.record, required this.bytes});

  final EvidenceExportRecord record;
  final Uint8List bytes;
}

typedef DocumentsDirectoryProvider = Future<Directory> Function();

String? futureReadingEvidenceNotice(MeterReading reading) {
  if (!reading.wasFutureAtStorage) return null;
  return 'Beim Speichern lag der angegebene Ablesezeitpunkt in der Zukunft.';
}

class EvidenceReportService {
  EvidenceReportService({
    required this.exports,
    this.integrity = const IntegrityService(),
    DocumentsDirectoryProvider? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final EvidenceExportRepository exports;
  final IntegrityService integrity;
  final DocumentsDirectoryProvider _documentsDirectoryProvider;

  Future<GeneratedEvidenceReport> createSingle({
    required MeterReading reading,
    required List<ReadingRevision> revisions,
  }) async {
    return _create(
      readings: [reading],
      revisions: {reading.id: revisions},
      kind: EvidenceExportKind.singleReading,
    );
  }

  Future<GeneratedEvidenceReport> createHistory({
    required List<MeterReading> readings,
    required Map<String, List<ReadingRevision>> revisions,
  }) async {
    if (readings.isEmpty) {
      throw StateError('Für diesen Zähler gibt es noch keine Ablesungen.');
    }
    return _create(
      readings: [...readings]
        ..sort((left, right) => left.capturedAt.compareTo(right.capturedAt)),
      revisions: revisions,
      kind: EvidenceExportKind.meterHistory,
    );
  }

  Future<GeneratedEvidenceReport> _create({
    required List<MeterReading> readings,
    required Map<String, List<ReadingRevision>> revisions,
    required EvidenceExportKind kind,
  }) async {
    final createdAt = DateTime.now();
    final manifestSha = await _reportManifestHash(readings, revisions);
    final fonts = await _loadFonts();
    final document = pw.Document(
      title: kind == EvidenceExportKind.singleReading
          ? 'Zählerstand-Nachweis'
          : 'Zählerstand-Verlauf',
      author: 'ZählerstandLog',
      subject: 'Private Dokumentation eines Zählerstands',
    );
    final date = DateFormat('dd.MM.yyyy, HH:mm');
    final meter = readings.first.meter;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ZÄHLERSTANDLOG',
              style: pw.TextStyle(
                color: PdfColor.fromHex('#075E54'),
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
            pw.Text(
              'Seite ${context.pageNumber} von ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
        footer: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            pdfPrivateDocumentationText,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 16),
          pw.Text(
            kind == EvidenceExportKind.singleReading
                ? 'Zählerstand-Nachweis'
                : 'Zählerstand-Verlauf',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${meter.type.label} · ${meter.label}',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 18),
          _meterTable(readings.first),
          pw.SizedBox(height: 14),
          if (kind == EvidenceExportKind.meterHistory)
            _historyTable(readings, date),
          if (kind == EvidenceExportKind.singleReading)
            ..._readingSection(
              reading: readings.single,
              revisions: revisions[readings.single.id] ?? const [],
              date: date,
              includeHeading: false,
            ),
          if (kind == EvidenceExportKind.meterHistory) ...[
            pw.NewPage(),
            pw.Text(
              'Fotoanhang und Prüfdaten',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            for (final reading in readings) ...[
              ..._readingSection(
                reading: reading,
                revisions: revisions[reading.id] ?? const [],
                date: date,
                includeHeading: true,
              ),
              pw.SizedBox(height: 20),
            ],
          ],
          pw.SizedBox(height: 18),
          _integrityBox(
            manifestSha: manifestSha,
            generatedAt: createdAt,
            date: date,
          ),
        ],
      ),
    );

    final bytes = await document.save();
    final pdfSha = await integrity.sha256Bytes(bytes);
    final id = newLocalId('evidence');
    final safeLabel = _safeFilePart(meter.label);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(createdAt);
    final fileName = kind == EvidenceExportKind.singleReading
        ? 'zaehlerstand_${safeLabel}_$stamp.pdf'
        : 'zaehlerverlauf_${safeLabel}_$stamp.pdf';
    final directory = Directory(
      p.join((await _documentsDirectoryProvider()).path, 'evidence_reports'),
    );
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    final record = EvidenceExportRecord(
      id: id,
      meterId: readings.first.meterId,
      kind: kind,
      readingIds: readings.map((reading) => reading.id).toList(),
      createdAt: createdAt.toUtc(),
      fileName: fileName,
      filePath: file.path,
      pdfSha256: pdfSha,
      manifestSha256: manifestSha,
    );
    await exports.save(record);
    return GeneratedEvidenceReport(record: record, bytes: bytes);
  }

  Future<EvidenceVerificationResult> verify(String path) async {
    final bytes = await File(path).readAsBytes();
    final hash = await integrity.sha256Bytes(bytes);
    final record = await exports.findByPdfHash(hash);
    final sameName = record == null
        ? await exports.findByFileName(p.basename(path))
        : null;
    return EvidenceVerificationResult(
      sha256: hash,
      status: record != null
          ? EvidenceVerificationStatus.unchanged
          : sameName != null
          ? EvidenceVerificationStatus.changed
          : EvidenceVerificationStatus.unknown,
      record: record ?? sameName,
    );
  }

  Future<String> _reportManifestHash(
    List<MeterReading> readings,
    Map<String, List<ReadingRevision>> revisions,
  ) async {
    final normalizedReadings = readings.map((reading) {
      return integrity.normalizedReadingData(reading);
    }).toList();
    final normalizedRevisions = <String, Object?>{
      for (final reading in readings)
        reading.id: (revisions[reading.id] ?? const [])
            .map((revision) => revision.toJson())
            .toList(),
    };
    return integrity.sha256Text(
      integrity.canonicalJson({
        'schema': 'meter_reading_evidence_v2',
        'readings': normalizedReadings,
        'revisions': normalizedRevisions,
      }),
    );
  }

  pw.Widget _meterTable(MeterReading reading) {
    final meter = reading.meter;
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      data: [
        ['Zählerart', meter.type.label],
        ['Bezeichnung', meter.label],
        [
          'Zählernummer',
          meter.meterNumber.isEmpty ? 'Nicht angegeben' : meter.meterNumber,
        ],
        [
          'Standort',
          meter.location.isEmpty ? 'Nicht angegeben' : meter.location,
        ],
        ['Einheit', meter.unit],
      ],
    );
  }

  pw.Widget _historyTable(List<MeterReading> readings, DateFormat date) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Ablesezeitpunkt', 'Zählerstand', 'Differenz', 'Quelle'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#D7EEE9')),
      cellPadding: const pw.EdgeInsets.all(6),
      data: [
        for (var index = 0; index < readings.length; index++)
          [
            '${date.format(readings[index].capturedAt.toLocal())}'
                '${readings[index].wasFutureAtStorage ? '\nBei Speicherung zukünftig' : ''}',
            '${readings[index].value.displayText} ${readings[index].meter.unit}',
            index == 0
                ? '–'
                : readings[index].meter.unit != readings[index - 1].meter.unit
                ? '– (Einheit gewechselt)'
                : '${readings[index].value.difference(readings[index - 1].value).germanFormatted} ${readings[index].meter.unit}',
            readings[index].source.label,
          ],
      ],
    );
  }

  List<pw.Widget> _readingSection({
    required MeterReading reading,
    required List<ReadingRevision> revisions,
    required DateFormat date,
    required bool includeHeading,
  }) {
    return [
      if (includeHeading)
        pw.Text(
          '${date.format(reading.capturedAt.toLocal())} · ${reading.value.displayText} ${reading.meter.unit}',
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
      if (includeHeading) pw.SizedBox(height: 8),
      pw.Text(
        reading.photoHistory.isEmpty
            ? 'Nachweisfoto'
            : 'Aktuelles Nachweisfoto',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      _photo(reading.photoPath),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        data: [
          [
            'Bestätigter Stand',
            '${reading.value.displayText} ${reading.meter.unit}',
          ],
          [
            'Zeitpunkt der Ablesung',
            '${date.format(reading.capturedAt.toLocal())} (${_offset(reading.timezoneOffsetMinutes)})',
          ],
          ['Gespeichert', date.format(reading.storedAt.toLocal())],
          [
            'Aktuelles Foto hinzugefügt',
            date.format(reading.effectivePhotoAddedAt.toLocal()),
          ],
          if (futureReadingEvidenceNotice(reading) case final notice?)
            ['Hinweis', notice],
          ['Quelle', reading.source.label],
          [
            'OCR-Kandidat',
            reading.ocrCandidate.isEmpty ? 'Keiner' : reading.ocrCandidate,
          ],
          [
            'OCR-Konfidenz',
            reading.ocrConfidence == null
                ? 'Nicht verfügbar'
                : '${(reading.ocrConfidence! * 100).round()} %',
          ],
          ['Manuell abweichend', reading.wasManuallyCorrected ? 'Ja' : 'Nein'],
          if (reading.lowerReadingReason != null)
            ['Niedrigerer Stand', reading.lowerReadingReason!.label],
          if (reading.note.isNotEmpty) ['Notiz', reading.note],
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Prüfwert des Fotos (SHA-256): ${reading.photoSha256}',
        style: _hashStyle,
      ),
      pw.Text(
        'Prüfwert der Ablesung (SHA-256): ${reading.manifestSha256}',
        style: _hashStyle,
      ),
      for (final entry in reading.photoHistory.indexed) ...[
        pw.SizedBox(height: 14),
        pw.Text(
          entry.$1 == 0
              ? 'Ursprüngliches Foto'
              : 'Frühere Foto-Version ${entry.$1 + 1}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        _photo(entry.$2.path),
        pw.SizedBox(height: 6),
        pw.Text(
          '${entry.$2.source.label} · hinzugefügt ${date.format(entry.$2.addedAt.toLocal())}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          'Prüfwert des Fotos (SHA-256): ${entry.$2.sha256}',
          style: _hashStyle,
        ),
      ],
      if (revisions.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Text(
          'Änderungsprotokoll',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        for (final revision in revisions)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              '${date.format(revision.changedAt.toLocal())}: ${revision.reason} · '
              '${revision.changes.entries.map((entry) => '${entry.key}: „${entry.value.before}“ → „${entry.value.after}“').join('; ')}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
      ],
    ];
  }

  pw.Widget _photo(String path) {
    try {
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const FormatException('Bildformat nicht lesbar');
      }
      final normalized = img.encodeJpg(decoded, quality: 88);
      return pw.Container(
        height: 280,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Image(pw.MemoryImage(normalized), fit: pw.BoxFit.contain),
      );
    } on Object {
      return pw.Container(
        height: 80,
        alignment: pw.Alignment.center,
        color: PdfColors.grey200,
        child: pw.Text('Originalfoto konnte nicht eingebettet werden.'),
      );
    }
  }

  pw.Widget _integrityBox({
    required String manifestSha,
    required DateTime generatedAt,
    required DateFormat date,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EEF7F5'),
        border: pw.Border.all(color: PdfColor.fromHex('#77AFA3')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            integrityProtectionTitle,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Bericht erzeugt: ${date.format(generatedAt)}'),
          pw.Text(
            'Prüfwert der enthaltenen Daten (SHA-256): $manifestSha',
            style: _hashStyle,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '$pdfIntegrityExplanation $integrityLimitationText',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.TextStyle get _hashStyle =>
      const pw.TextStyle(fontSize: 8, color: PdfColors.grey800);

  Future<_ReportFonts> _loadFonts() async {
    final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    return _ReportFonts(regular: pw.Font.ttf(regular), bold: pw.Font.ttf(bold));
  }

  String _safeFilePart(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'zaehler' : normalized;
  }

  String _offset(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final absolute = minutes.abs();
    return 'UTC$sign${(absolute ~/ 60).toString().padLeft(2, '0')}:'
        '${(absolute % 60).toString().padLeft(2, '0')}';
  }
}

class _ReportFonts {
  const _ReportFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}
