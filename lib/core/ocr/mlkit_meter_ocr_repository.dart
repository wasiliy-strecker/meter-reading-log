import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'meter_ocr_repository.dart';

class MlKitMeterOcrRepository implements MeterOcrRepository {
  const MlKitMeterOcrRepository({
    MeterReadingCandidateExtractor extractor =
        const MeterReadingCandidateExtractor(),
  }) : _extractor = extractor;

  final MeterReadingCandidateExtractor _extractor;

  @override
  Future<MeterOcrResult> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final lines = <OcrCandidateLine>[];
      final confidences = <double>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final confidence = (line.confidence ?? 0.75).clamp(0.0, 1.0);
          confidences.add(confidence);
          lines.add(
            OcrCandidateLine(
              text: line.text,
              confidence: confidence,
              height: line.boundingBox.height,
            ),
          );
        }
      }
      final average = confidences.isEmpty
          ? 0.0
          : confidences.reduce((a, b) => a + b) / confidences.length;
      return MeterOcrResult(
        rawText: result.text,
        candidates: _extractor.extract(lines),
        confidence: average,
      );
    } finally {
      await recognizer.close();
    }
  }
}

class UnsupportedMeterOcrRepository implements MeterOcrRepository {
  const UnsupportedMeterOcrRepository();

  @override
  Future<MeterOcrResult> recognize(String imagePath) async {
    return const MeterOcrResult(rawText: '', candidates: [], confidence: 0);
  }
}
