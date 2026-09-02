import 'package:flutter/material.dart';

import '../domain/meter.dart';

IconData meterIcon(MeterType type) => switch (type) {
  MeterType.electricity => Icons.bolt_outlined,
  MeterType.electricityFeedIn => Icons.solar_power_outlined,
  MeterType.gas => Icons.local_fire_department_outlined,
  MeterType.water => Icons.water_drop_outlined,
  MeterType.coldWater => Icons.ac_unit_outlined,
  MeterType.hotWater => Icons.water_drop,
  MeterType.heat => Icons.thermostat_outlined,
  MeterType.heatingCostAllocator => Icons.home_outlined,
  MeterType.oil => Icons.oil_barrel_outlined,
  MeterType.other => Icons.speed_outlined,
};

Color meterColor(MeterType type) => switch (type) {
  MeterType.electricity => const Color(0xFFC67C00),
  MeterType.electricityFeedIn => const Color(0xFF548400),
  MeterType.gas => const Color(0xFFC64B36),
  MeterType.water => const Color(0xFF1976A3),
  MeterType.coldWater => const Color(0xFF1479C9),
  MeterType.hotWater => const Color(0xFFC44B3E),
  MeterType.heat => const Color(0xFFB85F00),
  MeterType.heatingCostAllocator => const Color(0xFF8754A1),
  MeterType.oil => const Color(0xFF5F665E),
  MeterType.other => const Color(0xFF536878),
};
