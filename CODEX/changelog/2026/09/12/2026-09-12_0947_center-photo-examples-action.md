# Zentrierte, dezente Beispiel-Aktion und schnelle Dev-Vorschau

- „Beispiele ansehen“ mittig ausgerichtet. Nach Smartphone-Feedback die erste
  größere Vorschau auf 15 px / Medium und ein 22-px-Symbol zurückgenommen.
  Die gut erreichbare Touchfläche bleibt mindestens 48 px hoch.
- Im Aufnahmebildschirm gleiche sichtbare Abstände oberhalb und unterhalb der
  Aktion hergestellt; den vorhandenen Kartenrand berücksichtigt. Store blendet
  Aktion und zusätzlichen oberen Abstand weiterhin aus.
- Dev als Flutter-Standardvariante gesetzt, damit `flutter attach` die
  Dev-Konstanten und ausschließlich dafür freigegebenen Bilder korrekt erhält.
  Store-Releases wählen unverändert ausdrücklich `--flavor store`.
- Hot-Reload-Ablauf mit sicherem Neuverbinden einer vorhandenen Dev-Installation
  in `AGENTS.md` dokumentiert. UI-Vorschauen von APK-Abschlussprüfungen getrennt;
  keine Neuinstallation für jede Schrift- oder Abstandsänderung.

## Verifikation

- Widget-Tests für Zentrierung, Schrift-/Symbolgröße, Mindest-Touchfläche und
  gleiche sichtbare Abstände (je 18 px) ergänzt.
- `dart run build_runner build`, `dart format lib test`,
  `flutter analyze --no-pub`, `flutter test --no-pub --reporter expanded` und
  `flutter build apk --debug --flavor dev --no-pub` erfolgreich;
  alle 138 Tests bestanden.
- Galerie-/Asset-Tests nach der Default-Flavor-Änderung zusätzlich ausdrücklich
  mit `--flavor store` erfolgreich (8 Tests): Beispiele bleiben ausgeschlossen.
- Erste Layout-Vorschau datenbewahrend in Dev installiert; Paketkennung,
  Version, Debug-Flag und Signatur zuvor geprüft. Anschließend Dev ohne weitere
  Installation neu gestartet und per `flutter attach` verbunden.
- Finale kleinere Darstellung per Hot Reload auf das Smartphone übertragen
  (1 Bibliothek, 874 ms), visuell geprüft und Galerie erfolgreich geöffnet.
  Live-Verbindung für weitere UI-Iterationen offen gelassen. Die Hot-Reload-
  Vorschau ändert nicht das dauerhaft installierte APK; das abschließend neu
  geprüfte Dev-APK wurde nicht nochmals installiert.
- Datenbank-Prüfsumme unverändert; Play-Version, Installer und Updatezeit
  unverändert. Kein Store-AAB, Test-Release, Upload oder Versionssprung;
  App-Version bleibt `1.0.0+2`.
