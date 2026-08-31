import 'package:flutter/material.dart';

import '../domain/meter.dart';

IconData meterIcon(MeterType type) => switch (type) {
  MeterType.electricity => Icons.bolt_outlined,
  MeterType.gas => Icons.local_fire_department_outlined,
  MeterType.water => Icons.water_drop_outlined,
};

Color meterColor(MeterType type) => switch (type) {
  MeterType.electricity => const Color(0xFFC67C00),
  MeterType.gas => const Color(0xFFC64B36),
  MeterType.water => const Color(0xFF1976A3),
};
