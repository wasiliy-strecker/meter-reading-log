# Play-Store-Bilderpaket für Build 7

## Umsetzung

- Vorhandenes, per SHA-256 geprüftes Store-AAB 1.0.0+7 mit bundletool in eine
  lokal signierte Emulator-APK umgewandelt. Keine Flutter-Neukompilierung,
  Versionsänderung, Upload-Signierung oder Berührung des Nutzer-Smartphones.
- Eigene API-35-AVD `zsl_store_assets`, Serial `emulator-5580`, mit frischen
  Daten unter `/dev/shm/zsl-store-assets-vbzjnI/`; keine bestehenden AVD-Daten.
- Drei fiktive Zähler, 24 Monatsablesungen, passgenaue synthetische SVG-Belegbilder
  und eine Notiz-Revision über den produktiven verschlüsselten Backup-Import.
  Das vorhandene synthetische Stromfoto durchlief echte lokale ML-Kit-Erkennung.
- 16 opake RGB-PNGs: Icon 512×512, Feature-Grafik 1024×500, sechs gestaltete
  Smartphone-Screenshots 1080×1920, je vier unverzierte Tablet-Screenshots
  1920×1080 und 2560×1440. Echte App-Oberflächen, proportional und unretuschiert.
- Lieferung unter `build/store-assets/de-DE/build-7/`, mit Gesamtvorschau,
  Upload-Anleitung, Alttexten, Prüfsummen und ZIP; Arbeitsmaterial in `raw/`.
- App-lokale, wiederverwendbare Aufnahme-/Layout-/Prüfwerkzeuge unter
  `scripts/store_assets/`; opt-in Demo-Backup-Test ausschließlich hostseitig.
  Weder öffentliche App-APIs noch Laufzeitverhalten, Schema oder Assets geändert.

## Prüfungen

- `dart format --output=none --set-exit-if-changed test/tooling/store_demo_backup_test.dart`.
- `flutter analyze --no-pub`: keine Befunde.
- Opt-in `store_demo_backup_test.dart`: Roundtrip von 3 Zählern, 24 Ablesungen,
  Foto-/Manifest-Prüfsummen, Werten und Revision erfolgreich.
- Bestehende Backup- und PDF-Inhaltstests: 19 Tests erfolgreich.
- Python-Werkzeugtests: 4 erfolgreich; `node --check`, `bash -n` erfolgreich.
  Die Vorbereitungshilfe wurde nur statisch geprüft; ihre einzelnen
  Emulator-/bundletool-Befehle wurden für diese Lieferung tatsächlich ausgeführt.
- Alle Upload-PNGs auf Maße, RGB ohne Alpha, Anzahl, Dateigröße geprüft und
  vollständig mit `identify` dekodiert. Alle kleiner als 300.000 Bytes.
- Motive visuell geprüft: keine Fehlermeldung, Ladeansicht, fremde Benachrichtigung
  oder privaten Beispieldaten. PDF in der echten App erzeugt und Vorschau geprüft.

## Beobachtungen / Grenzen

- Die früher beobachtete sporadische PDF-Preview-Ausnahme trat bei diesem
  Store-Durchlauf nicht auf; daraus folgt keine allgemeine Fehlerbehebung.
- Nach erneutem Import der überarbeiteten Demo wurden gespeicherte Revisionsdetails
  zunächst noch aus dem bereits geladenen UI-Stand angezeigt. Nach Neustart der
  Emulator-App erschien die importierte Revision korrekt. Kein Datenverlust;
  hierfür keine App-Codeänderung vorgenommen. In der Aufnahme-Anleitung vermerkt.
- Tablet-Oberfläche ist weiterhin die echte einspaltige App, kein erfundenes
  Mehrspaltenlayout. Die Ablesedetails wurden zur relevanten Infokarte gescrollt.
- Kein neuer Test-Release, keine Play-Veröffentlichung und kein Git-Push.
