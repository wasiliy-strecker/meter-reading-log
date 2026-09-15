import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF086F65);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAF8),
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    const buttonShape = StadiumBorder();
    final theme = ThemeData(useMaterial3: true, colorScheme: scheme);
    final actionButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      textStyle: WidgetStatePropertyAll(
        theme.textTheme.labelLarge?.copyWith(fontSize: 16),
      ),
      shape: const WidgetStatePropertyAll(buttonShape),
    );
    return theme.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: actionButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: actionButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: actionButtonStyle),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape),
      ),
    );
  }
}
