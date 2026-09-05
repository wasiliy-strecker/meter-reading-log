# Fehlende Weckerfreigabe verständlich anzeigen

- Bei ausgewähltem Modus „Pünktlich mit Ton“ einen deutlichen Warnhinweis zur Android-Freigabe „Alarme & Erinnerungen“ ergänzt.
- Der Hinweis bleibt beim erstmaligen Antippen und während des Wechsels in die Android-Einstellungen verborgen.
- Nach der Rückkehr wird die Freigabe erneut geprüft; nur bei weiterhin fehlender Freigabe erscheint der Hinweis mit direktem Einstellungsbutton.
- Nach erteilter Freigabe verschwindet der Hinweis automatisch, ohne die Modusauswahl zurückzusetzen.
- Den Erstaufruf, die Rückkehr ohne Freigabe und das anschließende Erteilen der Freigabe per Widget-Test abgesichert.

## Prüfung

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
