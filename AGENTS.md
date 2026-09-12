# ZählerstandLog repository guide

ZählerstandLog ist eine unabhängige Flutter-App in der App Factory. Sie muss
ohne den AI Contract Manager baubar bleiben; keine gemeinsame Monorepo-Runtime
oder Abhängigkeit auf benachbarte App-Verzeichnisse einführen.

Feature-first Clean MVVM mit Riverpod beibehalten. Kamera, Dateispeicher, OCR,
Persistenz, Erinnerungen, PDF-Erzeugung und Backup bleiben hinter austauschbaren
Schnittstellen. Zählerstände werden als Ziffern plus Dezimalskala gespeichert,
nicht als `double`.

Zählerfotos und OCR-Inhalte sind privat. Keine `INTERNET`-Berechtigung,
Analytics, Remote-OCR, AI-Dienste, Konten, Kundendokumente oder Geheimnisse
hinzufügen. Nur synthetische Fixtures gehören in Tests.

Änderungen an gespeicherten Ablesungen müssen eine `ReadingRevision` mit Grund
erzeugen. Foto-, Manifest- und PDF-Hashing darf nicht stillschweigend entfernt
oder durch nicht deterministische Serialisierung geschwächt werden. Die App
darf lokale Prüfsummen nicht als amtlichen Zeitstempel oder garantierte
Beweiskraft bezeichnen.

## Prüfungen nach Änderungsart

- Reine Dokumentationsänderungen: Inhalt, Konsistenz und `git diff --check`
  prüfen. Keine Flutter-Codegenerierung, Analyse, Tests, Builds oder Geräteaktionen.
- Dart-/UI-Änderungen: `dart format lib test`, `flutter analyze` und passende
  fokussierte `flutter test <testdateien>` ausführen. Bei übergreifenden Änderungen
  und vor Releases die vollständige Suite mit `flutter test` ausführen.
- `dart run build_runner build` nur bei geänderten Generator-Eingaben oder
  Generator-Konfiguration ausführen, etwa Drift-Schema oder Annotationen.
- `flutter build apk --debug --flavor dev` nur bei einem konkreten Build-Grund
  nach den folgenden Geräteregeln, nicht pauschal vor jedem Commit.

Ein Commit oder Aufgabenabschluss allein ist kein Grund für einen APK-Build;
auch kein zusätzlicher Hintergrund-„Prüfbuild“ bei reinen UI-Anpassungen.

## Android-Varianten und Gerätetests

Android hat zwei unabhängig installierbare Varianten:

- `dev`: `com.appfactory.meter_reading_log.dev`, App-Name `ZählerstandLog Dev`.
  Lokale Entwicklung und Gerätetests verwenden `flutter run --flavor dev -d <device-id>`
  oder `flutter build apk --debug --flavor dev`. Die vorhandenen Debug-Optionen
  sind in Debug-Builds verfügbar.
- `store`: `com.appfactory.meter_reading_log`, App-Name `ZählerstandLog`.
  Interne Play-Tests und Veröffentlichung verwenden ausschließlich
  `flutter build appbundle --release --flavor store` mit Upload-Signierung.
  Store-Debug- und Store-Profile-Builds sind im Android-Build deaktiviert.

Auf verbundenen Android-Geräten niemals `flutter install` verwenden. Lokale
APKs nur datenbewahrend installieren:

```bash
adb -s <device-id> install -r -t -g --no-streaming build/app/outputs/flutter-apk/app-dev-debug.apk
```

Die Play-Installation niemals mit einem lokalen APK ersetzen. Dev und Store
bleiben parallel installiert. Ein Test-Release erfordert weder ein verbundenes
Smartphone noch eine Neuinstallation, Deinstallation oder Datenübertragung.
Dev und Store besitzen getrennte Daten und Android-Berechtigungen; ein Backup
kann auf ausdrücklichen Wunsch über die bestehende Wiederherstellung übertragen
werden.

Für Schrift-, Abstands- und andere reine Dart/UI-Anpassungen zuerst die laufende
Dev-Verbindung mit Hot Reload aktualisieren; dafür kein APK neu bauen oder
installieren. `default-flavor: dev` in `pubspec.yaml` hält auch die
Dev-Konstanten und Dev-Assets beim erneuten Verbinden korrekt:

```bash
flutter attach --debug --app-id com.appfactory.meter_reading_log.dev -d <device-id>
```

Die Verbindung für weitere UI-Iterationen offen halten (`r` für Hot Reload).
Änderungen an `main()`, `initState()`, Initialisierung oder von Hot Reload nicht
unterstützte Dart-Änderungen bei Bedarf mit Hot Restart (`R`) übernehmen; das
erfordert keinen APK-Build. Kompilierungsfehler zuerst beheben, nicht durch
Neubau umgehen. Vor einem Neustart ungespeicherte Eingaben berücksichtigen.
Falls die Verbindung zur manuell geöffneten App nicht klappt, die Dev-App bei
einem sicheren UI-Zustand ohne ungespeicherte Eingaben mit Debug-Startparametern
neu starten und erneut verbinden, statt sie zu installieren:

```bash
adb -s <device-id> shell am start -S -n com.appfactory.meter_reading_log.dev/com.appfactory.meter_reading_log.MainActivity --ez enable-dart-profiling true --ez enable-checked-mode true --ez verify-entry-points true
```

Hot Reload aktualisiert die laufende Sitzung, nicht das dauerhaft installierte
APK; das gilt auch für Hot Restart. Nicht behaupten, die Live-Änderung sei nach
einem Kaltstart weiterhin installiert. Eine fehlende Live-Verbindung allein ist
kein Build-Grund.

Ein Dev-APK nur neu bauen, wenn nativer Code, native Plugins, Manifest,
Berechtigungen oder Android-Buildkonfiguration geändert wurden, keine passende
Dev-Installation vorhanden ist oder ausdrücklich ein dauerhaft aktualisiertes
APK gewünscht wird. Den konkreten Grund vor dem Build kurz nennen.

Bei Assets und Abhängigkeiten nur die nötige Vorbereitung durchführen, etwa
`flutter pub get`, danach passend reloaden oder neu starten. Nicht jede Asset-,
reine Dart-Paket- oder `pubspec.yaml`-Änderung verlangt einen APK-Build. Erst wenn
die native Installation oder eine nicht über die Live-Sitzung aktualisierbare
gebündelte Ressource betroffen ist, entsprechend neu bauen.

Maßgeblich ist die [Flutter-Anleitung zu Hot Reload und Neustarts](https://docs.flutter.dev/tools/hot-reload).
Store-Release-Befehle geben weiterhin ausdrücklich `--flavor store` an.

Vor einem APK-Update die exakte Ziel-Paketkennung, installierte Version,
Debug-Flag und Installer prüfen. Bei möglicher abweichender Signierung zuerst
die Zertifikate prüfen. Ein Play-App-Signing-Zertifikat muss nicht dem lokalen
Upload-Zertifikat entsprechen. `INSTALL_FAILED_UPDATE_INCOMPATIBLE` nicht durch
automatische Deinstallation umgehen.

Die frühere Debug-App ohne `.dev` war ein einmaliger Altbestand; der Umstieg
auf parallele Dev-/Play-Installationen wurde bereits durchgeführt. Diesen
Umzug nicht bei jedem Release wiederholen. Nur falls tatsächlich erneut eine
alte Debug-Installation mit Store-Paketkennung gefunden wird: zuerst externes
verschlüsseltes Backup und Wiederherstellung prüfen, dann eine ausdrückliche
Freigabe zur Deinstallation genau dieser alten Installation einholen.

Nach Android-Buildänderungen zusätzlich das Store-AAB bauen und Paketkennung,
Release-Signatur sowie das zusammengeführte Manifest ohne Netzwerkrechte prüfen.
Das Store-AAB liegt unter `build/app/outputs/bundle/storeRelease/app-store-release.aab`.
Ein bereits hochgeladener Play-Release wird durch lokale Dev-Änderungen nicht
ersetzt; für einen späteren neuen Play-Upload muss der Versionscode erhöht werden.

## Schneller interner Test-Release

Bei „Test-Release erstellen“ den etablierten Ablauf selbstständig ausführen,
ohne erneut nach Dev-/Store-Aufteilung, Datenumzug oder Neuinstallation zu fragen:

1. Arbeitsstand und `pubspec.yaml` prüfen. Für einen neuen Upload die Buildnummer
   hinter `+` erhöhen, größer als alle bekannten bereits hochgeladenen Codes.
   Den Versionsnamen nur bei fachlichem Anlass ändern. Normale Dev-Arbeit und
   Dokumentationsänderungen brauchen keine neue Release-Version.
2. Formatierung, Analyse und die vollständige Testsuite ausführen;
   Codegenerierung nur bei betroffenen Generator-Eingaben oder Konfiguration.
   Kein zusätzlicher Dev-APK-Build allein wegen des Releases. Danach:

   ```bash
   ./scripts/build_internal_test_aab.sh
   ```

   Voraussetzungen: Flutter, Bash, `jq` und die bestehende private
   Upload-Signierung. Das Skript baut ausschließlich Store/Release, prüft
   Paketkennung, Variante und Version aus den Build-Metadaten und erzeugt:
   `build/releases/internal-test/zaehlerstandlog-<version>-build-<code>-internal-test.aab`.
   Es verändert keine Versionsnummer, überschreibt keine vorhandene benannte
   Datei und installiert, löscht oder veröffentlicht nichts.
3. Genau diese versionierte Datei nennen und ihren Ordner öffnen. Einen kurzen
   Release-Titel und direkt kopierbare deutsche Notizen mit `<de-DE>`-Tags
   liefern, ohne Aufzählungszeichen. Nicht versehentlich das alte
   `build/app/outputs/bundle/release/app-release.aab` aushändigen.
4. Der Nutzer lädt die Datei in den internen Play-Test hoch und aktualisiert die
   Store-App über Google Play. Dev bleibt unverändert nutzbar. Kein automatischer
   Play-Upload und keine Veröffentlichung ohne entsprechenden Auftrag.

Existiert die benannte AAB-Datei bereits, nicht für einen erneuten Download
neu bauen oder die Version erhöhen: den vorhandenen Release aushändigen. Nur
ein wirklich neuer Upload benötigt eine neue Buildnummer. Rückfragen auf
fehlende Informationen, rechtliche Bestätigungen durch den Nutzer und mögliche
Datenverluste beschränken.

Benannte Upload-Dateien außerhalb von `build/app/outputs/bundle/` ablegen:
Flutter kann dort sonst eine ältere AAB als Build-Ergebnis anzeigen. Maßgeblich
ist der abschließend vom Skript geprüfte und ausgegebene Pfad. Die früher dort
abgelegte versionierte Datei bleibt erhalten und wird ebenfalls gegen
versehentliches erneutes Erstellen derselben Version geschützt.

## Wenn der Play-Test nicht verfügbar ist

Zuerst zwischen fehlender Store-Seite und fehlgeschlagener Installation
unterscheiden. Aktiven Release, ausgewählte/gespeicherte Testerliste und
Testbeitritt prüfen. Insbesondere das Konto **in der Android-Play-Store-App**
kontrollieren; das korrekte Browserkonto allein reicht nicht. Danach konkrete
Gerätekompatibilität oder Installations-/Signaturfehler prüfen. Wartezeit oder
Cache nicht ohne Befund als Ursache behaupten. Google-Nutzungsbedingungen
bestätigt der Nutzer selbst.

Beim bisherigen Umstieg gab es zwei getrennte Ursachen: eine alte Debug-App
mit Store-Paketkennung und ein anderes aktives Play-Store-Konto als im Browser.
Beides wurde behoben; eine bereits funktionierende Play-/Dev-Aufteilung nicht
erneut umbauen.
