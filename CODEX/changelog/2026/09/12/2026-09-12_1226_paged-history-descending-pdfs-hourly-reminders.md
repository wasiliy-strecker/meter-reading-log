# Durchsuchbarer Gesamtverlauf, absteigende PDFs und stündliche Erinnerungen

- Zählerdetails zeigen höchstens fünf aktuelle Ablesungen und öffnen über „Alle
  Ablesungen anzeigen“ einen eigenen Verlauf. Die Suche nach Datum, Stand und
  Notiz ist dort immer sichtbar; feste 20er-Seiten ersetzen kumulatives Nachladen.
- Offset-basierte Drift-/In-Memory-Abfragen behalten die echte neueste Ablesung
  und eine ältere Nachbarablesung für die Differenzberechnung. Suche und Seite
  bleiben bei Rücknavigation erhalten; leere letzte Seiten werden korrigiert.
- Übersicht und Detail-/Fotobereiche neuer Verlaufs-PDFs sind absteigend
  sortiert. Differenzen beziehen sich weiterhin auf die ältere Ablesung;
  Einheitenwechsel und negative Differenzen bleiben korrekt. Vorhandene PDFs
  und die bisherige Manifest-Normalisierung werden nicht verändert.
- „Stündlich“ ist in Dev und Store verfügbar: Startdatum und Startzeit werden
  als UTC-Anker gespeichert und an Android weitergereicht. Folgetermine liegen
  alle 60 Minuten auf diesem Raster; verspätete Ausführung verschiebt es nicht.
  Ältere Erinnerungsdaten bleiben lesbar; verschlüsselte Backups übernehmen den
  neuen Startzeitpunkt ohne Datenbankmigration. Minütlich bleibt Debug-only.
- Dashboard und Veröffentlichungsversion bleiben unverändert (`1.0.0+4`).

## Prüfung

- `dart format --output=none --set-exit-if-changed lib test`: unverändert.
- `flutter analyze --no-pub`: keine Befunde.
- `flutter test --no-pub --reporter expanded`: **160 Tests bestanden**.
  Einschließlich 0/1/5/6/20/21 Einträgen, 5.000 Ablesungen, stabiler Sortierung
  bei gleichen Zeitstempeln, Such-/Seitenerhalt, leerer letzter Seite,
  PDF-Fotovarianten, 365 täglichen Ablesungen als PDF, Startzeitwahl und Backup.
- `flutter build apk --debug --flavor dev --no-pub`: erfolgreich. Neubau wegen
  geänderter nativer Erinnerungsplanung, nicht wegen Dart-/UI-Änderungen.
- `test/native/HourlyReminderCheck.java` gegen die tatsächlich kompilierten
  Dev-Kotlin-Klassen mit JDK 21 und Kotlin-stdlib ausgeführt: **16 Prüfungen
  bestanden**, einschließlich Sommer-/Winterzeit, Neustart und Verspätung.
- APK mit `aapt dump badging` und `apksigner verify --print-certs` geprüft:
  `com.appfactory.meter_reading_log.dev`, `ZählerstandLog Dev`, Debug-Signatur,
  Version 1.0.0 / Code 4. Ausgabe:
  `build/app/outputs/flutter-apk/app-dev-debug.apk`.

## Gerät und Release

Das Smartphone war zunächst nicht verbunden, wurde vor Abschluss aber als
HONOR BVL-N49 (`A5CS024205005243`) erkannt. Installierte Dev-Paketkennung,
Debug-Flag und Installer geprüft; SHA-256-Zertifikat der installierten APK
stimmt mit dem neuen Debug-APK überein. Ausschließlich Dev mit
`adb -s A5CS024205005243 install -r -t -g --no-streaming build/app/outputs/flutter-apk/app-dev-debug.apk`
erfolgreich datenbewahrend aktualisiert (installierter Dev-Code 2 → 4) und die
Dev-Activity gestartet. Flutter-Dev-Verbindung erneut geöffnet.

Die Play-App bleibt auf Code 4, einschließlich unverändertem Installationsstand
vom 12.09.2026 um 11:01:52. Kein neues AAB und keine neue Buildnummer. Eine
tatsächliche stündliche Benachrichtigung wurde nicht abgewartet; keine
Test-Erinnerungen oder Test-Ablesungen in den persönlichen Daten angelegt.
