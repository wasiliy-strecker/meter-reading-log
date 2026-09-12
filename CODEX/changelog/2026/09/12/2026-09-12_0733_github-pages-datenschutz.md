# Datenschutzerklärung auf GitHub Pages umstellen

- Deutsche und englische Erklärung aus der bisherigen AppFabrik-Webseite in
  eigenständige statische Seiten unter `docs/` übernommen; responsives Layout
  mit Hell-/Dunkelmodus, ohne JavaScript, externe Schriftarten oder Tracking.
- GitHub-Pages-Hosting einschließlich IP-Verarbeitung ausdrücklich von lokalen
  App-Daten getrennt beschrieben. Kontakt, Support-Aufbewahrung und Betroffenenrechte
  stehen direkt auf den Seiten und benötigen keine AppFabrik-Webseite mehr.
- Neue deutsche Adresse für App und Play Console:
  `https://wasiliy-strecker.github.io/meter-reading-log/datenschutz/`.
  Englisch: `https://wasiliy-strecker.github.io/meter-reading-log/privacy/`.
- App-Link und zugehörigen Widget-Test angepasst; Versionscode für den nächsten
  Play-Upload auf `1.0.0+2` erhöht. Alte Datenschutzseite für bestehende Builds
  unverändert erreichbar gelassen; AI Contract Manager nicht verändert.
- Pages-Veröffentlichung aus `main:/docs` und den manuellen Play-Console-Schritt
  im README dokumentiert. App-Bundles und persönliche Daten bleiben außerhalb von Git.

## Verifikation

- `dart run build_runner build`, `dart format lib test`, `flutter analyze` erfolgreich.
- `flutter test`: alle 115 Tests erfolgreich, einschließlich Datenschutzlink und Fehlerfall.
- `flutter build apk --debug --flavor dev` erfolgreich; Dev-APK mit `adb install -r -t -g --no-streaming`
  datenbewahrend auf dem angeschlossenen Smartphone aktualisiert und gestartet.
- Lokaler Browser-Smoke-Test: beide Sprachfassungen bei 320, 390 und 1280 Pixeln,
  jeweils hell/dunkel und ohne JavaScript; keine horizontale Überbreite,
  Sprachwechsel und interne Links erfolgreich, CSS lokal geladen, keine externen
  Ressourcen oder Cookies. Mobile Ansichten zusätzlich visuell geprüft.
- Bisherige deutsche AppFabrik-Datenschutzadresse antwortet weiterhin mit HTTP 200.
