# Photo Picker und Datenschutz absichern

- Android-Galerieauswahl auf den direkten System-Photo-Picker umgestellt, um
  den instabilen `GET_CONTENT`-/DocumentsUI-Umweg zu vermeiden.
- Android-Systembackups deaktiviert und Cloud- sowie Geräteübertragungen über
  Backup-Regeln für die privaten App-Daten ausgeschlossen.
- Einstellungen um Entwicklerkontakt, Aufbewahrungs-/Löschhinweis und einen
  Link zur eigenen ZählerstandLog-Datenschutzerklärung ergänzt.
- Unzutreffende Originalfoto-Aussagen durch die tatsächliche JPEG-Optimierung
  auf maximal 1920 Pixel ersetzt; EXIF-Daten werden auch im Dart-Fallback
  entfernt und unoptimierbare Dateien nicht roh übernommen.
- Eigene deutsche und englische ZählerstandLog-Datenschutzseiten veröffentlicht:
  - `https://www.appfabrik-ai.de/de/apps/zaehlerstandlog/datenschutz/`
  - `https://www.appfabrik-ai.de/en/apps/meter-reading-log/privacy/`

## Verifikation

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test` (113 Tests)
- `flutter build apk --debug`
- Datenbewahrende Installation mit
  `adb install -r -t -g --no-streaming build/app/outputs/flutter-apk/app-debug.apk`
- Android 16 / Honor BVL-N49: vorhandene Zähler und Nachweise erhalten,
  Datenschutzlink im externen Browser geöffnet, Alben mehrfach gescrollt.
- Logcat bestätigt `android.provider.action.PICK_IMAGES` direkt zur
  `PhotoPickerActivity`; kein `GET_CONTENT` oder `TrampolineActivity`.
- Beide veröffentlichten Datenschutzseiten und die Sitemap liefern HTTP 200
  und enthalten Kontakt-, Aufbewahrungs- und Löschinformationen.
