class ReadingValue implements Comparable<ReadingValue> {
  const ReadingValue({
    required this.displayText,
    required this.digits,
    required this.scale,
  });

  final String displayText;
  final String digits;
  final int scale;

  BigInt get unscaled => BigInt.parse(digits);

  String get canonical {
    final negative = digits.startsWith('-');
    final raw = negative ? digits.substring(1) : digits;
    if (scale == 0) {
      return digits;
    }
    final padded = raw.padLeft(scale + 1, '0');
    final split = padded.length - scale;
    return '${negative ? '-' : ''}${padded.substring(0, split)}.'
        '${padded.substring(split)}';
  }

  String get germanFormatted => canonical.replaceAll('.', ',');

  static ReadingValue? tryParse(String input) {
    final value = input
        .trim()
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'[\u00a0\u202f]'), ' ');
    if (value.isEmpty || !RegExp(r"^[0-9., ']+$").hasMatch(value)) {
      return null;
    }
    final commas = ','.allMatches(value).length;
    final dots = '.'.allMatches(value).length;
    String? decimal;
    if (commas > 0 && dots > 0) {
      decimal = value.lastIndexOf(',') > value.lastIndexOf('.') ? ',' : '.';
      if (decimal.allMatches(value).length != 1) return null;
    } else if (commas == 1) {
      decimal = ',';
    } else if (dots == 1) {
      decimal = '.';
    }
    final split = decimal == null ? -1 : value.lastIndexOf(decimal);
    final integer = split < 0 ? value : value.substring(0, split);
    final fraction = split < 0 ? '' : value.substring(split + 1);
    if (split >= 0 && !RegExp(r'^[0-9]+$').hasMatch(fraction)) return null;
    final integerDigits = _parseIntegerGroup(integer.isEmpty ? '0' : integer);
    if (integerDigits == null) return null;
    final digits = '$integerDigits$fraction';
    return ReadingValue(
      displayText: input.trim(),
      digits: digits.replaceFirst(RegExp(r'^0+(?=\d)'), ''),
      scale: fraction.length,
    );
  }

  static String? _parseIntegerGroup(String value) {
    if (RegExp(r'^[0-9]+$').hasMatch(value)) return value;
    final separators = RegExp(
      r"[., ']",
    ).allMatches(value).map((match) => match.group(0)!).toSet();
    if (separators.length != 1) return null;
    final separator = separators.single;
    final grouped = RegExp(
      '^[0-9]{1,3}(?:${RegExp.escape(separator)}[0-9]{3})+\$',
    );
    if (!grouped.hasMatch(value)) return null;
    return value.replaceAll(separator, '');
  }

  ReadingValue difference(ReadingValue other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    final left = _scaled(targetScale);
    final right = other._scaled(targetScale);
    final result = left - right;
    return ReadingValue(
      displayText: _formatUnscaled(result, targetScale).replaceAll('.', ','),
      digits: result.toString(),
      scale: targetScale,
    );
  }

  BigInt _scaled(int targetScale) {
    return unscaled * BigInt.from(10).pow(targetScale - scale);
  }

  static String _formatUnscaled(BigInt value, int scale) {
    if (scale == 0) {
      return value.toString();
    }
    final negative = value.isNegative;
    final raw = value.abs().toString().padLeft(scale + 1, '0');
    final split = raw.length - scale;
    return '${negative ? '-' : ''}${raw.substring(0, split)}.'
        '${raw.substring(split)}';
  }

  @override
  int compareTo(ReadingValue other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    return _scaled(targetScale).compareTo(other._scaled(targetScale));
  }

  Map<String, dynamic> toJson() => {
    'displayText': displayText,
    'digits': digits,
    'scale': scale,
  };

  factory ReadingValue.fromJson(Map<String, dynamic> json) {
    return ReadingValue(
      displayText: json['displayText'] as String,
      digits: json['digits'] as String,
      scale: (json['scale'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingValue && compareTo(other) == 0;
  }

  @override
  int get hashCode => canonical.hashCode;
}
