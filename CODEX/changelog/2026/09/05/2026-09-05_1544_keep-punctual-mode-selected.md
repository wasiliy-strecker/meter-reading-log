# Pünktlichen Erinnerungsmodus beim Berechtigungswechsel behalten

- „Pünktlich mit Ton“ wird unmittelbar beim Antippen als Formularauswahl gesetzt.
- Die Auswahl bleibt erhalten, während Android die Freigabe „Wecker und Erinnerungen“ öffnet und nachdem man zur App zurückkehrt.
- Die verfrühte Berechtigungsprüfung während des Wechsels in die Android-Einstellungen entfernt.
- Die Freigabe wird weiterhin verbindlich beim Speichern geprüft.
- Android meldet nun korrekt zurück, ob die Einstellungsseite geöffnet werden konnte.
- Den Ablauf mit anfangs deaktivierter Weckerfreigabe per Widget-Test abgesichert.

## Prüfung

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
