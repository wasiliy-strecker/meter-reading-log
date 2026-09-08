# Speicherort für verschlüsselte Backups

- Nach der Backup-Erstellung öffnet Android jetzt direkt die systemeigene Speicherortwahl, statt sofort den Teilen-Dialog anzuzeigen.
- Große Backup-Dateien werden nativ aus dem privaten Cache in den gewählten Speicherort gestreamt, ohne sie erneut vollständig in den Arbeitsspeicher zu laden.
- Eine Erfolgsanzeige nennt Dateiname, Größe, Erstellungszeit und Inhalt und bietet das Teilen optional an.
- Bei Abbruch oder Speicherfehler kann derselbe erzeugte Backup-Stand erneut gespeichert oder bewusst verworfen werden.
- Tests decken erfolgreiches Speichern, Abbruch, Wiederholen, Fehler und Teilen ab.
