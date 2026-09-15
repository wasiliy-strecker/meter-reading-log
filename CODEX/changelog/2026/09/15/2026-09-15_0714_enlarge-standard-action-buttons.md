# Einheitliche, besser treffbare Aktionsbuttons

- Umrandete, ausgefüllte und erhöhte Standardbuttons verwenden in beiden Themes eine gemeinsame Mindesthöhe von 50, Schriftgröße 16 und Innenabstände von horizontal 16 / vertikal 10. Schriftgewicht, Rundungen und zustandsabhängige Farben bleiben erhalten.
- Beschriftungen dieser Buttons zentriert; lange Texte dürfen umbrechen und die Mindesthöhe überschreiten. Bearbeiten-/Löschen-Aktionen und PDF-Erstellung sind damit gleich groß. Reine Textbuttons, Symbolbuttons und Auswahlchips unverändert.
- Zähleranzahl und Sortierbutton im Dashboard dürfen bei Platzmangel auf getrennte Zeilen wechseln, statt bei großer Schrift horizontal überzulaufen.

## Prüfung

- `dart format lib test`, `flutter analyze --no-pub` und `git diff --check` erfolgreich.
- Vollständige Testsuite: 217 Tests bestanden, ein opt-in Store-Asset-Test regulär übersprungen. Nach der abschließenden Dashboard-Anpassung Analyse und alle 17 Tests aus `test/widget_test.dart` erneut erfolgreich ausgeführt.
- Vorhandene Layouttests prüfen das Formular bei 320 logischen Pixeln Breite mit normaler und doppelter Schriftgröße in hellem und dunklem Theme.
- Dashboard und Zählerdetails am verbundenen Honor-Gerät visuell geprüft: Bearbeiten, Löschen und PDF-Erstellung mit gleicher Höhe und Schriftgröße, Beschriftungen vollständig sichtbar. Weitere Bedienungstests übernimmt der Nutzer.

## Geräteübernahme

- Vor der Übernahme VM-PID mit der Dev-App abgeglichen und Root-Bibliothek `package:meter_reading_log/main.dart` geprüft.
- Die bestehende Dev-App aus einer sicheren Detailansicht mit Debug-Startparametern verbunden. Der erste Hot Reload lud keine Bibliotheken; den aktuellen Stand anschließend mit Hot Restart erfolgreich übernommen. Die Verbindung bleibt für weitere Iterationen offen.
- Keine APK-Erstellung oder Installation, keine Versionsänderung und kein Play-Upload. Die Darstellungsänderung gilt für die laufende Sitzung; das installierte APK enthält weiterhin den vorherigen Buttonstand.
