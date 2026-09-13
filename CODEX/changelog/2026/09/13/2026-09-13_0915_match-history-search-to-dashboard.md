# Suchfeld im Zählerverlauf an Dashboard angleichen

- Die eigene Randdefinition von „Ablesungen suchen“ entfernt. Das Feld erbt
  jetzt dieselbe `InputDecorationTheme` wie „Zähler suchen“ im Dashboard:
  14 px Eckenradius, unverändert auch bei Fokus.
- Dashboard, globales Theme, Suchlogik und Pagination bleiben unverändert.
- Widget-Tests prüfen die geerbte Rundung ohne und mit Fokus.

## Prüfung

- `dart format lib test`, `flutter analyze --no-pub`: sauber.
- `flutter test --no-pub test/features/meters/meter_history_screen_test.dart`:
  alle sieben Tests bestanden.
- Hot Reload der bestehenden Dev-Sitzung nach Öffnen der App erfolgreich:
  eine Bibliothek aktualisiert. Ziel über VM-Prozess-ID und Root-Library als
  ZählerstandLog Dev bestätigt. Der zunächst wartende Reload konnte erst nach
  Rückkehr der Dev-App in den Vordergrund abgeschlossen werden.
- Direkt am HONOR-Smartphone geprüft: abgerundetes Verlaufssuchfeld,
  „1–5 von 6 Ablesungen“ und „Seite 1 von 2“. Dev-Verbindung bleibt offen.
- Kein APK-/AAB-Build, keine Neuinstallation und kein Test-Release.
