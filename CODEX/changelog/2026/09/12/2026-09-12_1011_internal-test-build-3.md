# Interner Play-Test 1.0.0, Build 3

- Buildnummer von `1.0.0+2` auf `1.0.0+3` erhöht; Versionsname unverändert.
- Neuen Store/Release-Teststand über `scripts/build_internal_test_aab.sh`
  mit der vorhandenen privaten Upload-Signierung erstellt.
- Upload-Datei: `build/releases/internal-test/zaehlerstandlog-1.0.0-build-3-internal-test.aab`
  (69.034.699 Bytes). Der Ordner wurde für den manuellen Play-Upload geöffnet.
- Beispielfotos bleiben ausdrücklich Dev-only. Keine zusätzlichen
  Store-Nutzerfunktionen für diesen Test-Release freigeschaltet.
- Kein Dev-APK, keine Installation, kein App-Neustart, kein Datenumzug und kein
  automatischer Play-Upload. Bestehende Dev-/Play-Installationen unverändert.

## Verifikation

- `dart format lib test` und `flutter analyze --no-pub` erfolgreich.
- Vollständige Suite mit `flutter test --no-pub --flavor store`: 138 Tests
  erfolgreich. Zusätzliche Galerie-/Asset-Tests mit `--flavor dev`: 8 erfolgreich.
- Store-AAB erfolgreich gebaut und mit `bundletool validate` geprüft.
- Manifest direkt aus dem ausgelieferten AAB geprüft: Paket
  `com.appfactory.meter_reading_log`, Version `1.0.0` / Code `3`, keine
  Debug-Markierung, keine Netzwerkberechtigungen, Android-Backup deaktiviert.
- Keine Dev-Beispielbilder oder großen Original-Fixtures im AAB enthalten.
- JAR-Signatur gültig; SHA-256 des Upload-Zertifikats identisch zu Build 2:
  `1D:64:D5:0C:CF:5F:20:E8:BC:81:85:37:E4:10:4D:22:65:74:6F:78:35:C4:6A:9F:81:FF:85:05:1A:25:7B:55`.
  Die JDK-Warnungen zu selbstsigniertem Zertifikat und JarInputStream-Reihenfolge
  treten auch beim bereits ausgelieferten Build 2 auf.
- Benannte Build-3-Datei bytegleich zum aktuellen `app-store-release.aab`.
  Ältere benannte Build-2-Datei unverändert; Flutter zeigte diese beim
  Build-Abschluss erneut als Fundstelle an, der Release-Helfer lieferte korrekt
  die anhand von Metadaten und tatsächlichem Manifest geprüfte Build-3-Datei.
- Abhängigkeitssperrdatei unverändert; Signierungsdateien und AAB bleiben ignoriert.
- SHA-256 des neuen AAB:
  `58515acaf871340e20646f50d73aafc3dc6d8cdb25fe33c0c34f2d2455eb66b3`.

## Release-Notizen

Titel: `1.0.0 – Interner Test 3`

```text
<de-DE>
Aktueller interner Teststand von ZählerstandLog
Zum Testen von Zählererfassung, PDF-Nachweisen und verschlüsselten Backups
</de-DE>
```
