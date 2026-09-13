# Einheitliche Fünfer-Seiten für Ablesungen und Verlaufs-PDFs

- Die Zählervorschau bleibt bei fünf Ablesungen. „Alle Ablesungen anzeigen“
  erscheint erst ab sechs; der vollständige Verlauf verwendet ebenfalls fünf
  Einträge pro Seite. Die Suche durchsucht weiterhin den gesamten Verlauf.
- Das Suchfeld hat 18 px Eckenradius wie die Karten, auch bei Fokus.
- Gespeicherte Zählerverlaufs-PDFs bleiben oberhalb der Ablesungen aufklappbar,
  jetzt mit fünf Nachweisen je Seite, Gesamtanzahl und Zurück/Weiter.
- Neue paginierte Repository-Abfrage für Drift und In-Memory, gefiltert nach
  Zähler und Nachweisart, stabil sortiert nach Erstellzeit und ID absteigend.
  SQLite liefert nur die angeforderte Seite plus eine separate Gesamtanzahl;
  keine Schemaänderung oder Migration.
- Dateiverfügbarkeit wird nur für die aufgeklappte Seite asynchron geprüft.
  Keine PDF-Inhalte beim Listenaufbau. Fehlende Dateien bleiben löschbar;
  Abfrage-/Dateiprüffehler bieten Wiederholen an.
- Nach PDF-Erstellung zurück auf Seite eins, nach Löschung auf die letzte
  gültige Seite. Einzel-PDFs, bestehende Dateien und die vollständige
  PDF-Erstellung bleiben unverändert.

## Prüfung

- `dart format lib test` und `git diff --check`: sauber.
- `flutter analyze --no-pub`: keine Befunde.
- `flutter test --no-pub`: alle 167 Tests bestanden.
- Tests für 0/1/2/5/6/11 Ablesungen, Suche und Seitenrückkehr; 100 PDF-Nachweise
  über alle 20 Seiten, Meter-/Artfilter, Zeitgleichstand, begrenzte Deserialisierung,
  keine Dateiprüfung im geschlossenen Bereich, letzte Seite löschen, fehlende
  Dateien, Wiederholen und 320 px Displaybreite.

## Dev / Release

- Vorhandene Dev-App auf HONOR BVL-N49 geöffnet und erneut verbunden. Hot Reload
  meldete nach dem Attach null aktualisierte Bibliotheken; anschließend wurde
  ein Hot Restart der Dart-Sitzung erfolgreich ausgeführt. Abschließende Sichtprüfung noch
  nicht bestätigt, da inzwischen eine andere App im Vordergrund aktiv ist.
- Kein APK-/AAB-Build, keine Installation, keine Datenlöschung und kein Play-Upload.
  Projektversion bleibt `1.0.0+5`; vorhandene Play-App bleibt unangetastet.
