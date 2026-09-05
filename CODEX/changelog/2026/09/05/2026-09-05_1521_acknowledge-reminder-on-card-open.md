# Erinnerung beim Öffnen der Zählerkarte bestätigen

- Ein Klick auf eine Dashboard-Zählerkarte bestätigt eine dort angezeigte aktive Erinnerung.
- Die Android-Benachrichtigung und die Badge „1“ werden entfernt, bevor die Zählerdetails geöffnet werden.
- Zeitpunkt der letzten Erinnerung und nächste geplante Erinnerung bleiben unverändert.
- Der Kartenklick bleibt auch bei einem Plattformfehler nutzbar.
- Widget-Test für Bestätigung, Badge und unveränderte Erinnerungsdaten ergänzt.

## Prüfung

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
