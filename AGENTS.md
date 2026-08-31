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

Vor jedem Commit ausführen:

```bash
dart run build_runner build
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Auf verbundenen Android-Geräten niemals `flutter install` verwenden. APKs nur
datenbewahrend mit `adb install -r -t -g --no-streaming` aktualisieren.
