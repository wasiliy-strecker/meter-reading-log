import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meter_reading_log/features/evidence/application/evidence_report_service.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import '../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates and verifies a persistent single-reading PDF', () async {
    final temp = await Directory.systemTemp.createTemp('evidence_test_');
    addTearDown(() => temp.delete(recursive: true));
    final photo = File('${temp.path}/photo.jpg');
    await photo.writeAsBytes(img.encodeJpg(img.Image(width: 20, height: 20)));
    final repository = MemoryEvidenceExportRepository();
    final service = EvidenceReportService(
      exports: repository,
      documentsDirectoryProvider: () async => temp,
    );
    final reading = _reading(photo.path);

    final report = await service.createSingle(
      reading: reading,
      revisions: const [],
    );

    expect(report.bytes.take(4), [0x25, 0x50, 0x44, 0x46]);
    expect(await File(report.record.filePath).exists(), isTrue);
    final verified = await service.verify(report.record.filePath);
    expect(verified.status.name, 'unchanged');

    await File(report.record.filePath).writeAsString('changed');
    final changed = await service.verify(report.record.filePath);
    expect(changed.status.name, 'changed');
  });
}

MeterReading _reading(String photoPath) {
  final meter = Meter(
    id: 'meter_1',
    label: 'Strom Keller',
    type: MeterType.electricity,
    unit: 'kWh',
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );
  return MeterReading(
    id: 'reading_1',
    meterId: meter.id,
    meter: MeterSnapshot.fromMeter(meter),
    value: ReadingValue.tryParse('00123,4')!,
    capturedAt: DateTime.utc(2026, 8, 31, 10),
    timezoneOffsetMinutes: 120,
    storedAt: DateTime.utc(2026, 8, 31, 10),
    updatedAt: DateTime.utc(2026, 8, 31, 10),
    source: ReadingSource.camera,
    photoPath: photoPath,
    photoSha256: 'a' * 64,
    ocrRawText: '00123,4 kWh',
    ocrCandidate: '00123,4',
    ocrConfidence: 0.92,
    manifestSha256: 'b' * 64,
  );
}
