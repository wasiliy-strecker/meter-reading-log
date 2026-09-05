# Sichtbare PDF-Prüfung entfernt

- Entfernt die PDF-Manipulationsprüfung aus Einstellungen, Navigation und Oberfläche.
- Blendet technische Prüfwerte in Ablesungen, PDF-Vorschau, Teilen-Texten und erzeugten PDFs vollständig aus.
- Erklärt Einzel- und Zählerverlaufsnachweise nur noch anhand ihrer verständlichen Inhalte und Verwendung.
- Behält interne Hashwerte für Backup-Schutz, Fotozuordnung und die Sperre identischer Einzelnachweise bei.
- Entfernt nicht mehr benötigte Verifizierungs-APIs und aktualisiert Dokumentation sowie Tests.

## Prüfung

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test` (63 Tests)
- PDF-Textprüfung mit `pdftotext`: keine sichtbaren Prüfwerte oder SHA-256-Angaben
- `flutter build apk --debug`
