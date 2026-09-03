import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/app/app_theme.dart';

void main() {
  test('uses the same pill shape for all standard action buttons', () {
    final theme = AppTheme.light();

    expect(_shape(theme.filledButtonTheme.style), isA<StadiumBorder>());
    expect(_shape(theme.outlinedButtonTheme.style), isA<StadiumBorder>());
    expect(_shape(theme.elevatedButtonTheme.style), isA<StadiumBorder>());
    expect(_shape(theme.textButtonTheme.style), isA<StadiumBorder>());
  });
}

OutlinedBorder? _shape(ButtonStyle? style) {
  return style?.shape?.resolve(const <WidgetState>{});
}
