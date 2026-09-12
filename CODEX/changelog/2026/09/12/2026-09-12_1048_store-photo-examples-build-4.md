# Beispielfotos im Play-Test – Build 4

- „Beispiele ansehen“ für die Store-App freigegeben. Den Dev-Provider und die
  Flavor-Beschränkung der vier JPEGs entfernt; die Galerie ist nun ohne
  Entwickleroption verfügbar, auch in Builds ohne Flavor.
- Erstaufnahme, Foto-Ersetzen und Korrektur verwenden dieselbe bestehende
  Galerie. Kleine Schrift (14 px), Symbol (20 px), Zentrierung, gleiche Abstände,
  mindestens 48 px hohe Touchfläche und verzögertes Laden bleiben erhalten.
- Die Galerie bleibt eine optionale Ansicht: keine automatische Fotoauswahl,
  OCR oder Speicherung; Kennzeichnung als KI-generierte Beispiele unverändert.
- Vorschauen nicht neu verarbeitet: 55.143 / 132.411 / 71.111 / 97.370 Bytes,
  zusammen 356.035 Bytes, maximal 1024 Pixel. Große Original-Fixtures bleiben
  ungebündelt. Historische Asset-Pfade bleiben stabil.
- README und Fixture-Dokumentation aktualisiert; Versionsnummer `1.0.0+4`.

## Verifikation und Auslieferung

- `dart format lib test` und `flutter analyze --no-pub` erfolgreich.
- Vollständige Store-Testsuite: 138 Tests erfolgreich. Zusätzliche Galerie- und
  Aufnahmebildschirm-Tests in Dev: 15 erfolgreich. Keine künstliche
  Entwickler-Freischaltung mehr in den Widget-Tests.
- Tests prüfen standardmäßig sichtbaren Einstieg, unveränderte Typografie,
  gleiche Abstände, Navigation, Schließen, große Schrift, Ladefehler sowie
  enthaltene Bildbytes und Größenbudget (150 KiB/Bild, 400 KiB gesamt).
- Store-AAB mit `scripts/build_internal_test_aab.sh` erstellt und mit bundletool
  validiert. Tatsächliches Manifest: Store-Paket, Version `1.0.0` / Code `4`,
  kein Debug-Flag, keine Netzwerkrechte und Android-Backup deaktiviert.
- Alle vier JPEGs direkt im ausgelieferten AAB nachgewiesen und byteweise mit
  den unveränderten Vorschauen verglichen; keine Original-PNGs enthalten.
- JAR-Signatur gültig; vorhandenes Upload-Zertifikat unverändert. Bekannte
  JDK-Warnungen zum selbstsignierten Zertifikat und JarInputStream wie bei den
  bisherigen AABs, keine neue Signierungsidentität.
- Upload-Datei: `build/releases/internal-test/zaehlerstandlog-1.0.0-build-4-internal-test.aab`
  (69.372.999 Bytes), bytegleich zum aktuellen `app-store-release.aab`.
  Ältere benannte Builds 2 und 3 unverändert; Ordner in einem neuen Fenster
  geöffnet und Build 4 zur Auswahl angefordert.
- SHA-256: `adf17a8c65686bc3975e5aba7f7125d45607e01e3fb1e7ac4f29c691dd7b21d9`.
- Kein Dev-APK, keine Codegenerierung, keine Geräteinstallation, kein App-Neustart,
  kein Datenumzug und kein automatischer Play-Upload.

## Release-Notizen

Titel: `Beispielfotos für die Zähleraufnahme`

```text
<de-DE>
Beispiele ansehen ist jetzt auch in der Play-Version verfügbar
Vier kompakte Beispielfotos für Strom-, Gas- und Wasserzähler helfen bei der Aufnahme
Auch beim Ersetzen und Korrigieren eines Fotos verfügbar
</de-DE>
```
