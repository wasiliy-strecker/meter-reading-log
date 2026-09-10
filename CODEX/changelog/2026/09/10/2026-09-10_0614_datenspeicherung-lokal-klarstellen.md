# Lokale Datenspeicherung klarstellen

- Den Aufbewahrungshinweis in den Einstellungen präzisiert: App-Daten bleiben
  lokal auf dem Gerät gespeichert, bis sie in der App oder als App-Daten
  gelöscht werden.
- Den bestehenden Hinweis zur separaten Löschung extern gespeicherter PDFs und
  Backups beibehalten.
- Die vollständige Formulierung mit einem Widget-Test abgesichert.

## Verifikation

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test` (113 Tests)
- `flutter build apk --debug`
