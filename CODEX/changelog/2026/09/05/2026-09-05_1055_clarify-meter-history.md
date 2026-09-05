# Zählerverlauf deutlicher dargestellt

- Benennt den Bereich und seine PDF-Aktionen eindeutig als Zählerverlauf.
- Hebt Datum und Uhrzeit jeder Ablesung in einem farblich passenden Kalender-Badge am oberen Rand der Karte hervor.
- Ergänzt Widget-Tests für die neuen Bezeichnungen, das Badge und dessen Position.

## Prüfung

- `dart format lib/features/meters/presentation/meter_detail_screen.dart test/features/meters/capture_reading_screen_test.dart test/widget_test.dart`
- `flutter analyze`
- `flutter test test/features/meters/capture_reading_screen_test.dart test/widget_test.dart`
