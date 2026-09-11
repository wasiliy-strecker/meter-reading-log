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
- chronologischer Verlauf mit Verbrauchsdifferenzen
- begründete, append-only protokollierte Korrekturen
- Ablesezeitpunkte bis Ende 2100 mit transparenter Kennzeichnung zukünftiger
  Angaben in App und PDF
- Einzel- und Verlaufs-PDFs mit Fotos, Zeitpunkten und Korrekturen
- optionale monatliche oder jährliche Android-Erinnerungen
- passwortgeschütztes AES-256-GCM-Backup einschließlich Fotos und PDFs

## Aussagekraft der Nachweise

Die PDFs bündeln die in der App gespeicherten Zählerstände, Fotos, Zeitpunkte
und Korrekturen. Sie dienen der privaten Dokumentation und sind keine amtliche
Bestätigung. Ablesezeitpunkt und Zeitzone stammen vom Gerät. Galerieimporte
werden im Nachweis ausdrücklich als solche markiert.

## Datenschutz

- Fotos, OCR, Verlauf, PDFs und Backups werden lokal verarbeitet.
- Die Android-Release-App fordert keine `INTERNET`-Berechtigung an.
  Debug-/Profile-Builds benötigen sie für Flutter-Entwicklungswerkzeuge.
- Android-Systembackups für die privaten App-Daten sind deaktiviert; Backups
  werden ausschließlich bewusst und verschlüsselt in der App erstellt.
- Es gibt kein Konto, keine Cloud-Synchronisation, keine Server-KI, keine
  Werbung und keine Analytics.
- Das verschlüsselte Backup verlässt die private App-Ablage nur, wenn der
  Nutzer einen Speicherort auswählt oder eine Teilen-Aktion auslöst.

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

Für einen Play-Store-Build muss `android/key.properties` anhand von
`android/key.properties.example` eingerichtet sein und auf einen privaten
Upload-Keystore unter `android/app/` verweisen. Beide Dateien bleiben außerhalb
von Git. Anschließend entsteht das signierte Android App Bundle mit:

```bash
flutter build appbundle --release --flavor store
```

Das AAB liegt unter `build/app/outputs/bundle/storeRelease/app-store-release.aab`.
Interne Play-Tests verwenden dieselbe Store-Variante wie die Veröffentlichung.
Ein bereits veröffentlichter Test-Release bleibt durch die Einführung der
Dev-Variante gültig. Für einen späteren neuen Upload den Versionscode erhöhen.

Beim einmaligen Umstieg von einer alten Debug-Installation mit Store-Paketkennung
zuerst ein verschlüsseltes Backup außerhalb der App speichern. Die neue Dev-App
zusätzlich installieren, das Backup dort wiederherstellen und die Daten prüfen.
Erst danach die alte Debug-App bewusst deinstallieren und die Store-App über
Google Play beziehen. Beide Varianten synchronisieren ihre Daten nicht automatisch.

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
