import '../../features/meters/domain/reading_value.dart';

class OcrReadingCandidate {
  const OcrReadingCandidate({
    required this.rawText,
    required this.value,
    required this.confidence,
    required this.score,
  });

  final String rawText;
  final ReadingValue value;
  final double confidence;
  final double score;
}

class MeterOcrResult {
  const MeterOcrResult({
    required this.rawText,
    required this.candidates,
    required this.confidence,
  });

  final String rawText;
  final List<OcrReadingCandidate> candidates;
  final double confidence;
}

abstract interface class MeterOcrRepository {
  Future<MeterOcrResult> recognize(String imagePath);
}

class OcrCandidateLine {
  const OcrCandidateLine({
    required this.text,
    required this.confidence,
    required this.height,
  });

  final String text;
  final double confidence;
  final double height;
}

class MeterReadingCandidateExtractor {
  const MeterReadingCandidateExtractor();

  List<OcrReadingCandidate> extract(List<OcrCandidateLine> lines) {
    final candidates = <OcrReadingCandidate>[];
    final maxHeight = lines.fold<double>(
      1,
      (current, line) => line.height > current ? line.height : current,
    );
    final pattern = RegExp(r"\d(?:[\d\s.,'’]*\d)?");
    for (final line in lines) {
      for (final match in pattern.allMatches(line.text)) {
        final raw = match.group(0)?.trim() ?? '';
        final value = ReadingValue.tryParse(raw);
        if (value == null || raw.replaceAll(RegExp(r'\D'), '').length < 2) {
          continue;
        }
        final digitCount = raw.replaceAll(RegExp(r'\D'), '').length;
        final numericDensity = digitCount / raw.length;
        final lengthScore = (digitCount / 8).clamp(0.0, 1.0);
        final heightScore = (line.height / maxHeight).clamp(0.0, 1.0);
        final score =
            line.confidence * 0.35 +
            numericDensity * 0.25 +
            lengthScore * 0.2 +
            heightScore * 0.2;
        candidates.add(
          OcrReadingCandidate(
            rawText: raw,
            value: value,
            confidence: line.confidence,
            score: score,
          ),
        );
      }
    }

    final unique = <String, OcrReadingCandidate>{};
    for (final candidate in candidates) {
      final existing = unique[candidate.value.canonical];
      if (existing == null || candidate.score > existing.score) {
        unique[candidate.value.canonical] = candidate;
      }
    }
    final result = unique.values.toList()
      ..sort((left, right) => right.score.compareTo(left.score));
    return result.take(8).toList(growable: false);
  }
}
