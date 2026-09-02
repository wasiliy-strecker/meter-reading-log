# ZählerstandLog

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](LICENSE)

ZählerstandLog ist eine Android-first Flutter-App für private Haushalte. Sie
fotografiert Strom-, Gas- und Wasserzähler, erkennt mögliche Zählerstände lokal
per OCR, speichert den bestätigten Verlauf und erzeugt manipulationsprüfbare
PDF-Nachweise.

## Funktionen

- Strombezug, PV-Einspeisung, Gas, Wasser, Kalt-/Warmwasser, Wärme,
  Heizkostenverteiler, Heizöl und sonstige Zähler mit Nummer und Standort
- passende Einheitenauswahl je Zählerart statt fehleranfälliger Freitexteingabe
- unveränderte Ablage des aufgenommenen Originalfotos im privaten App-Speicher
- lokale ML-Kit-OCR mit Kandidatenauswahl und verpflichtender Bestätigung
- exakte Dezimalwerte ohne Gleitkomma-Rundungsfehler
- chronologischer Verlauf mit Verbrauchsdifferenzen
- begründete, append-only protokollierte Korrekturen
- Einzel- und Verlaufs-PDFs mit Foto-, Datensatz- und Manifest-Prüfsummen
- lokale Prüfung exportierter PDFs über den gespeicherten SHA-256-Wert
- optionale monatliche oder jährliche Android-Erinnerungen
- passwortgeschütztes AES-256-GCM-Backup einschließlich Fotos und PDFs

## Aussagekraft der Nachweise

Die App speichert den SHA-256-Wert des unveränderten Originalfotos, eines
kanonischen Datenmanifests und jeder erzeugten PDF. Damit lassen sich spätere
Änderungen gegenüber den lokal gespeicherten Exportdatensätzen erkennen.

Das ist kein amtlicher Zeitstempel, keine qualifizierte elektronische Signatur
und keine Garantie gerichtlicher Beweiskraft. Aufnahmezeit und Zeitzone stammen
vom Gerät. Galerieimporte werden im Nachweis ausdrücklich als solche markiert.

## Datenschutz

- Fotos, OCR, Verlauf, PDFs und Backups werden lokal verarbeitet.
- Die Android-App fordert keine `INTERNET`-Berechtigung an.
- Es gibt kein Konto, keine Cloud-Synchronisation, keine Server-KI, keine
  Werbung und keine Analytics.
- Das verschlüsselte Backup verlässt das Gerät nur über eine vom Nutzer
  ausgelöste Teilen-Aktion.

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
flutter build apk --debug
```

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
