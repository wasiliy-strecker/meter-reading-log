# Aktuellen Dev-Stand dauerhaft installieren

- Auf ausdrücklichen Wunsch die bisher installierte Dev-APK 1.0.0 / Build 4
  datenbewahrend durch den aktuellen Build 6 ersetzt. Keine Änderung der
  Versionsnummer oder UI-Logik, kein neuer Store-Test-Release.
- Der Stand enthält die gemeinsame Suchfeld-Rundung von 14, zehn Ablesungen
  in Vorschau und Verlaufssuche sowie zehn gespeicherte Verlaufs-PDFs pro Seite.
  Pagination bzw. der Button zum vollständigen Verlauf erscheinen ab elf
  Einträgen. Diese Änderungen sind jetzt im installierten APK enthalten und
  nicht mehr nur in einer temporären Hot-Reload-Sitzung.
- Vorhandene eigene Flutter-Attach-Verbindung sauber getrennt; keine fremden
  Prozesse oder Apps beendet und anschließend kein neues Attach gestartet.

## Prüfung und Installation

- `flutter analyze --no-pub`: keine Befunde.
- `flutter test --no-pub --flavor dev` mit den vier Testdateien für Verlauf,
  Erfassung, gespeicherte PDFs und PDF-Seiten: alle 26 Tests bestanden.
- `flutter build apk --debug --flavor dev --no-pub`: erfolgreich.
- Neue APK mit `aapt dump badging` geprüft: Paket
  `com.appfactory.meter_reading_log.dev`, Name `ZählerstandLog Dev`,
  Version 1.0.0 / Code 6 und Debuggable-Flag.
- Installierte und neue APK mit `apksigner verify --print-certs` geprüft:
  identisches Debug-Zertifikat, SHA-256
  `632889a1379e7cfd837ae594034bc96b9ff393e4212424a0fc5e7aaa16e33579`.
- Update mit `adb -s A5CS024205005243 install -r -t -g --no-streaming
  build/app/outputs/flutter-apk/app-dev-debug.apk`: `Success`. Keine
  Deinstallation und kein Löschen von App-Daten. Datenverzeichnis und
  Erstinstallationszeitpunkt sind unverändert.
- Anschließend normal über die Dev-MainActivity gestartet:
  `Status: ok`, `LaunchState: COLD`. Installierter Code 6 bestätigt.
  Die optische Kontrolle übernimmt der Nutzer; keine automatischen UI-Taps.
- Play-Paket bleibt auf Code 5 mit unverändertem Aktualisierungszeitpunkt.
  Das bereits gelieferte Store-AAB für Build 6 bleibt unangetastet.
- APK: `build/app/outputs/flutter-apk/app-dev-debug.apk`, 205.342.215 Bytes,
  SHA-256 `38624fbae6b4e6b19be5bc24c848878a91058061a2e1360a63f7b7faf1a45878`.

Für weitere gewöhnliche Dart-/UI-Änderungen gilt weiterhin Hot Reload zuerst;
dieser APK-Build war das ausdrücklich angeforderte dauerhafte Update.
