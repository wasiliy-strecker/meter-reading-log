# Korrekturhinweis kürzen

- Ausschließlich die Passage „sowie – falls angegeben – deinen Grund“ aus dem Hinweis auf „Ablesung korrigieren“ entfernt; Satz endet jetzt nach „Vorher“ und „Neu“.
- Optionales Eingabefeld für den Korrekturgrund und Speicherung unverändert.
- Bestehenden Widget-Test um den vollständigen neuen Satz und die Abwesenheit der entfernten Passage ergänzt.
- Prüfung: `dart format lib test`, `flutter analyze --no-pub`, `flutter test --no-pub test/features/meters/capture_reading_screen_test.dart` (7 Tests) und `git diff --check` erfolgreich.
- Dev-Verbindung anhand PID und Root-Bibliothek geprüft; Hot Reload erfolgreich (1 Bibliothek). Kein Neustart, APK-/AAB-Build, Versionswechsel oder Play-Update. Live-Sitzung bleibt geöffnet; kein Push.
- Separater offener Befund: Das Dev-Log meldete vor und nach Hot Reload einen `RangeError` in `printing` / `PdfPreviewRaster._raster` (raster.dart:185). PDF-Vorschau in dieser reinen Textänderung nicht bearbeitet.
