import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/integrity/integrity_copy.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';
import 'package:meter_reading_log/features/meters/presentation/reading_detail_screen.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('hides OCR diagnostics and explains change protection', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final reading = _reading();
    final readings = MemoryReadingRepository()..items[reading.id] = reading;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterReadingRepositoryProvider.overrideWithValue(readings),
          evidenceExportRepositoryProvider.overrideWithValue(
            MemoryEvidenceExportRepository(),
          ),
        ],
        child: MaterialApp(home: ReadingDetailScreen(readingId: reading.id)),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(scrollable, findsOneWidget);
    expect(find.text('OCR-Kandidat'), findsNothing);
    expect(find.text('OCR-Konfidenz'), findsNothing);
    expect(find.text('Manuell abweichend'), findsNothing);

    await tester.scrollUntilVisible(
      find.text(integrityProtectionTitle),
      250,
      scrollable: scrollable,
    );
    expect(find.text(integrityBenefitText), findsOneWidget);
    expect(find.text(integrityLimitationText), findsOneWidget);
    expect(find.text(technicalChecksTitle), findsOneWidget);
    expect(find.textContaining(reading.photoSha256), findsNothing);

    await tester.ensureVisible(find.text(technicalChecksTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(technicalChecksTitle));
    await tester.pumpAndSettle();
    expect(find.textContaining(reading.photoSha256), findsOneWidget);
    expect(find.textContaining(reading.manifestSha256), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(pdfPurposeTitle),
      250,
      scrollable: scrollable,
    );
    expect(find.text(pdfPurposeText), findsOneWidget);
    expect(find.text(privateDocumentationText), findsOneWidget);
    expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
  });
}

MeterReading _reading() {
  final meter = Meter(
    id: 'meter_1',
    label: 'Wasser Bad',
    type: MeterType.water,
    unit: 'm³',
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 1),
  );
  return MeterReading(
    id: 'reading_1',
    meterId: meter.id,
    meter: MeterSnapshot.fromMeter(meter),
    value: ReadingValue.tryParse('42,1')!,
    capturedAt: DateTime.utc(2026, 9, 2, 10),
    timezoneOffsetMinutes: 120,
    storedAt: DateTime.utc(2026, 9, 2, 10),
    updatedAt: DateTime.utc(2026, 9, 2, 10),
    source: ReadingSource.camera,
    photoPath: '/tmp/photo.jpg',
    photoSha256: 'a' * 64,
    ocrRawText: '42,1',
    ocrCandidate: '42,1',
    manifestSha256: 'b' * 64,
  );
}
