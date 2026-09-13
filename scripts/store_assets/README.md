# Play-Store-Bilder ohne Eingriff ins Nutzergerät

Dieses Werkzeugpaket erzeugt ausschließlich lokale Marketing-Assets. Es
verändert weder App-Code noch Version, baut keinen Flutter-Release und lädt
nichts hoch. Ein vorhandenes Store-AAB ist die Quelle für die Emulator-App.
Keine Verbindung zu einer physischen Installation, kein `uninstall`, `pm clear`,
`flutter install`, Datenbank-Patching oder Demo-Schalter in der ausgelieferten App.

## Voraussetzungen

App-Verzeichnis als Arbeitsverzeichnis, Node 22+, Python 3, Chrome, ImageMagick,
Flutter, Java, bundletool, Android-Emulator und bereits installiertes
API-35-Image `google_apis/x86_64`. `/dev/shm` mit genügend Platz verwenden,
insbesondere wenn die SSD fast voll ist. Keine fremden AVD-Daten kopieren.
Die Shell-Hilfe akzeptiert `ZSL_ANDROID_SDK`, `ZSL_ADB` und einen freien
`ZSL_EMULATOR_PORT` (Standard 5580). `device.py` prüft zusätzlich `ro.kernel.qemu`
und den AVD-Namen mit Präfix `zsl_store_assets` vor jeder Bedienung.

## Ablauf

1. Arbeitsstand und genaues AAB prüfen, SHA-256 festhalten. Das benannte
   Lieferartefakt unter `build/releases/internal-test/` verwenden, nicht ein
   zufällig gefundenes APK oder eine ältere Datei im Flutter-Bundleordner.
2. `bash scripts/store_assets/prepare_emulator.sh <AAB> <bundletool.jar>` erzeugt
   eine frische RAM-AVD und eine lokal signierte APK aus dem unveränderten AAB.
   Der Store-Paketname ist hier nur im eigenen Emulator zulässig; diese APK
   niemals auf einem Nutzergerät installieren. Vor dem Installieren bestätigt
   das Skript die leere Zielinstallation. Die private Upload-Signierung wird
   nicht benötigt. Das Präparationsskript entspricht den für Build 7 einzeln
   ausgeführten Befehlen; die Wrapper-Variante wurde nur statisch geprüft.
3. Demobilder und echtes verschlüsseltes Backup erzeugen (Pfade einsetzen):

   ```bash
   node scripts/store_assets/render.mjs fixtures /dev/shm/<task>/fixtures
   flutter test test/tooling/store_demo_backup_test.dart --dart-define=STORE_DEMO_DIR=/dev/shm/<task>/fixtures
   ```

   Der opt-in Host-Test verwendet die produktive Backup-/Integritätslogik und
   prüft den Roundtrip von 3 Zählern, 24 Ablesungen, passgenauen Bildern und einer
   Notiz-Korrektur. Ohne Define ist er übersprungen; keine Fixtures in App-Assets
   aufnehmen. `Demo2026` ist ein öffentliches Demopasswort, kein Geheimnis.
   Synthetische SVG-Illustrationen sind neu gezeichnet; für die Live-OCR-Ansicht
   wird das vorhandene synthetische JPEG aus `assets/dev/meter_photo_examples/`
   unverändert genutzt. Historische OCR-Konfidenz wird nicht erfunden.
4. `Demo.zslbackup` mit explizitem Emulator-Serial nach `/sdcard/Download/`
   kopieren. In der echten App über Einstellungen → Backup wiederherstellen
   und Android-Dateiauswahl importieren. Keine Nutzer-Backups verwenden.
   Das JPEG nach `/sdcard/Pictures/` kopieren, per Media-Scanner bekannt machen
   und im normalen Galerie-Dialog auswählen. Auf der Erfassungsseite den echten
   OCR-Lauf abwarten; für das Bild ist kein Speichern einer weiteren Ablesung nötig.
   Bei überarbeiteten Fixtures die eigene Emulator-App nach dem Import neu
   starten, bevor erneut aufgenommen wird: bereits geladene Detail-/Revisions-
   Ansichten können sonst noch den Stand vor der Wiederherstellung anzeigen.
5. Helles Theme, Animationen aus und echte Display-Geometrien konfigurieren:

   | Ziel | `adb -s <emulator> shell wm size` | `wm density` |
   | --- | --- | --- |
   | Smartphone | `1080x1920` | `390` |
   | 7-Zoll-Tablet | `1920x1080` | `288` |
   | 10-Zoll-Tablet | `2560x1440` | `288` |

   Nach jedem Größenwechsel kurz stabilisieren lassen und
   `python3 scripts/store_assets/device.py <emulator> status` für ruhige native
   Statusanzeigen ausführen. Das ist Android-Demomodus, keine Bildretusche.
   `dump`, `tap '<sichtbarer Text>'` und `capture <Datei.png>` unterstützen die
   echte UI-Navigation. Detailseiten bei Tablets bis zu den Ableseangaben scrollen.
   Das aktuelle Layout ist einspaltig; keine erfundene Tablet-Mehrspaltenansicht.
6. Sechs rohe Telefonaufnahmen als `raw/phone/01.png` bis `06.png` im Zielordner:
   Dashboard, Foto/OCR, kompletter Verlauf mit Suche, Ablesung mit Foto,
   echte PDF-Vorschau, Backup-Einstellungen. Tablets jeweils Dashboard,
   Verlauf, Ablesedetails und Einstellungen als `01-dashboard.png`,
   `02-history.png`, `03-reading.png`, `04-backup.png` in `tablet7/` und `tablet10/`.
   PDF über die reale App erstellen. Bei reproduziertem Preview-Fehler nicht
   retuschieren: gespeicherte PDF-Liste verwenden, Alttext anpassen und Fehler melden.
   Für die Tablet-Serie ist die echte Navigation ab Dashboard automatisiert:

   ```bash
   python3 scripts/store_assets/capture_tablet.py <emulator> 7 build/store-assets/de-DE/build-7
   python3 scripts/store_assets/capture_tablet.py <emulator> 10 build/store-assets/de-DE/build-7
   ```
7. Branding und Layout erzeugen, prüfen, paketieren:

   ```bash
   node scripts/store_assets/render.mjs assets build/store-assets/de-DE/build-7
   node scripts/store_assets/render.mjs contact build/store-assets/de-DE/build-7
   python3 scripts/store_assets/package.py build/store-assets/de-DE/build-7 --aab build/releases/internal-test/zaehlerstandlog-1.0.0-build-7-internal-test.aab
   python3 -m unittest discover -s scripts/store_assets -p 'test_*.py'
   ```

   `package.py` beschreibt aktuell ausdrücklich Build 7; für spätere Lieferungen
   Quellversion, Inhalt und Alttexte bewusst prüfen/anpassen. Es prüft Stückzahlen,
   RGB-PNG-Format, exakte Maße und Größenlimits und erzeugt Prüfsummen, Anleitung,
   Alttexte und ZIP. Anschließend **jede Grafik visuell ansehen** und PNGs mit
   ImageMagick `identify` vollständig dekodieren lassen. Metadaten ersetzen keine
   Sichtprüfung. Rohbilder, HTML und Buildausgaben sind ignoriertes Arbeitsmaterial.
8. Nur den selbst gestarteten Emulator mit seinem geprüften Serial beenden.
   Den Ausgabeordner öffnen; nichts automatisch in Google Play hochladen.

## Layoutregeln

Bestehendes SVG-Logo und Roboto-Schriften; kein neues Markenmotiv. Smartphone-
Header 330/1920 Pixel (<20%), UI proportional ohne Beschnitt oder Retusche.
Tablet-Screenshots ohne Werbetext, Device-Mockup oder Skalierungs-Tricks.
PNG24-Konvertierung entfernt nur den Alpha-Kanal, verändert keine UI-Inhalte.
Keine Rankings, Badges, offiziellen Zertifizierungen oder Installationsaufrufe.

Vorgaben: <https://support.google.com/googleplay/android-developer/answer/9866151?hl=en>
