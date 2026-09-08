import 'package:universal_io/io.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/integrity/integrity_copy.dart';
import '../../../core/integrity/integrity_service.dart';
import '../../../core/files/evidence_photo_asset_repository.dart';
import '../../../core/utils/id_generator.dart';
import '../../meters/application/reading_revision_photos.dart';
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
    EvidencePhotoAssetRepository? photoAssets,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       photoAssets = photoAssets ?? LocalEvidencePhotoAssetRepository();

  final EvidenceExportRepository exports;
  final IntegrityService integrity;
  final DocumentsDirectoryProvider _documentsDirectoryProvider;
  final EvidencePhotoAssetRepository photoAssets;

  Future<void> delete(EvidenceExportRecord record) async {
    final file = File(record.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    await exports.delete(record.id);
  }

  Future<GeneratedEvidenceReport> createSingle({
    required MeterReading reading,
    required List<ReadingRevision> revisions,
    EvidencePhotoMode photoMode = EvidencePhotoMode.allPhotos,
  }) async {
    final reportMeter = reading.meter;
    final manifestSha = await _reportManifestHash(
      [reading],
      {reading.id: revisions},
      reportMeter,
    );
    return _create(
      readings: [reading],
      revisions: {reading.id: revisions},
      kind: EvidenceExportKind.singleReading,
      photoMode: photoMode,
      manifestSha256: manifestSha,
      reportMeter: reportMeter,
    );
  }

  Future<GeneratedEvidenceReport> createHistory({
    required Meter meter,
    required List<MeterReading> readings,
    required Map<String, List<ReadingRevision>> revisions,
    EvidencePhotoMode photoMode = EvidencePhotoMode.allPhotos,
  }) async {
    if (readings.isEmpty) {
      throw StateError('Für diesen Zähler gibt es noch keine Ablesungen.');
    }
    final sortedReadings = [...readings]
      ..sort((left, right) => left.capturedAt.compareTo(right.capturedAt));
    if (sortedReadings.any((reading) => reading.meterId != meter.id)) {
      throw StateError('Die Ablesungen gehören nicht zu diesem Zähler.');
    }
    final reportMeter = MeterSnapshot.fromMeter(meter);
    final manifestSha = await _reportManifestHash(
      sortedReadings,
      revisions,
      reportMeter,
    );
    return _create(
      readings: sortedReadings,
      revisions: revisions,
      kind: EvidenceExportKind.meterHistory,
      photoMode: photoMode,
      manifestSha256: manifestSha,
      reportMeter: reportMeter,
    );
  }

  Future<GeneratedEvidenceReport> _create({
    required List<MeterReading> readings,
    required Map<String, List<ReadingRevision>> revisions,
    required EvidenceExportKind kind,
    required EvidencePhotoMode photoMode,
    required String manifestSha256,
    required MeterSnapshot reportMeter,
  }) async {
    final createdAt = DateTime.now();
    final fonts = await _loadFontBytes();
    final preparedPhotoPaths = await _preparePhotos(
      readings: readings,
      photoMode: photoMode,
    );
    final buildResult = await compute(_buildPdfInBackground, <String, Object?>{
      'readings': readings.map((reading) => reading.toJson()).toList(),
      'revisions': <String, Object?>{
        for (final entry in revisions.entries)
          entry.key: entry.value.map((revision) => revision.toJson()).toList(),
      },
      'kind': kind.name,
      'photoMode': photoMode.name,
      'preparedPhotoPaths': preparedPhotoPaths,
      'createdAtMicroseconds': createdAt.microsecondsSinceEpoch,
      'manifestSha256': manifestSha256,
      'reportMeter': reportMeter.toJson(),
      'regularFontBytes': fonts.regular,
      'boldFontBytes': fonts.bold,
    }, debugLabel: 'evidence-pdf-builder');
    final bytes = buildResult['bytes']! as Uint8List;
    final manifestSha = buildResult['manifestSha256']! as String;
    final pdfSha = buildResult['pdfSha256']! as String;
    final id = newLocalId('evidence', now: createdAt);
    final safeLabel = _safeFilePart(reportMeter.label);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(createdAt);
    final uniqueSuffix = id.substring(id.length - 6);
    final variant = switch (photoMode) {
      EvidencePhotoMode.withoutPhotos => 'kompakt',
      EvidencePhotoMode.currentPhotos => 'mit_fotos',
      EvidencePhotoMode.allPhotos => 'alle_fotos',
    };
    final fileName = kind == EvidenceExportKind.singleReading
        ? 'zaehlerstand_${safeLabel}_${variant}_${stamp}_$uniqueSuffix.pdf'
        : 'zaehlerverlauf_${safeLabel}_${variant}_${stamp}_$uniqueSuffix.pdf';
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
      photoMode: photoMode,
    );
    await exports.save(record);
    return GeneratedEvidenceReport(record: record, bytes: bytes);
  }

  Future<Map<String, String>> _preparePhotos({
    required List<MeterReading> readings,
    required EvidencePhotoMode photoMode,
  }) async {
    if (photoMode == EvidencePhotoMode.withoutPhotos) {
      return const <String, String>{};
    }
    final versions = <ReadingPhotoVersion>[
      for (final reading in readings)
        if (photoMode == EvidencePhotoMode.currentPhotos)
          reading.currentPhotoVersion
        else
          ...reading.allPhotoVersions,
    ];
    final versionsByHash = <String, List<ReadingPhotoVersion>>{};
    for (final version in versions) {
      versionsByHash.putIfAbsent(version.sha256, () => []).add(version);
    }
    final prepared = <String, String>{};
    final groups = versionsByHash.entries.toList(growable: false);
    for (var offset = 0; offset < groups.length; offset += 2) {
      final batch = groups.skip(offset).take(2).toList(growable: false);
      final paths = await Future.wait(
        batch.map((group) {
          final representative = group.value.first;
          return photoAssets.prepare(
            path: representative.path,
            sha256: representative.sha256,
          );
        }),
      );
      for (var index = 0; index < batch.length; index++) {
        final path = paths[index];
        if (path == null) continue;
        for (final version in batch[index].value) {
          prepared[version.path] = path;
        }
      }
    }
    return prepared;
  }

  static Future<Map<String, Object?>> _buildPdfInBackground(
    Map<String, Object?> message,
  ) async {
    final readings = (message['readings']! as List)
        .map(
          (json) =>
              MeterReading.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList(growable: false);
    final revisionData = Map<String, Object?>.from(
      message['revisions']! as Map,
    );
    final revisions = <String, List<ReadingRevision>>{
      for (final entry in revisionData.entries)
        entry.key: (entry.value! as List)
            .map(
              (json) => ReadingRevision.fromJson(
                Map<String, dynamic>.from(json as Map),
              ),
            )
            .toList(growable: false),
    };
    final kind = EvidenceExportKind.values.byName(message['kind']! as String);
    final photoMode = EvidencePhotoMode.values.byName(
      message['photoMode']! as String,
    );
    final photoAssets = _PdfPhotoAssets(
      Map<String, String>.from(message['preparedPhotoPaths']! as Map),
    );
    final reportMeter = MeterSnapshot.fromJson(
      Map<String, dynamic>.from(message['reportMeter']! as Map),
    );
    final createdAt = DateTime.fromMicrosecondsSinceEpoch(
      message['createdAtMicroseconds']! as int,
    );
    final regularFontBytes = message['regularFontBytes']! as Uint8List;
    final boldFontBytes = message['boldFontBytes']! as Uint8List;
    final fonts = _ReportFonts(
      regular: pw.Font.ttf(ByteData.sublistView(regularFontBytes)),
      bold: pw.Font.ttf(ByteData.sublistView(boldFontBytes)),
    );
    final manifestSha = message['manifestSha256']! as String;
    final document = pw.Document(
      title: kind == EvidenceExportKind.singleReading
          ? 'Zählerstand-Nachweis'
          : 'Zählerstand-Verlauf',
      author: 'ZählerstandLog',
      subject: 'Private Dokumentation eines Zählerstands',
    );
    final date = DateFormat('dd.MM.yyyy, HH:mm');

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
            '${reportMeter.type.label} · ${reportMeter.label}',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 18),
          _meterTable(reportMeter),
          pw.SizedBox(height: 12),
          _photoModeBox(photoMode),
          pw.SizedBox(height: 14),
          if (kind == EvidenceExportKind.meterHistory)
            _historyTable(readings, date),
          if (kind == EvidenceExportKind.singleReading)
            ..._readingSection(
              reading: readings.single,
              revisions: revisions[readings.single.id] ?? const [],
              date: date,
              includeHeading: false,
              photoMode: photoMode,
              photoAssets: photoAssets,
            ),
          if (kind == EvidenceExportKind.meterHistory) ...[
            pw.NewPage(),
            pw.Text(
              photoMode == EvidencePhotoMode.withoutPhotos
                  ? 'Details und Korrekturen'
                  : 'Aktuelle Fotos und Details',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            for (final reading in readings) ...[
              ..._readingSection(
                reading: reading,
                revisions: revisions[reading.id] ?? const [],
                date: date,
                includeHeading: true,
                photoMode: photoMode,
                photoAssets: photoAssets,
              ),
              pw.SizedBox(height: 20),
            ],
          ],
          pw.SizedBox(height: 18),
          _documentInfoBox(
            generatedAt: createdAt,
            date: date,
            photoMode: photoMode,
            kind: kind,
          ),
        ],
      ),
    );

    final bytes = await document.save();
    final pdfSha = await const IntegrityService().sha256Bytes(bytes);
    return <String, Object?>{
      'bytes': bytes,
      'manifestSha256': manifestSha,
      'pdfSha256': pdfSha,
    };
  }

  static Future<String> _reportManifestHash(
    List<MeterReading> readings,
    Map<String, List<ReadingRevision>> revisions,
    MeterSnapshot reportMeter,
  ) async {
    const integrity = IntegrityService();
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
        'schema': 'meter_reading_evidence_v3',
        'reportMeter': reportMeter.toJson(),
        'readings': normalizedReadings,
        'revisions': normalizedRevisions,
      }),
    );
  }

  static pw.Widget _meterTable(MeterSnapshot meter) {
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

  static pw.Widget _historyTable(List<MeterReading> readings, DateFormat date) {
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

  static List<pw.Widget> _readingSection({
    required MeterReading reading,
    required List<ReadingRevision> revisions,
    required DateFormat date,
    required bool includeHeading,
    required EvidencePhotoMode photoMode,
    required _PdfPhotoAssets photoAssets,
  }) {
    return [
      if (includeHeading)
        pw.Text(
          '${date.format(reading.capturedAt.toLocal())} · ${reading.value.displayText} ${reading.meter.unit}',
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
      if (includeHeading) pw.SizedBox(height: 8),
      if (photoMode != EvidencePhotoMode.withoutPhotos) ...[
        pw.Text(
          photoMode == EvidencePhotoMode.allPhotos &&
                  reading.photoHistory.isEmpty
              ? 'Nachweisfoto'
              : 'Aktuelles Nachweisfoto',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        _photo(reading.photoPath, photoAssets),
        pw.SizedBox(height: 10),
      ],
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
      if (revisions.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Text(
          'Korrekturverlauf',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        for (final revision in ([
          ...revisions,
        ]..sort((left, right) => right.changedAt.compareTo(left.changedAt))))
          _revisionSection(
            revision: revision,
            reading: reading,
            date: date,
            photoMode: photoMode,
            photoAssets: photoAssets,
          ),
      ],
    ];
  }

  static pw.Widget _revisionSection({
    required ReadingRevision revision,
    required MeterReading reading,
    required DateFormat date,
    required EvidencePhotoMode photoMode,
    required _PdfPhotoAssets photoAssets,
  }) {
    final visibleChanges = visibleRevisionChanges(
      revision,
    ).toList(growable: false);
    final revisionPhotos = photosForRevision(
      reading: reading,
      revision: revision,
    );
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Korrektur vom ${date.format(revision.changedAt.toLocal())}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          if (revision.reason.trim().isNotEmpty)
            pw.Text(
              'Grund: ${revision.reason.trim()}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          for (final change in visibleChanges) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              change.key,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Vorher: ${_revisionValue(change.key, change.value.before, reading.meter.unit, date)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Neu: ${_revisionValue(change.key, change.value.after, reading.meter.unit, date)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
          if (revisionPhotos != null &&
              photoMode == EvidencePhotoMode.allPhotos) ...[
            pw.SizedBox(height: 4),
            _revisionPhotoComparison(
              photos: revisionPhotos,
              date: date,
              photoAssets: photoAssets,
            ),
          ] else if (revisionPhotos != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Nachweisfoto geändert',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _revisionPhotoComparison({
    required ReadingRevisionPhotos photos,
    required DateFormat date,
    required _PdfPhotoAssets photoAssets,
  }) {
    final before = photos.before;
    final after = photos.after;
    if (before == null && after == null) {
      return pw.Text(
        'Nachweisfoto geändert',
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (before != null)
              pw.Expanded(
                child: _revisionPhoto(
                  label: 'Vorheriges Foto',
                  photo: before,
                  date: date,
                  photoAssets: photoAssets,
                ),
              ),
            if (before != null && after != null) pw.SizedBox(width: 8),
            if (after != null)
              pw.Expanded(
                child: _revisionPhoto(
                  label: 'Neues Foto',
                  photo: after,
                  date: date,
                  photoAssets: photoAssets,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _revisionPhoto({
    required String label,
    required ReadingPhotoVersion photo,
    required DateFormat date,
    required _PdfPhotoAssets photoAssets,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        _photo(photo.path, photoAssets, height: 120),
        pw.SizedBox(height: 3),
        pw.Text(
          '${photo.source.label} · ${date.format(photo.addedAt.toLocal())}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ],
    );
  }

  static String _revisionValue(
    String key,
    String value,
    String unit,
    DateFormat date,
  ) {
    if (value.trim().isEmpty) return 'Keine Angabe';
    if (key == 'Zeitpunkt der Ablesung') {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return date.format(parsed.toLocal());
    }
    if (key == 'Zählerstand') return '$value $unit';
    return value;
  }

  static pw.Widget _photo(
    String path,
    _PdfPhotoAssets photoAssets, {
    double height = 280,
  }) {
    try {
      final image = photoAssets.image(path);
      return pw.Container(
        height: height,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Image(image, fit: pw.BoxFit.contain),
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

  static pw.Widget _documentInfoBox({
    required DateTime generatedAt,
    required DateFormat date,
    required EvidencePhotoMode photoMode,
    required EvidenceExportKind kind,
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
            'Dokumentinformationen',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('PDF erstellt am ${date.format(generatedAt)}'),
          pw.Text('Variante: ${photoMode.labelFor(kind)}'),
          pw.SizedBox(height: 6),
          pw.Text(
            privateDocumentationText,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _photoModeBox(EvidencePhotoMode photoMode) {
    final text = switch (photoMode) {
      EvidencePhotoMode.withoutPhotos =>
        'Kompakte Variante: Die gespeicherten Foto-Dateien sind nicht in dieser PDF enthalten.',
      EvidencePhotoMode.currentPhotos =>
        'Foto-Variante: Pro Ablesung ist das aktuell zugeordnete Nachweisfoto enthalten.',
      EvidencePhotoMode.allPhotos =>
        'Ältere Foto-Variante: Aktuelle und frühere Nachweisfotos können enthalten sein.',
    };
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(9),
      color: PdfColors.grey200,
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  Future<_ReportFontBytes> _loadFontBytes() async {
    final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    return _ReportFontBytes(
      regular: regular.buffer.asUint8List(
        regular.offsetInBytes,
        regular.lengthInBytes,
      ),
      bold: bold.buffer.asUint8List(bold.offsetInBytes, bold.lengthInBytes),
    );
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

  static String _offset(int minutes) {
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

class _ReportFontBytes {
  const _ReportFontBytes({required this.regular, required this.bold});

  final Uint8List regular;
  final Uint8List bold;
}

class _PdfPhotoAssets {
  _PdfPhotoAssets(this.preparedPaths);

  final Map<String, String> preparedPaths;
  final Map<String, pw.MemoryImage> _images = {};

  pw.MemoryImage image(String originalPath) {
    return _images.putIfAbsent(originalPath, () {
      final preparedPath = preparedPaths[originalPath];
      if (preparedPath == null) {
        throw StateError('Keine vorbereitete Fotodatei vorhanden.');
      }
      return pw.MemoryImage(File(preparedPath).readAsBytesSync());
    });
  }
}
