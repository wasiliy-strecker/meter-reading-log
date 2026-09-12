# Kompakte Beispielfotos nur in der Dev-App

- Optionalen Link „Beispiele ansehen“ vor Kamera/Galerie sowie beim Ersetzen
  und Korrigieren eines Fotos ergänzt. Keine automatisch vorgeschaltete Ansicht.
- Galerie mit vier beschrifteten Beispielen, Wisch-Navigation, Pfeilen,
  Seitenzähler, Fotohinweis und Schließen. Nur Ansicht: kein Import, keine OCR
  und keine Änderung von Ablesungen. Bilder werden erst beim Öffnen geladen.
- Sichtbarkeit an `appFlavor == 'dev'` gebunden; die vier Asset-Einträge sind
  ebenfalls ausschließlich für `dev` freigegeben. Store und Builds ohne Flavor
  enthalten die Beispiele nicht.
- Aus den vorhandenen synthetischen PNG-Fixtures kleine JPEG-Vorschauen erzeugt:
  683 × 1024 Pixel, 55.143 / 132.411 / 71.111 / 97.370 Bytes, zusammen 356.035 Bytes.
  Die großen Originale bleiben unverändert und werden nicht gebündelt.
- Reproduzierbares App-lokales Vorbereitungsskript mit maximal 1024 Pixeln,
  JPEG-Qualität ab 80 und einer Obergrenze von 150 KiB pro Bild ergänzt.
  Verarbeitung und Speicherung echter Nachweisfotos bleiben unverändert.
- Galerie und Fotoquellen-Auswahl bleiben bei wenig Bildschirmhöhe scrollbar;
  Beispielbilder lassen sich auch bei einem Ladefehler problemlos schließen.

## Verifikation

- `dart run build_runner build`, `dart format lib test scripts/prepare_meter_photo_examples.dart`,
  `flutter analyze --no-pub` und `flutter test --no-pub --reporter expanded`
  erfolgreich; alle 137 Tests bestanden.
- Galerie-/Asset-Tests zusätzlich mit `flutter test --no-pub --flavor dev`
  und `--flavor store` ausgeführt: je 7 Tests erfolgreich, einschließlich
  Dateigrößen, Bildabmessungen, Dev-Einschluss und Store-Ausschluss.
- Widget-Tests prüfen Erstaufnahme, Foto-Ersetzen und Korrektur ohne zusätzliche
  Fotoaufnahme oder Speicherung; große Schrift, Querformat, Schließen, Android-
  Zurück, Wischen, Pfeile und fehlende Bilder ebenfalls abgedeckt.
- `flutter build apk --debug --flavor dev --no-pub` erfolgreich. APK-Paketkennung,
  Debug-Flag und Signatur mit der vorhandenen Dev-Installation abgeglichen.
  APK enthält genau die vier kleinen JPEGs, keine Original-PNGs.
- Dev datenbewahrend mit `adb install -r -t -g --no-streaming` aktualisiert und
  gestartet. Galerie auf dem Smartphone visuell geprüft; Pfeile, Wischen und
  Android-Zurück funktionieren. Datenbank-Prüfsumme vor/nach dem Update identisch.
- Play-Installation unverändert: gleiche Version, Installer und Updatezeit.
  Kein Store-AAB, Test-Release, Upload oder Versionssprung für diese Aufgabe;
  App-Version bleibt `1.0.0+2`.
