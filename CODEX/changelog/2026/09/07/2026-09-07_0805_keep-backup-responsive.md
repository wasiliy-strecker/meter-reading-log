# Backup-Erstellung bedienbar halten

- JSON-Kodierung und große AES-Datenmengen in Hintergrund-Isolates verschoben.
- PBKDF2 und AES nutzen unter Android und iOS die beschleunigten Plattform-Implementierungen, wenn die Datengröße dafür geeignet ist.
- Auch Prüfung und Entschlüsselung bestehender Backups blockieren die Oberfläche nicht mehr.
- Während der Verarbeitung zeigt die Einstellungsseite einen verständlichen Status zur laufenden Aktion.
- Das bestehende verschlüsselte Backupformat und seine Sicherheitsparameter bleiben unverändert.
