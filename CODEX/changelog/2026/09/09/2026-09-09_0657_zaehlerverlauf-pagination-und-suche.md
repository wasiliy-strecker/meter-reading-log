# Zählerverlauf paginiert und durchsuchbar

- Lädt lange Zählerverläufe datenbankseitig in 20er-Schritten und bietet „Weitere 20 anzeigen“ statt einer vollständig geladenen Liste.
- Blendet ab 20 Ablesungen eine Suche nach lokalem Datum, Zählerstand und Notiz ein und zeigt die Anzahl der sichtbaren Ablesungen beziehungsweise Treffer.
- Rendert Verlaufskarten lazy, zeigt Notiz-Ausschnitte und lässt Differenzen während einer gefilterten Suche weg, damit keine nicht benachbarten Werte verglichen werden.
- Verwendet im Kopf weiterhin die neueste ungefilterte Ablesung und lädt für Verlaufs-PDFs unabhängig von Suche und Seitengröße immer den vollständigen Verlauf.
- Ergänzt Datenbank-, Last- und Widgettests für 20er-Limits, Suche außerhalb der ersten Seite und vollständige PDF-Daten.
