# Backup-Dateiauswahl filtern

- Filtert die Android-Dateiauswahl nach dem Binärdateityp bestehender Backups, sodass normale PDFs, Bilder und Dokumente nicht mehr auswählbar sind.
- Prüft ausgewählte Dateien vor der Passwortabfrage auf die Endung `.zslbackup` und weist fremde Backup-Dateien verständlich zurück.
- Behält die direkte Endungsfilterung für iOS, Web und Desktop bei und behandelt einen abgebrochenen Dateidialog weiterhin ohne Fehlermeldung.
- Ergänzt eine testbare Dateiauswahl-Schnittstelle sowie Tests für Plattformfilter, Dateinamen, gültige Auswahl, falsche Auswahl und Abbruch.
