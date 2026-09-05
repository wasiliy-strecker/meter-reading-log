# Erinnerungstest für beide Modi

- Den bisherigen Button „Ton jetzt testen“ durch den immer sichtbaren Button „Erinnerung jetzt testen“ ersetzt.
- Normale und pünktliche Test-Erinnerungen verwenden nun den jeweils ausgewählten Android-Benachrichtigungskanal.
- Testmeldungen zeigen Zählerart, Bezeichnung und – falls vorhanden – den letzten Zählerstand und öffnen beim Antippen den passenden Zähler.
- Ladezustand sowie verständliche Rückmeldungen für Erfolg, fehlende Berechtigung und nicht unterstützte Geräte ergänzt.
- Widget-Tests für beide Erinnerungsarten, Metadaten, Ladezustand und Berechtigungsfehler hinzugefügt.

## Prüfung

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
