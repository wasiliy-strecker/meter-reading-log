# Beispiel-Aktion nochmals etwas kleiner

- Schrift von „Beispiele ansehen“ von 15 auf 14 px und Symbol von 22 auf
  20 px reduziert. Zentrierung, gleiche Abstände, Schriftgewicht und mindestens
  48 px hohe Touchfläche unverändert.
- Typografie-Test auf die kompaktere Darstellung angepasst.

## Verifikation

- `dart format lib test`, `flutter analyze --no-pub` und die fokussierten
  Galerie-/Aufnahmebildschirm-Tests erfolgreich (15 Tests); `git diff --check`
  ohne Befund.
- Bestehende Dev-Verbindung per Hot Reload aktualisiert: eine Bibliothek in
  1.113 ms. Die auf dem Smartphone geöffnete Fotoauswahl nicht unterbrochen.
- Kein APK-Build, keine Installation, keine Codegenerierung und kein Test-Release.
  Änderung ist in der laufenden Dev-Sitzung verfügbar, nicht neu im APK installiert.
