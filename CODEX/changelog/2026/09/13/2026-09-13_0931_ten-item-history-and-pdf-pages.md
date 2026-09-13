# Zehn Einträge in Verlauf und Verlaufs-PDF-Listen

- Zählervorschau von fünf auf zehn Ablesungen erhöht. Der Einstieg
  „Alle Ablesungen anzeigen“ erscheint damit erst ab elf Ablesungen.
- Vollständiger Zählerverlauf einschließlich Suche: zehn Treffer je Seite.
- Gespeicherte Zählerverlaufs-PDFs: zehn Nachweise je Seite, auch beim ersten
  Aufklappen. Gesamtanzahl, asynchrone Dateiprüfung und begrenzte Abfragen bleiben.
- Suchfeld-Rundung, Einzel-PDF-Listen und der vollständige Inhalt erzeugter
  PDFs bleiben unverändert. README an die neuen Grenzen angepasst.

## Prüfung

- `dart format lib test`, `flutter analyze --no-pub`, `git diff --check`: sauber.
- Alle 17 fokussierten Widget-Tests bestanden: Grenzfälle 0/1/9/10/11/21,
  Suche und Rückkehr, letzte Seite löschen, 100 PDFs über zehn Seiten,
  fehlende Dateien, Wiederholen und schmales Display.
- Hot Reload in der bestehenden Dev-Sitzung angefordert. Die Sichtprüfung
  übernimmt der Nutzer; keine Smartphone-Navigation oder Bestätigungsfrage.
- Kein APK-/AAB-Build, keine Installation, kein Test-Release oder Versionssprung.
