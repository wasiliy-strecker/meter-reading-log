# Zehner-Seiten absichern und kollidierende Dev-Verbindungen erkennen

- Die Ablesevorschau, die Verlaufssuche und gespeicherte Verlaufs-PDFs verwenden
  bereits jeweils zehn Einträge. Zusätzliche Regressionstests prüfen sechs
  Ablesungen inklusive „6 von 6 Ablesungen“ sowie 6, 10, 11 und 12 PDFs:
  keine Pagination bis zehn, danach zehn plus die restlichen Einträge.
- Auf dem Gerät war nach verlorener Verbindung wieder die ältere Dev-APK aktiv.
  Dev neu verbunden und per Hot Restart aktualisiert, ohne APK-/AAB-Build,
  Installation, Änderung der Versionsnummer oder Löschen gespeicherter Daten.
- Bei der anschließenden Diagnose zusätzlich nachgewiesen: Flutter-Attach aus
  ZählerstandLog und aus AI Age Estimator waren gleichzeitig mit derselben
  lokalen Dart-VM-Service-Adresse verbunden. Im privaten Dev-Code-Cache von
  ZählerstandLog lag auch ein inkrementelles AI-Age-Estimator-Kernel-Artefakt.
  Weitere Reloads wegen dieses Konflikts zunächst gestoppt und die Gerätenutzung
  mit dem Nutzer koordiniert.
- Nach bestätigter Pause des anderen Agenten nur ZählerstandLog frisch verbunden.
  Vor dem Hot Restart die VM-PID mit der Android-Paket-PID abgeglichen und
  `package:meter_reading_log/main.dart` als Root-Bibliothek geprüft. Anschließend
  direkt über die VM die geladenen Quellen aller drei Ansichten kontrolliert:
  Vorschaugröße und beide Seitengrößen sind `10`, die Pagination-Bedingungen
  verwenden jeweils `> 10`. Die PDF-Seiten-Bibliothek ist ebenfalls geladen.
  Keine zweite Flutter-Attach-Verbindung vorhanden. Die Geräteaktualisierung ist
  damit abgeschlossen; die Live-Sitzung bleibt offen. Wie bei jedem Hot Restart
  bleibt die dauerhaft installierte APK unverändert.
- App-lokale Agentenregeln um PID-/Root-Bibliotheksprüfung und den Umgang mit
  kollidierenden Projektverbindungen ergänzt. Fremde Prozesse nicht beendet;
  keine manuelle Navigation auf dem Smartphone durchgeführt.
- Prüfung: `dart format lib test`, `flutter analyze --no-pub`, die vier
  fokussierten Testdateien für Verlauf, Erfassung, PDF-Liste und PDF-Seiten
  sowie `git diff --check`: keine Analysefehler, alle 26 Tests erfolgreich.
