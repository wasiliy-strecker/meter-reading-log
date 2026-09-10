# ZählerstandLog 1.0.0 für den Play Store vorbereitet

- Die App-Version auf `1.0.0+1` angehoben und die sichtbare Versionsangabe in
  den Einstellungen an die tatsächlichen Paketinformationen gebunden.
- Die Android-Release-Konfiguration von der Debug-Signatur auf einen lokalen,
  nicht eingecheckten Upload-Keystore umgestellt und eine sichere Beispielkonfiguration
  sowie die Build-Anleitung ergänzt.
- Den R8-Releasefehler für nicht mitgelieferte optionale ML-Kit-Schriften mit
  den vom Android-Build erzeugten `-dontwarn`-Regeln behoben.
- Ein eigenes Release-Manifest entfernt die von einer Android-Abhängigkeit
  eingebrachten Netzwerkberechtigungen; Entwicklungs-Builds behalten Hot Reload.
- Das signierte App Bundle unter
  `build/app/outputs/bundle/release/app-release.aab` erzeugt (68.976.947 Byte,
  SHA-256 `9dfaebd6847ef23a57e69123b2e9a3fb5c598b65ccee842d46a8b7018854773f`).

## Verifikation

- `dart run build_runner build`
- `dart format lib test`
- `flutter analyze`
- `flutter test` (115 Tests bestanden)
- `flutter build apk --debug`
- `flutter build appbundle --release`
- Release-Manifest: Paket `com.appfactory.meter_reading_log`, Version
  `1.0.0 (1)`, Target SDK 36, keine `INTERNET`- oder
  `ACCESS_NETWORK_STATE`-Berechtigung.
- AAB-Zertifikat stimmt mit dem Upload-Schlüssel überein und unterscheidet sich
  vom Android-Debugzertifikat.
- Alle 64-Bit-Bibliotheken im AAB besitzen mindestens 16-KB-LOAD-Ausrichtung.
- Debug-APK auf dem angeschlossenen Android-Gerät per `adb install -r` ohne
  Datenlöschung aktualisiert; App-Start und Paketversion `1.0.0` bestätigt.
