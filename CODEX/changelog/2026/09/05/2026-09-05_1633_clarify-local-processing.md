# Lokale Verarbeitung verständlich erklären

- Den technischen Begriff „OCR-Daten“ aus Dashboard und Einstellungen entfernt.
- Im Dashboard verständlich erklärt, dass die gesamte Verarbeitung lokal auf dem Gerät stattfindet.
- In den Einstellungen die lokalen Schritte – Fotoauswertung, Speicherung und PDF-Erstellung – konkret benannt.
- Deutlich gemacht, dass die App keine Zählerdaten an einen Server sendet.
- Beide sichtbaren Datenschutztexte per Widget-Test abgesichert.

## Prüfung

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
