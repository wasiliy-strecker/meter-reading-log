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
    var value = input.trim().replaceAll(RegExp(r'\s+'), '');
    value = value.replaceAll("'", '');
    if (value.isEmpty || !RegExp(r'\d').hasMatch(value)) {
      return null;
    }

    value = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (value.startsWith('-')) {
      return null;
    }
    value = value.replaceAll('-', '');

    final comma = value.lastIndexOf(',');
    final dot = value.lastIndexOf('.');
    final decimalIndex = comma > dot ? comma : dot;
    var scale = 0;
    String digits;
    if (decimalIndex >= 0) {
      scale = value.length - decimalIndex - 1;
      if (scale == 0) {
        return null;
      }
      digits =
          '${value.substring(0, decimalIndex)}'
                  '${value.substring(decimalIndex + 1)}'
              .replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    }
    if (digits.isEmpty) {
      return null;
    }
    final normalizedDigits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return ReadingValue(
      displayText: input.trim(),
      digits: normalizedDigits,
      scale: scale,
    );
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
