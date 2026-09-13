# Interner Play-Test: Version 1.0.0, Build 6

- Buildnummer in `pubspec.yaml` von 5 auf 6 erhöht; Versionsname bleibt 1.0.0.
- Enthält den aktuellen Stand: zehn Ablesungen in der Vorschau und pro
  Such-/Verlaufsseite, zehn gespeicherte Verlaufs-PDFs pro Seite, Blättern bzw.
  vollständiger Verlauf erst bei mehr als zehn Einträgen. Das Suchfeld übernimmt
  die abgerundeten Rahmen des Dashboard-Themes. PDF-Dateien werden erst für die
  geöffnete Nachweisseite asynchron geprüft.
- Store-AAB mit der bestehenden Upload-Signierung über
  `FLUTTER_BIN=/home/unknown/.local/flutter/bin/flutter ./scripts/build_internal_test_aab.sh`
  erstellt. Keine Geräteaktion, kein Dev-APK und kein Play-Upload.

## Prüfung

- `dart format lib test`: 104 Dateien, keine Änderungen.
- `flutter analyze --no-pub`: keine Befunde.
- `flutter test --no-pub --flavor store --reporter expanded`: 172 Tests bestanden.
- `bundletool validate`: erfolgreich. Manifest direkt aus der gelieferten AAB:
  Paket `com.appfactory.meter_reading_log`, Version 1.0.0 / Code 6, kein
  Debuggable-Flag, keine INTERNET-/ACCESS_NETWORK_STATE-Berechtigung und
  Android-Systembackup deaktiviert. Gradle-Metadaten bestätigen `storeRelease`.
- `jarsigner -verify`: `jar verified.`. Bestehendes Upload-Zertifikat SHA-256:
  `1D:64:D5:0C:CF:5F:20:E8:BC:81:85:37:E4:10:4D:22:65:74:6F:78:35:C4:6A:9F:81:FF:85:05:1A:25:7B:55`.
  Die bekannten JDK-Hinweise zu selbstsigniertem Zertifikat, Zeitstempel und
  JarInputStream-Verarbeitung bestehen unverändert.
- Neue PDF-Seitenaktionen und Verlaufssuche auch im gebündelten ARM64-Dart-Code
  nachgewiesen; die vier kompakten Fotobeispiele sind enthalten.
- Benannte Datei und `app-store-release.aab` sind bytegleich. Frühere benannte
  Releases bleiben erhalten. Flutters Build-Ausgabe nennt wegen der historischen
  Datei im Bundle-Ordner weiterhin Build 2; maßgeblich ist die vom Skript erzeugte
  und separat geprüfte Build-6-Datei außerhalb dieses Ordners.

## Übergabe

- Datei: `build/releases/internal-test/zaehlerstandlog-1.0.0-build-6-internal-test.aab`
- Größe: 69.421.461 Bytes.
- SHA-256: `74ba96e27cb4b7c5dd36bc745463b846bdde49b0bb186883fe75c8549dd8077e`.
- Titel: `1.0.0 (6) – Übersichtlicher Verlauf`

```text
<de-DE>
Zählerverlauf mit zehn Ablesungen pro Seite
Liste gespeicherter Verlaufs-PDFs mit zehn Nachweisen pro Seite
Blättern erst bei mehr als zehn Einträgen
Einheitlich abgerundetes Suchfeld im Zählerverlauf
</de-DE>
```
