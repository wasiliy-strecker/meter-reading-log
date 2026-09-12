# Interner Play-Test: Version 1.0.0, Build 5

- Buildnummer in `pubspec.yaml` von 4 auf 5 erhöht; Versionsname bleibt 1.0.0.
- Enthält den eigenen durchsuchbaren Zählerverlauf mit 20er-Seiten, fünf
  aktuellen Ablesungen in den Zählerdetails, absteigend sortierte Verlaufs-PDFs
  mit korrekten Differenzen und stündliche Erinnerungen ab Startdatum/-zeit.
- Store-Release mit der vorhandenen Upload-Signatur über
  `FLUTTER_BIN=/home/unknown/.local/flutter/bin/flutter ./scripts/build_internal_test_aab.sh`
  gebaut. Keine Geräteaktion, kein Dev-APK, kein automatischer Play-Upload.

## Prüfung

- `dart format lib test`: 99 Dateien, keine Änderungen.
- `flutter analyze --no-pub`: keine Befunde.
- `flutter test --no-pub --flavor store --reporter expanded`: 160 Tests bestanden.
- Manifest direkt aus dem AAB gelesen: Paket `com.appfactory.meter_reading_log`,
  Version 1.0.0 / Code 5, kein Debuggable-Flag, keine INTERNET- oder
  ACCESS_NETWORK_STATE-Berechtigung, Android-Systembackup deaktiviert.
- JAR-Signatur verifiziert; bestehendes Upload-Zertifikat SHA-256:
  `1D:64:D5:0C:CF:5F:20:E8:BC:81:85:37:E4:10:4D:22:65:74:6F:78:35:C4:6A:9F:81:FF:85:05:1A:25:7B:55`.
  Die bekannten JDK-Hinweise zu selbstsigniertem Zertifikat, Zeitstempel und
  JarInputStream-Verarbeitung sind unverändert kein neuer Buildfehler.
- Benannte Upload-Datei bytegleich mit `app-store-release.aab`; bestehende
  Builds 3 und 4 erhalten. Flutters Ausgabe nennt weiterhin die historische
  Build-2-Datei im Bundle-Verzeichnis; maßgeblich ist die separat geprüfte,
  vom Skript erzeugte Build-5-Datei.

## Übergabe

- Datei: `build/releases/internal-test/zaehlerstandlog-1.0.0-build-5-internal-test.aab`
- Größe: 69.396.805 Bytes.
- SHA-256: `999beac0b401ff05e635599b8dcd9d3ad74ad136009f86e59169c523dd2f6aad`.
- Titel: `1.0.0 (5) – Verlauf und Erinnerungen`

```text
<de-DE>
Zählerverlauf mit Suche und übersichtlichen Seiten
PDF-Verlaufsnachweise zeigen die neuesten Ablesungen zuerst
Stündliche Erinnerungen mit einstellbarem Startdatum und Uhrzeit
</de-DE>
```
