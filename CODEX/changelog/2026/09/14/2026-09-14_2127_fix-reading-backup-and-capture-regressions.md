# ZählerLog: Speicherung, Wiederherstellung und Erfassung korrigieren

- SQLite-Schema 5 speichert Zeitstempel verlustfrei in Mikrosekunden. Transaktionale Migration aus Schema 1–4, angepasste Abfragen und Indizes sowie unverändertes Backupformat.
- Vorhandene Werte, Pfade und Prüfsummen bleiben bei der Migration erhalten. Bereits früher verlorene Mikrosekunden sind nicht rekonstruierbar; alte Manifest-Prüfsummen werden nicht nachträglich neu berechnet.
- Backup-Import aktualisiert Detail-, Korrektur- und PDF-Caches auch nach Teilschreibfehlern, ergänzt passende fehlende aktuelle/archivierte Fotos ohne Überschreiben neuerer lokaler Angaben und meldet deaktivierte Erinnerungen ab.
- OCR-Ausfälle erlauben manuelle Erfassung mit sichtbarem Foto, auch bei Ersatzfotos und wiederhergestellten Kameraaufnahmen. Ungespeicherte Fotos werden beim Verwerfen und nach verspäteter Fertigstellung aufgeräumt; einstellige OCR-Kandidaten sind zulässig.
- Zahlenparser validiert vollständige Eingaben und Dreiergruppierungen. Notiz-/Fotokorrekturen bewahren die numerische Bedeutung unveränderter alter Anzeigetexte. Notizkorrekturen behalten den ursprünglichen Zeitzonenversatz; echte Zeit-/Zeitzonenänderungen werden protokolliert.
- Native Fotoausgaben werden auf maximal 1920 Pixel an der längsten Kante begrenzt, bevor gespeichert und gehasht wird; vorhandene Fotos bleiben unverändert.
- Das Löschen einer Ablesung entfernt ihre Einzel-PDFs samt Metadaten. Verlaufs-PDFs und externe Kopien bleiben erhalten; Zählerlöschung entfernt weiterhin alle zugehörigen App-Daten. Löschfehler bleiben sichtbar und wiederholbar; keine automatische Bereinigung alter verwaister Dateien.
- README und AGENTS.md dokumentieren den weiterhin optionalen Korrekturgrund.

## Prüfung

- `dart run build_runner build` (wegen geändertem Drift-Schema).
- `dart format lib test`, `flutter analyze --no-pub` und `git diff --check`.
- `flutter test --no-pub --reporter expanded`: 217 Tests bestanden; ein opt-in Test für Store-Asset-Erzeugung regulär übersprungen.
- Neue Regressionstests für Migrationen aller bisherigen Schemata, SQLite-/Backup-Hash-Roundtrips, enge Zeitstempel-Sortierung, Zeitzonen und PDF-Zeitdarstellung, Cache-Aktualisierung bei erfolgreichem/fehlgeschlagenem Import, passende Fotoreparaturen, Alarmabmeldung, OCR-Ausfälle einschließlich Formularabschluss/Verwerfen, Altwertschutz, Fotogröße/Ausrichtung und PDF-Löschung mit Wiederholungsversuch.

## Gerätetest und Übernahme

- Gerät zunächst nicht verbunden; später Honor BVL-N49, Seriennummer `A5CS024205005243`, verbunden. ZählerLog Dev ist als `com.appfactory.meter_reading_log.dev`, Version `1.0.0+6`, Debuggable, ohne angegebenen Installer installiert. Im Vordergrund war AI Contract Manager Dev.
- `flutter attach --debug --app-id com.appfactory.meter_reading_log.dev -d A5CS024205005243` erhielt keine Dart-VM-Verbindung; den wartenden Attach-Prozess ohne Geräteänderung beendet. Kein Hot Reload, Restart, APK-Build oder Install. Die installierte App enthält diese Änderungen noch nicht.
- Für den echten Gerätetest ZählerLog Dev ohne ungespeicherte Eingaben öffnen und erneut verbinden. Vor dem ersten Restart VM-PID und Root-Library nach AGENTS.md verifizieren. Die Schema-/Provideränderungen benötigen Hot Restart; die Live-Änderung aktualisiert nicht das dauerhaft installierte APK.
- Noch am Gerät zu prüfen: synthetisches großes Quer-/Hochformatfoto erfassen und längste Kante kontrollieren; synthetischen Erinnerungsfall per Backup deaktivieren und ausbleibenden Alarm prüfen. Diese nativen Abläufe wurden hier über austauschbare Testimplementierungen geprüft, nicht am Telefon.
