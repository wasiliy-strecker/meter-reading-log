import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';

void main() {
  test('every meter type exposes a valid default and unique unit options', () {
    for (final type in MeterType.values) {
      expect(type.label, isNotEmpty);
      expect(type.availableUnits, isNotEmpty);
      expect(type.availableUnits, contains(type.defaultUnit));
      expect(
        type.availableUnits.toSet(),
        hasLength(type.availableUnits.length),
      );
    }
  });

  test('expanded household meter types use suitable units', () {
    expect(MeterType.values, contains(MeterType.electricityFeedIn));
    expect(MeterType.values, contains(MeterType.coldWater));
    expect(MeterType.values, contains(MeterType.hotWater));
    expect(MeterType.values, contains(MeterType.heat));
    expect(MeterType.values, contains(MeterType.heatingCostAllocator));
    expect(MeterType.values, contains(MeterType.oil));
    expect(MeterType.values, contains(MeterType.other));
    expect(MeterType.gas.availableUnits, containsAll(['m³', 'kWh']));
    expect(MeterType.heat.availableUnits, containsAll(['kWh', 'MWh', 'GJ']));
    expect(MeterType.oil.availableUnits, containsAll(['Liter', '%']));
  });
}
