# Backup-Dialog beim Abbrechen stabilisieren

- Den Passwortdialog in ein eigenes zustandsbehaftetes Widget ausgelagert.
- Eingabecontroller werden erst beim vollständigen Entfernen des Dialogs entsorgt und nicht mehr während der Schließanimation.
- Einen Regressionstest für „Backup erstellen → Abbrechen“ ohne Flutter-Assertion ergänzt.
