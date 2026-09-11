# Dev- und Play-Installationen trennen

- Android-Flavors `dev` und `store` ergänzt: lokale Debug-App als
  `com.appfactory.meter_reading_log.dev` / `ZählerstandLog Dev`, Store-App mit
  bisheriger Paketkennung und bisherigem Namen.
- Store-Debug/Profile über den Android-Variantenfilter deaktiviert. Release
  behält Upload-Signierung, R8-Regeln und das Offline-Manifest.
- Entwicklungs-, Installations- und Release-Befehle in README und AGENTS
  angepasst; generierten Kotlin-Cache vom Commit ausgeschlossen.

## Verifikation

- `dart run build_runner build`, `dart format lib test`, `flutter analyze`
  und `flutter test` erfolgreich; alle 115 Tests bestanden.
- `flutter build apk --debug --flavor dev` und
  `flutter build appbundle --release --flavor store` erfolgreich.
- Gradle-Taskliste mit vollständigem Android-Studio-JDK geprüft: StoreRelease
  vorhanden, StoreDebug und StoreProfile fehlen. Die System-JRE allein besitzt
  keinen Java-Compiler und ist für direkte Gradle-Aufrufe ungeeignet.
- Dev-APK: eigene Paketkennung, Anzeigename, Debug-Signatur und getrennte
  FileProvider-Authorities. Store-AAB: Version 1.0.0 (1), Target SDK 36,
  Upload-Zertifikat bestätigt, kein Debug-Flag und keine Netzwerkrechte.
- Dev-App per `adb install -r -t -g --no-streaming` zusätzlich installiert,
  gestartet und vorhandene Debug-Menüs auf dem angeschlossenen Gerät geprüft.
- Frisches verschlüsseltes Backup außerhalb der App gespeichert, zusätzlich
  lokal gesichert und über die normale Wiederherstellung in Dev importiert.
  Datenbankvergleich bestätigt 2 Zähler, 3 Ablesungen, 3 Korrekturen und 5 PDFs;
  SHA-256 aller 10 referenzierten Foto-/PDF-Dateien in beiden Apps geprüft.
- Android-Alarmfreigabe in Dev für die übernommene pünktliche Erinnerung
  eingerichtet. App-Daten, Backup und Passwort bleiben außerhalb des Repositories.

## Verbleibender einmaliger Gerätewechsel

Die bisherige Debug-App mit Store-Paketkennung wurde nicht deinstalliert.
Nach ausdrücklicher Freigabe kann diese alte Installation entfernt und durch
den bereits veröffentlichten Play-Testrelease ersetzt werden. Die neue Dev-App
und das externe Backup bleiben dabei erhalten; ein neuer Play-Upload ist für
die Flavor-Trennung nicht erforderlich.
