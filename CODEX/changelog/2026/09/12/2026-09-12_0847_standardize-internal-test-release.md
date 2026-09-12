# Klarer Dev-/Play-Release-Ablauf

- App-Guide und README legen den festen Ablauf fest: neue Upload-Buildnummer,
  Prüfungen, Store-AAB, versionierte Datei, Ordner und kopierbare deutsche
  Release-Notizen. Dev bleibt parallel installiert; kein routinemäßiger
  Datenumzug und keine Neuinstallation beim Erstellen eines Test-Releases.
- Signaturkonflikte, getrennte Daten und die einmalige Altbestandsmigration
  dokumentiert. Bei fehlendem Play-Test auch das tatsächlich aktive Konto in
  der Play-Store-App prüfen, nicht nur das Browserkonto.
- App-lokales `scripts/build_internal_test_aab.sh` ergänzt: feste Store-/Release-
  Argumente, Prüfung von Paket, Variante und Version, Schutz vorhandener Dateien
  und kein Installieren, Löschen, Hochladen oder automatisches Versionieren.
- Benannte Upload-Dateien gehen nach `build/releases/internal-test/`, außerhalb
  von Flutters Bundle-Suche. So werden ältere AAB-Dateien nicht als neue
  Ergebnisse ausgewählt. Bereits ausgelieferte Dateien im alten Ordner bleiben
  ebenfalls geschützt.
- Den übergreifenden Standard zusätzlich in der App-Factory-`AGENTS.md`
  festgehalten. Diese übergeordnete Workspace-Datei liegt außerhalb dieses
  App-Git-Repositories; die vollständige app-spezifische Anleitung ist hier
  versioniert. Andere Apps und ihre Konfiguration wurden nicht geändert.

## Verifikation

- `bash -n scripts/build_internal_test_aab.sh` erfolgreich.
- 15 isolierte Skript-Tests mit synthetischen Bundles/Fake-Flutter, einschließlich
  Erfolg, Fehlerfälle, fremdem Arbeitsverzeichnis, Leerzeichen im Pfad,
  Versions-/Variantenabweichungen und Erhalt bereits ausgelieferter Dateien.
- `dart run build_runner build`, `dart format lib test`, `flutter analyze` und
  `flutter test --reporter expanded` erfolgreich: alle 130 Tests bestanden.
- `flutter build apk --debug --flavor dev` und
  `flutter build appbundle --release --flavor store` erfolgreich.
- Store-Paketkennung mit Bundletool, Build-Metadaten und Manifest ohne Debug-
  oder Netzwerkrechte geprüft; `jarsigner -verify` meldet `jar verified.`.
- Skript-Aufruf für die vorhandene Version `1.0.0+2` stoppt erwartungsgemäß vor
  einem Build. SHA-256 der bereits ausgelieferten versionierten AAB unverändert.
- Dev-App auf dem verbundenen Android-Gerät wieder in den Vordergrund geholt.
  Beide Pakete weiterhin vorhanden; Store-Installer `com.android.vending`,
  Store ohne Debug-Flag, Dev mit Debug-Flag. Keine Installation oder Löschung.
- App-Version bleibt `1.0.0+2`; kein neuer Play-Release oder Upload für diese Aufgabe.
