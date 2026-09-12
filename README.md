# ZählerstandLog

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](LICENSE)

ZählerstandLog ist eine Android-first Flutter-App für private Haushalte. Sie
fotografiert Strom-, Gas- und Wasserzähler, erkennt mögliche Zählerstände lokal
per OCR, speichert den bestätigten Verlauf und erzeugt übersichtliche
PDF-Nachweise mit Fotos und Korrekturen.

## Funktionen

- Strombezug, PV-Einspeisung, Gas, Wasser, Kalt-/Warmwasser, Wärme,
  Heizkostenverteiler, Heizöl und sonstige Zähler mit Nummer und Standort
- passende Einheitenauswahl je Zählerart, durchsuchbarer Gesamtkatalog und
  optionale eigene Einheiten
- Einheit kann beim Bestätigen einer Ablesung angepasst werden; historische
  Ablesungen behalten ihre ursprüngliche Einheit
- lokal gespeicherte Nachweisfotos, als JPEG mit maximal 1920 Pixeln an der
  längsten Kante optimiert und ohne übernommene Aufnahme-/Standortmetadaten
- lokale ML-Kit-OCR mit Kandidatenauswahl und verpflichtender Bestätigung
- exakte Dezimalwerte ohne Gleitkomma-Rundungsfehler
- fünf aktuelle Ablesungen pro Zähler; vollständiger Verlauf mit Suche nach
  Datum, Zählerstand oder Notiz und festen Seiten mit je 20 Einträgen
- neueste Ablesungen zuerst, mit Verbrauchsdifferenzen zur älteren Ablesung
- begründete, append-only protokollierte Korrekturen
- Ablesezeitpunkte bis Ende 2100 mit transparenter Kennzeichnung zukünftiger
  Angaben in App und PDF
- Einzel- und Verlaufs-PDFs mit Fotos, Zeitpunkten und Korrekturen;
  Verlaufs-PDFs enthalten alle Ablesungen, neueste zuerst
- optionale stündliche, tägliche, wöchentliche, monatliche oder jährliche
  Android-Erinnerungen; stündlich ab einem einstellbaren Startdatum mit Uhrzeit,
  danach alle 60 Minuten ohne Nachholen verpasster Termine
- passwortgeschütztes AES-256-GCM-Backup einschließlich Fotos und PDFs

## Aussagekraft der Nachweise

Die PDFs bündeln die in der App gespeicherten Zählerstände, Fotos, Zeitpunkte
und Korrekturen. Sie dienen der privaten Dokumentation und sind keine amtliche
Bestätigung. Ablesezeitpunkt und Zeitzone stammen vom Gerät. Galerieimporte
werden im Nachweis ausdrücklich als solche markiert.

## Datenschutz

Die vollständige [Datenschutzerklärung](https://wasiliy-strecker.github.io/meter-reading-log/datenschutz/)
und ihre [englische Fassung](https://wasiliy-strecker.github.io/meter-reading-log/privacy/)
werden unabhängig von der AppFabrik-Website über GitHub Pages bereitgestellt.

- Fotos, OCR, Verlauf, PDFs und Backups werden lokal verarbeitet.
- Die Android-Release-App fordert keine `INTERNET`-Berechtigung an.
  Debug-/Profile-Builds benötigen sie für Flutter-Entwicklungswerkzeuge.
- Android-Systembackups für die privaten App-Daten sind deaktiviert; Backups
  werden ausschließlich bewusst und verschlüsselt in der App erstellt.
- Es gibt kein Konto, keine Cloud-Synchronisation, keine Server-KI, keine
  Werbung und keine Analytics.
- Das verschlüsselte Backup verlässt die private App-Ablage nur, wenn der
  Nutzer einen Speicherort auswählt oder eine Teilen-Aktion auslöst.

### Veröffentlichung der Datenschutzerklärung

Die statischen Datenschutzseiten liegen unter `docs/`. GitHub Pages veröffentlicht
den Ordner `/docs` aus `main` (Deploy from a branch); `.nojekyll` deaktiviert
die Jekyll-Verarbeitung. HTML und CSS benötigen keine externen Assets, Skripte
oder Build-Abhängigkeiten. App-Daten werden dort nicht abgelegt.

In der Play Console unter **App-Inhalte → Datenschutzerklärung** dieselbe
deutsche URL wie in der App hinterlegen. Der neue App-Link ist im Store-Bundle
`1.0.0+2` enthalten. Bereits installierte Builds mit dem alten AppFabrik-Link
werden dadurch nicht geändert; die bisherige Webseite für diese Builds
erreichbar lassen. Änderungen an der Erklärung künftig in beiden Sprachfassungen
pflegen und das Aktualisierungsdatum anpassen.

## Architektur

```text
Feature-first Clean MVVM
+ Riverpod
+ Repository-Schnittstellen
+ Drift/SQLite
+ austauschbare Kamera-, OCR-, Reminder- und Export-Implementierungen
```

Die Flutter-Projekte in der App Factory bleiben unabhängig. ZählerstandLog
enthält kopierte und auf die Zählerdomäne angepasste Architektur-, OCR-,
Reporting-, Reminder- und Backup-Muster aus dem AI Contract Manager, aber keine
gemeinsame Runtime-Abhängigkeit.

## Entwicklung

Voraussetzungen: Flutter 3.41 oder neuer und ein Android SDK.

```bash
flutter pub get
dart run build_runner build
dart format lib test
flutter analyze
flutter test
flutter build apk --debug --flavor dev
```

Android bietet zwei parallel installierbare Varianten mit getrennten Daten und
Berechtigungen:

| Variante | App-Name | Paketkennung |
| --- | --- | --- |
| `dev` | ZählerstandLog Dev | `com.appfactory.meter_reading_log.dev` |
| `store` | ZählerstandLog | `com.appfactory.meter_reading_log` |

Lokale Android-Entwicklung verwendet immer `dev`:

```bash
flutter run --flavor dev -d <device-id>
```

Für ein datenbewahrendes APK-Update auf dem Smartphone:

```bash
flutter build apk --debug --flavor dev
adb -s <device-id> install -r -t -g --no-streaming build/app/outputs/flutter-apk/app-dev-debug.apk
```

Debug-Optionen wie die minütliche Erinnerung stehen im Dev-Debug-Build bereit.
Store-Debug- und Store-Profile-Builds sind deaktiviert, damit lokale Entwicklung
die Paketkennung der Play-Version nicht belegt. `flutter install` nicht verwenden,
da es bestehende App-Daten bei einer Deinstallation verlieren kann.

In Dev und Store öffnet „Beispiele ansehen“ vor der Fotoauswahl eine
optionale Galerie mit vier synthetischen Zählerfotos, auch beim Ersetzen und
Korrigieren. Die Bilder dienen ausschließlich zur Ansicht, werden erst beim
Öffnen geladen. Ab `1.0.0+4` sind sie auch im internen Play-Test und in der
Store-Version enthalten, ohne Entwickleroption oder zusätzliche Berechtigung.
Gebündelt werden nur Vorschau-JPEGs unter `assets/dev/meter_photo_examples/`
(maximal 1024 Pixel, 150 KiB pro Bild). Die großen Originale unter
`test/manual_fixtures/meter_photos/` bleiben unverändert und werden nicht
mitgeliefert. Vorschauen bei Bedarf mit
`dart run scripts/prepare_meter_photo_examples.dart` aus dem App-Verzeichnis erzeugen.
Der historische `assets/dev/`-Pfad bleibt bestehen; er beschränkt die Beispiele
nicht mehr auf die Dev-Variante.

Für einen Play-Store-Build muss `android/key.properties` anhand von
`android/key.properties.example` eingerichtet sein und auf einen privaten
Upload-Keystore unter `android/app/` verweisen. Beide Dateien bleiben außerhalb
von Git. Für einen neuen internen Play-Release zuerst die Buildnummer hinter
`+` in `pubspec.yaml` erhöhen. Anschließend entsteht mit Bash, Flutter und `jq`
das signierte Android App Bundle:

```bash
./scripts/build_internal_test_aab.sh
```

Das Skript baut ausschließlich `store`/`release` und prüft Paketkennung,
Variante und Version anhand der Build-Metadaten. Die Datei für den Upload heißt
`build/releases/internal-test/zaehlerstandlog-<version>-build-<code>-internal-test.aab`.
Vorhandene versionierte Dateien werden nicht überschrieben; für denselben
Release die vorhandene Datei verwenden. Das Skript erhöht keine Version und
installiert, löscht oder veröffentlicht nichts. Bei Bedarf kann der Flutter-Pfad
über `FLUTTER_BIN` gesetzt werden.

Das ursprüngliche Build-Artefakt liegt unter
`build/app/outputs/bundle/storeRelease/app-store-release.aab`. Benannte
Upload-Dateien bleiben außerhalb dieses Build-Ordners, damit Flutter sie nicht
mit einem neuen Build-Ergebnis verwechselt. Maßgeblich ist der abschließend
vom Skript ausgegebene Pfad; ältere bereits ausgelieferte Dateien bleiben erhalten.
Interne Play-Tests verwenden dieselbe Store-Variante wie die Veröffentlichung.
Dev bleibt währenddessen installiert und unverändert nutzbar. Der Agent liefert
die geprüfte Datei, öffnet den Ordner und gibt Titel sowie deutsche Release-Notizen
aus; der Nutzer lädt sie in Play Console hoch und aktualisiert über Google Play.
Ein Test-Release braucht weder ein angeschlossenes Gerät noch einen Datenumzug.
Der genaue Agentenablauf ist in [AGENTS.md](AGENTS.md) festgehalten.

Nur bei einem Altbestand mit Store-Paketkennung und Debug-Signatur ist ein
einmaliger Umstieg nötig: externes verschlüsseltes Backup speichern,
Wiederherstellung in Dev prüfen und die alte Debug-App erst nach ausdrücklicher
Freigabe entfernen. Das ist kein wiederkehrender Release-Schritt. Beide Varianten
synchronisieren ihre Daten nicht automatisch.

Ist der Play-Test nicht sichtbar, auch das aktive Konto in der Android-Play-Store-App
prüfen, nicht nur im Browser. Eine fehlende Store-Seite ist noch kein Beleg für
einen Signaturkonflikt. Ein konkreter Konflikt bei der Installation darf nicht
durch ungefragtes Löschen einer App behoben werden.

Die native Kamera, ML-Kit-OCR, Benachrichtigungen und der Share-Sheet benötigen
ein Android-Gerät. iOS ist als Projekt-Shell vorbereitet, aber nicht das
Release-Ziel der ersten Version.

Für schnelle UI-Prüfungen ist außerdem eine Web-Shell verfügbar:

```bash
flutter run -d chrome --web-port=53545
```

Sie verwendet absichtlich nur flüchtige In-Memory-Repositories. Persistenz,
Kamera, OCR, PDF-Dateien, Erinnerungen und Backups werden vollständig in der
Android-App geprüft.

## Lizenz

Der Quellcode steht unter der [Mozilla Public License 2.0](LICENSE). Änderungen
an MPL-abgedeckten Dateien müssen bei einer Weitergabe unter den Bedingungen der
MPL verfügbar bleiben. Direkt eingebundene Drittanbieter-Assets sind in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) dokumentiert.
