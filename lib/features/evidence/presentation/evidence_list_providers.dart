import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_io/io.dart';

import '../../../app/app_providers.dart';
import '../domain/evidence_export.dart';
import '../domain/evidence_export_page.dart';

typedef EvidenceExportPageRequest = ({
  String meterId,
  EvidenceExportKind kind,
  int limit,
  int offset,
});

final evidenceExportPageProvider = StreamProvider.autoDispose
    .family<EvidenceExportPage, EvidenceExportPageRequest>(
      (ref, request) => ref
          .watch(evidenceExportRepositoryProvider)
          .watchPageForMeter(
            request.meterId,
            kind: request.kind,
            limit: request.limit,
            offset: request.offset,
          ),
    );

final evidenceFileAvailableProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, path) => File(path).exists());
