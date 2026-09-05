# PDF-Exporte mit Fotos beschleunigt

- Vor Einzel- und Verlaufsnachweisen kann zwischen einer kompakten PDF ohne
  Fotos und einer PDF mit den jeweils aktuellen Nachweisfotos gewählt werden.
- PDF-Fotos werden lokal auf maximal 1600 Pixel und JPEG-Qualität 82
  vorbereitet, per Prüfsumme wiederverwendet und bei neuen Fotos im Hintergrund
  vorgewärmt. Originalfotos und ihre Prüfsummen bleiben unverändert.
- Frühere Korrekturfotos werden in neuen Foto-PDFs nicht mehr eingebettet;
  der Korrekturverlauf weist weiterhin auf Fotoänderungen hin.
- Exportvariante, Dateiname, Duplikaterkennung, Datenbank und verschlüsselte
  Backups berücksichtigen den gewählten Fotomodus.
- Analyse, vollständige Flutter-Tests und Android-Debug-Build wurden
  erfolgreich ausgeführt; das APK wurde datenbewahrend auf dem Testgerät
  installiert.
