# ZählerLog Dev mit den Fehlerkorrekturen aktualisieren

- Die Korrekturen aus `13dde06` als Dev-APK auf dem verbundenen Android-Gerät installiert und die App gestartet. Version `1.0.0+7` aus dem vorhandenen Projektstand, keine Versionsänderung.
- Konkreter Build-Grund: Die installierte Version `1.0.0+6` verwendete SQLite-Schema 4. Nach der Migration auf Schema 5 könnte ihre alte Laufzeit nach einem Kaltstart die umbenannten Spalten nicht mehr lesen. Deshalb war entgegen der früheren Hot-Restart-Empfehlung ein dauerhaft kompatibles Dev-APK erforderlich.
- Vor dem Update Zielpaket `com.appfactory.meter_reading_log.dev`, installierte Version, Debug-Flag und Installer geprüft. Das neue APK hat dieselbe Dev-Paketkennung und dasselbe Signaturzertifikat.
- Vorher eine private lokale Sicherheitskopie der App-Dateien außerhalb des Repositorys angelegt. Update mit `adb install -r -t -g --no-streaming`, ohne Deinstallation oder Datenlöschung. Store-App und andere Flutter-Sitzungen nicht verändert.

## Prüfung

- `flutter build apk --debug --flavor dev --no-pub` erfolgreich; Installation meldet `Success`.
- Dashboard nach dem Start sichtbar, keine Flutter-/AndroidRuntime-Fehler für den App-Prozess im abgefragten Log.
- Datenbank nach dem Start auf Schema 5. Alle bestehenden Datensätze vor/nach dem Update verglichen: 3 Zähler, 11 Ablesungen, 3 Korrekturen und 26 PDF-Exporte vollständig erhalten; ausschließlich die beabsichtigte Zeitstempelumrechnung.
- Keine neuen Codeänderungen; Analyse und 217 erfolgreiche Tests sind im Implementierungseintrag vom 14.09.2026 dokumentiert. Diesen Dokumentationsnachtrag mit `git diff --check` geprüft.
- Weitere Bedienungs- und Funktionstests übernimmt der Nutzer ausdrücklich selbst.
