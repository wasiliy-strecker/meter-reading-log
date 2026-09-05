# PDF-Loader vor der Erstellung anzeigen

- Der PDF-Dialog meldet nun seinen ersten gerenderten Frame, bevor der Export beginnt.
- Fotoaufbereitung, PDF-Erzeugung und Prüfsummenberechnung laufen auf Android in einem Hintergrund-Isolate, damit der Loader sichtbar und animiert bleibt.
- Widget-Tests sichern die Startreihenfolge sowie das Schließen bei Erfolg und Fehlern ab.

Verifiziert mit `flutter analyze` und `flutter test` (57 Tests).
