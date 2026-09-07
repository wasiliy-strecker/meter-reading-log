# Große Android-Backups ohne Zwischenkopie teilen

- Android teilt fertige Backups nun direkt über einen geschützten Datei-URI, statt sie vorher synchron in den `share_plus`-Cache zu duplizieren.
- Der Teilen-Aufruf kehrt direkt zurück, sodass die Fortschrittsanzeige nach der Erstellung nicht hängen bleibt.
- Vor einem neuen Backup werden ältere temporäre Backup-Dateien entfernt; extern gespeicherte Backups bleiben unberührt.
- Tests decken das Zurückkehren aus dem Fortschrittszustand sowie das Aufräumen alter temporärer Backups ab.
