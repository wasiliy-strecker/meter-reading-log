import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

void main() {
  test(
    'validates decimal and grouped values without reinterpreting invalid input',
    () {
      const valid = {
        '0': '0',
        '7': '7',
        '00123': '123',
        '123,45': '123.45',
        '123.45': '123.45',
        '1 234,56': '1234.56',
        "1'234.56": '1234.56',
        '1.234,56': '1234.56',
        '1,234.56': '1234.56',
        '1.234.567': '1234567',
        '1,234': '1.234',
        '1\u202f234,5': '1234.5',
        '1’234,5': '1234.5',
        ',5': '0.5',
      };
      for (final entry in valid.entries) {
        expect(
          ReadingValue.tryParse(entry.key)?.canonical,
          entry.value,
          reason: entry.key,
        );
      }
      for (final invalid in [
        '12-13',
        '12abc13',
        '-12',
        '+12',
        '12 kWh',
        '12/13',
        '12,',
        '1,,2',
        '12,34,56',
        '1.23,45',
        '12 34',
        '1 234 56',
        "1'234 567",
        '1.234,5,6',
        '1 234,5 6',
        'NaN',
        '1e3',
        '1\n234',
      ]) {
        expect(ReadingValue.tryParse(invalid), isNull, reason: invalid);
      }
    },
  );

  test('parses German decimal values and preserves display text', () {
    final value = ReadingValue.tryParse('00123,45');

    expect(value, isNotNull);
    expect(value!.displayText, '00123,45');
    expect(value.digits, '12345');
    expect(value.scale, 2);
    expect(value.canonical, '123.45');
  });

  test('compares and subtracts values without floating point errors', () {
    final current = ReadingValue.tryParse('1000,10')!;
    final previous = ReadingValue.tryParse('999,9')!;

    expect(current.compareTo(previous), greaterThan(0));
    expect(current.difference(previous).canonical, '0.20');
  });

  test('rejects empty and non-numeric input', () {
    expect(ReadingValue.tryParse(''), isNull);
    expect(ReadingValue.tryParse('kein Wert'), isNull);
  });
}
