# Verlauf verständlicher dargestellt

- Ersetzt den unauffälligen PDF-Ladezustand durch ein nicht wegklickbares Ladefenster mit Erklärung und kontrastreichem Ladebalken.
- Lässt den Button „Verlauf als PDF erstellen“ während der Verarbeitung optisch stabil.
- Zeigt in jeder Verlaufskarte einen Ausschnitt des zugehörigen Nachweisfotos.
- Beschriftet Wert und Zeitpunkt klar als „Zählerstand“ und „Abgelesen am“.
- Ergänzt einen Bildplatzhalter für lokal nicht verfügbare Fotos und aktualisiert die Widget-Tests.

## Prüfung

- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
