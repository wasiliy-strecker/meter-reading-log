# PDF-Nachweise vervollständigen und Hinweise überarbeiten

- Einzel- und Verlaufs-PDFs zeigen bei Foto-Korrekturen auch Fotoquelle und OCR-Kandidat mit Vorher/Nachher. Technische Prüfsummen bleiben intern; die angebotene Foto-Variante bindet weiterhin nur das aktuelle Foto je Ablesung ein.
- Ablesezeiten in Übersicht, Überschriften und Details verwenden den gespeicherten UTC-Zeitpunkt plus ursprünglichen Zeitzonenversatz, unabhängig von der Export-Zeitzone.
- Verlaufs-PDFs kennzeichnen aktuelle Zählerangaben und zeigen abweichende historische Stammdaten bei der jeweiligen Ablesung. Einzel-PDFs behalten den gespeicherten Zähler-Snapshot. Keine Änderung bestehender Ablesungen, Exportdateien oder Manifest-Normalisierung.
- Notizen, Korrekturgründe und Vorher-/Nachher-Texte umbrechen vollständig über mehrere PDF-Seiten, ohne Kürzung oder neue Eingabelimits.
- Aus der Datenschutzkarte ausschließlich die E-Mail-Adresse und den Satz über extern gespeicherte PDFs/Backups entfernt. Name, AppFabrik AI, übrige Texte und verlinkte Datenschutzerklärungen bleiben unverändert.
- Nur beim Anlegen: dezente, abgerundete Infofläche mit Symbol und hervorgehobenem „Ablesen / Fotografieren“ über dem Speichern-Button. Bei stark vergrößerter Schrift bleibt der Hinweis scrollbar und der Button erreichbar. Bearbeiten und Navigation unverändert.

## Prüfung

- `dart format lib test`, `flutter analyze --no-pub`, `git diff --check`: erfolgreich.
- `flutter test --no-pub`: 192 Tests erfolgreich, einschließlich vollständigem Jahresverlauf mit 365 Ablesungen.
- Neue PDF-Tests decken beide Exportarten und alle drei Foto-Modi ab, darunter den Legacy-Modus. Export mit langen Notizen, Gründen und Korrekturwerten (jeweils mindestens 9.600 Zeichen) erfolgreich.
- Zusätzliche Inhaltsprüfung mit `pdftotext`: `TZ=UTC flutter test --no-pub --dart-define=PDF_TEXT_AUDIT=true test/features/evidence/evidence_pdf_content_test.dart`; außerdem unter `TZ=Europe/Berlin` erfolgreich. Vollständige Textmarker/Wortanzahl, Zeitzonen, Stammdaten und Foto-Korrekturen geprüft.
- Widget-Tests: Hinweis in Hell/Dunkel bei 320 Pixeln Breite und Textskalierung 1/2, kein Hinweis beim Bearbeiten, gezielte Kürzung der Datenschutzkarte. Zwei bestehende Navigationstests scrollen nun explizit zur Ableseerinnerung.

## Dev-Übergabe

- Nur `com.appfactory.meter_reading_log.dev` auf dem angeschlossenen HONOR aktualisiert. Die Dev-App wurde im sicheren Dashboard-Zustand mit Debug-Startparametern neu gestartet und anschließend per `flutter attach` verbunden; VM-PID und Root-Bibliothek eindeutig geprüft.
- Hot Reload allein übernahm beim erneuten Verbinden den neuen Code nicht; Hot Restart lud die aktuelle Dart-Version erfolgreich. Hinweis anschließend auf dem Gerät visuell geprüft, ohne Daten anzulegen oder zu ändern.
- Dev-Verbindung für weitere Änderungen offen gelassen. Live-Änderungen sind kein dauerhaftes APK-Update und überstehen einen Kaltstart nicht automatisch.
- Kein APK-/AAB-Build, keine Installation, keine Versionsänderung, keine Änderung der Play-App oder ihrer Daten, kein Push und keine Veröffentlichung.
