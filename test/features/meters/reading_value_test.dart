import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

void main() {
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
