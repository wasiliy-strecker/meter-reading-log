# Kompakte Backups und optimierte neue Fotos

- Neue Kamera- und Galerie-Fotos werden vor OCR, Prüfwert und Speicherung automatisch auf maximal 1920 Pixel bei hoher JPEG-Qualität optimiert; vorhandene Fotos bleiben unverändert.
- Das neue verschlüsselte Backupformat speichert Binärdateien ohne mehrfache Base64-Kodierung und legt identische Dateien anhand ihres SHA-256-Prüfwerts nur einmal ab.
- Bereits erstellte PDF-Nachweise bleiben vollständig enthalten und Backups des bisherigen Formats können weiterhin geprüft und wiederhergestellt werden.
- Die Backup-Erstellung läuft auf Android und iOS in einem Hintergrund-Isolate und meldet echten Byte- und Dateifortschritt an eine moderne Fortschrittsanzeige.
- Tests decken Fotoabmessungen, Deduplizierung, Roundtrips, alte Backups, falsche Passwörter, manipulierte Dateien und die Fortschrittsoberfläche ab.
