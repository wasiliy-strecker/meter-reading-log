# Dashboard-Liste für viele Zähler optimiert

- Das Dashboard lädt den letzten Stand und das letzte Änderungsdatum aller
  Zähler über eine gebündelte, beobachtete Datenbankabfrage statt über eine
  separate Verlaufsabfrage pro Zähler.
- Neue Datenbankindizes beschleunigen die Suche nach dem letzten Stand und der
  letzten Änderung; bestehende Installationen werden auf Schema 4 migriert.
- Zählerkarten werden mit einer lazy Liste nur bei Bedarf aufgebaut. Suche,
  Sortierung und Erinnerungsstatus berücksichtigen weiterhin alle Zähler.
- Tests decken die Migration, korrekte Übersichten, 500 Zähler mit 10.000
  Ablesungen sowie lazy Rendering und vollständige Suche über 500 Zähler ab.
