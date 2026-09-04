# Fotos in den Korrekturverlauf integrieren

- Das bei einer Korrektur neu gewählte Foto direkt im zugehörigen
  Verlaufseintrag angezeigt und das ersetzte Foto dort aufklappbar gemacht.
- Den getrennten Bereich `Frühere Fotos` aus Ablesungsansicht und PDF entfernt,
  ohne gespeicherte Foto-Versionen oder Integritätsdaten zu löschen.
- Foto-Versionen anhand ihrer gespeicherten Prüfwerte und Zeitpunkte zuverlässig
  den jeweiligen Korrekturen zugeordnet; fehlende Zuordnungen werden abgefangen.
- Die PDF stellt vorheriges und neues Foto kompakt nebeneinander in der
  betreffenden Korrektur dar.
- Tests für mehrere Foto-Korrekturen, fehlende Zuordnungen, die aufklappbare
  Smartphone-Darstellung und die PDF-Ausgabe ergänzt.

## Verifikation

- `flutter analyze`
- `flutter test` (48 Tests)
