# Dev-Builds nur bei konkretem Bedarf

- Allgemeine Root-Regeln und ZählerstandLog-`AGENTS.md` aufeinander abgestimmt:
  Hot Reload für gewöhnliche Dart/UI-Änderungen, Hot Restart für Initialisierung
  und nicht reloadbare Dart-Änderungen, APK-Build nur mit konkretem Anlass.
- Pauschale Codegenerierungs- und APK-Buildpflicht vor jedem Commit entfernt.
  Auch ein Hintergrund-Prüfbuild ist kein Ersatz für die fehlende Notwendigkeit
  eines Builds bei einer reinen Schrift- oder Abstandsänderung.
- Native Änderungen, fehlende passende Dev-Installation und ausdrücklich
  gewünschte dauerhafte APK-Updates als Build-Gründe festgehalten. Assets und
  reine Dart-Abhängigkeiten separat beurteilen; fehlende Live-Verbindung allein
  rechtfertigt keinen Neubau. Den Build-Grund vorab kurz mitteilen.
- Formatierung, Analyse und fokussierte Tests für Codeänderungen beibehalten;
  vollständige Suite bei übergreifenden Änderungen und Releases. Codegenerierung
  nur bei betroffenen Eingaben oder Konfiguration. Dokumentationsänderungen
  benötigen ausschließlich Inhalts-/Konsistenz- und Diff-Prüfung.
- Dev-/Store-Trennung, Signaturkontrollen und datenbewahrende Installation
  unverändert. Hot Reload/Restart nicht als dauerhaftes APK-Update ausgeben.

## Verifikation

- Beide Anweisungsdateien auf widersprüchliche Build-/Commit-Regeln geprüft.
  Szenarien: UI-Änderung, Initialisierung, native Änderung, reine Dart-Abhängigkeit,
  getrennte Live-Verbindung, dauerhafter APK-Wunsch und reine Dokumentation.
- Diff-/Whitespace-Prüfung; ausschließlich Dokumentation geändert.
- Kein Flutter-Build, keine Codegenerierung, kein App-Neustart, keine Installation
  und kein Test-Release für diese Aufgabe.
- Die übergeordnete Root-`AGENTS.md` liegt außerhalb eines Git-Repositories und
  wurde lokal aktualisiert. App-Anweisungen und dieser Changelog sind im
  ZählerstandLog-Repository versioniert.
