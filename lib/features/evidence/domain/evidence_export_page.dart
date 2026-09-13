import 'evidence_export.dart';

class EvidenceExportPage {
  const EvidenceExportPage({
    required this.exports,
    required this.totalCount,
    required this.offset,
  });

  final List<EvidenceExportRecord> exports;
  final int totalCount;
  final int offset;

  bool get hasMore => offset + exports.length < totalCount;
}

int compareExportsNewestFirst(EvidenceExportRecord a, EvidenceExportRecord b) {
  final dateOrder = b.createdAt.compareTo(a.createdAt);
  return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
}
