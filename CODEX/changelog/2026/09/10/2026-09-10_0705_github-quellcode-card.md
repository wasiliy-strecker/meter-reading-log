# GitHub-Quellcode als eigene App-Info darstellen

- Datenschutz und App-Informationen in den Einstellungen in zwei eigenständige
  Bereiche aufgeteilt.
- Die bisherige reine Lizenzzeile durch eine vollständig antippbare
  „Quellcode auf GitHub“-Zeile mit Open-Source- und MPL-Hinweis ersetzt.
- App-Version in den neuen Abschnitt „Über ZählerstandLog“ verschoben.
- Datenschutz- und GitHub-Verweise verwenden dieselbe testbare externe
  Browseröffnung mit jeweils verständlicher Fehlermeldung.

## Verifikation

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test` (115 Tests)
- `flutter build apk --debug`
- Datenbewahrende Installation mit
  `adb install -r -t -g --no-streaming build/app/outputs/flutter-apk/app-debug.apk`
- Android 16 / Honor BVL-N49: zwei vorhandene Zähler erhalten, Layout und
  Scrollverhalten geprüft, GitHub-Repository in Chrome geöffnet und fehlerfrei
  zur App zurückgekehrt.
