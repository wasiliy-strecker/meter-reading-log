import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/ocr/meter_ocr_repository.dart';

void main() {
  test('ranks a large dense meter reading before smaller numbers', () {
    final result = const MeterReadingCandidateExtractor().extract(const [
      OcrCandidateLine(text: 'Zähler 12345678', confidence: 0.8, height: 14),
      OcrCandidateLine(text: '001234,5 kWh', confidence: 0.94, height: 42),
      OcrCandidateLine(text: '2026', confidence: 0.9, height: 10),
    ]);

    expect(result, isNotEmpty);
    expect(result.first.value.canonical, '1234.5');
  });

  test('deduplicates equivalent OCR candidates', () {
    final result = const MeterReadingCandidateExtractor().extract(const [
      OcrCandidateLine(text: '123,40', confidence: 0.8, height: 20),
      OcrCandidateLine(text: '123.40', confidence: 0.9, height: 24),
    ]);

    expect(result, hasLength(1));
    expect(result.single.confidence, 0.9);
  });
}
