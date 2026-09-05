# Wecker-Einstellung und Rückweg aus Erinnerungen

- In Debug-Builds direkt bei „Pünktlich mit Ton“ einen Button zur Android-Einstellung „Alarme & Erinnerungen“ ergänzt.
- Einen separaten Plattformaufruf hinzugefügt, der die Einstellungsseite auch bei bereits erteilter Freigabe öffnet.
- Zählerdetailseiten besitzen nun immer einen sichtbaren Zurück-Pfeil.
- Öffnet eine Erinnerung die Zählerseite als Root, führen Zurück-Pfeil und Android-Edge-Geste zum Dashboard statt aus der App.
- Lade-, Fehler- und Nicht-gefunden-Zustände verwenden denselben sicheren Rückweg.
- Widget-Tests für den Einstellungslink und beide Rückwege ergänzt.

## Prüfung

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
