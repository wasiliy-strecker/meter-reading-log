# ZählerstandLog repository guide

ZählerstandLog ist eine unabhängige Flutter-App in der App Factory. Sie muss
ohne den AI Contract Manager baubar bleiben; keine gemeinsame Monorepo-Runtime
oder Abhängigkeit auf benachbarte App-Verzeichnisse einführen.

Feature-first Clean MVVM mit Riverpod beibehalten. Kamera, Dateispeicher, OCR,
Persistenz, Erinnerungen, PDF-Erzeugung und Backup bleiben hinter austauschbaren
Schnittstellen. Zählerstände werden als Ziffern plus Dezimalskala gespeichert,
nicht als `double`.

Zählerfotos und OCR-Inhalte sind privat. Keine `INTERNET`-Berechtigung,
Analytics, Remote-OCR, AI-Dienste, Konten, Kundendokumente oder Geheimnisse
hinzufügen. Nur synthetische Fixtures gehören in Tests.

Änderungen an gespeicherten Ablesungen müssen eine `ReadingRevision` mit Grund
erzeugen. Foto-, Manifest- und PDF-Hashing darf nicht stillschweigend entfernt
oder durch nicht deterministische Serialisierung geschwächt werden. Die App
darf lokale Prüfsummen nicht als amtlichen Zeitstempel oder garantierte
Beweiskraft bezeichnen.

Vor jedem Commit ausführen:

```bash
dart run build_runner build
dart format lib test
flutter analyze
flutter test
flutter build apk --debug --flavor dev
```

## Android-Varianten und Gerätetests

Android hat zwei unabhängig installierbare Varianten:

- `dev`: `com.appfactory.meter_reading_log.dev`, App-Name `ZählerstandLog Dev`.
  Lokale Entwicklung und Gerätetests verwenden `flutter run --flavor dev -d <device-id>`
  oder `flutter build apk --debug --flavor dev`. Die vorhandenen Debug-Optionen
  sind in Debug-Builds verfügbar.
- `store`: `com.appfactory.meter_reading_log`, App-Name `ZählerstandLog`.
  Interne Play-Tests und Veröffentlichung verwenden ausschließlich
  `flutter build appbundle --release --flavor store` mit Upload-Signierung.
  Store-Debug- und Store-Profile-Builds sind im Android-Build deaktiviert.

Auf verbundenen Android-Geräten niemals `flutter install` verwenden. Lokale
APKs nur datenbewahrend installieren:

```bash
adb -s <device-id> install -r -t -g --no-streaming build/app/outputs/flutter-apk/app-dev-debug.apk
```

Die Play-Installation niemals mit einem lokalen APK ersetzen. Beim einmaligen
Wechsel von der alten Debug-App mit Store-Paketkennung zuerst ein externes
verschlüsseltes Backup erstellen und in der neuen Dev-App prüfen. Die alte
Installation erst nach ausdrücklicher Freigabe zur Deinstallation entfernen.
Dev und Store besitzen getrennte Daten und Android-Berechtigungen; ein Backup
kann über die bestehende Wiederherstellung übertragen werden.

Nach Android-Buildänderungen zusätzlich das Store-AAB bauen und Paketkennung,
Release-Signatur sowie das zusammengeführte Manifest ohne Netzwerkrechte prüfen.
Das Store-AAB liegt unter `build/app/outputs/bundle/storeRelease/app-store-release.aab`.
Ein bereits hochgeladener Play-Release wird durch lokale Dev-Änderungen nicht
ersetzt; für einen späteren neuen Play-Upload muss der Versionscode erhöht werden.
