"""Validate and package already-rendered Play Store images; does not edit pixels."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import zipfile

PHONE_ALT = [
    "Dashboard mit drei Beispielzählern für Strom, Gas und Wasser und ihren letzten Ablesungen",
    "Zählerfoto mit lokal erkanntem Stromzählerstand und Feld zur Bestätigung des Werts",
    "Zählerverlauf mit Suchfeld, neuesten Ablesungen zuerst und zehn Einträgen pro Seite",
    "Gespeicherte Ablesung mit passendem synthetischem Nachweisbild und Ablesezeitpunkt",
    "Echte PDF-Vorschau des Zählerverlaufs mit absteigender Tabelle sowie Drucken und Teilen",
    "Einstellungen zum Erstellen und Wiederherstellen verschlüsselter Backups",
]
TABLET_ALT = [
    "Tablet-Dashboard mit Beispielzählern und Suchfeld",
    "Zählerverlauf auf dem Tablet mit Suchfeld und Seitennavigation",
    "Ablesedetails auf dem Tablet mit Ablesezeitpunkt, Quelle, Notiz und Korrekturverlauf",
    "Tablet-Einstellungen mit verschlüsseltem Backup, Wiederherstellung und Datenschutzhinweisen",
]


def png_info(path):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError(f"Not a PNG: {path}")
    width, height, depth, color = struct.unpack(">IIBB", data[16:26])
    if depth != 8 or color != 2:
        raise ValueError(f"Expected opaque 8-bit RGB PNG: {path}")
    return width, height, len(data), hashlib.sha256(data).hexdigest()


def validate(root):
    specs = {
        "icon": (1, (512, 512), 1_000_000),
        "feature": (1, (1024, 500), 15_000_000),
        "phone": (6, (1080, 1920), 8_000_000),
        "tablet7": (4, (1920, 1080), 8_000_000),
        "tablet10": (4, (2560, 1440), 8_000_000),
    }
    entries = []
    for group, (count, size, limit) in specs.items():
        paths = sorted((root / group).glob("*.png"))
        if len(paths) != count:
            raise ValueError(f"{group}: expected {count} images, got {len(paths)}")
        for index, path in enumerate(paths):
            width, height, length, digest = png_info(path)
            if (width, height) != size or length > limit:
                raise ValueError(f"Dimensions/size outside specification: {path}")
            alt = (PHONE_ALT[index] if group == "phone" else
                   TABLET_ALT[index] if group.startswith("tablet") else
                   "ZählerstandLog: Ablesen, Dokumentieren und Teilen" if group == "feature"
                   else "ZählerstandLog App-Icon")
            if len(alt) > 140:
                raise ValueError("Alt text exceeds 140 characters")
            entries.append(dict(file=str(path.relative_to(root)), width=width,
                                height=height, bytes=length, sha256=digest, alt=alt))
    return entries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--aab", type=Path, required=True)
    args = parser.parse_args()
    aab_digest = hashlib.sha256(args.aab.read_bytes()).hexdigest()
    if aab_digest != "bcd7afc4223bd40ae296a9aa03f9797f50795a13484f464665c7a31443467f58":
        raise ValueError("Expected the verified Build 7 AAB; review source/version before changing this pin")
    entries = validate(args.output)
    manifest = dict(source_aab=args.aab.name,
                    aab_sha256=aab_digest,
                    package="com.appfactory.meter_reading_log", version="1.0.0+7",
                    source="Unmodified Store AAB, emulator-only local APK signing",
                    captures="Android API 35; phone 390 dpi; tablets 288 dpi; light theme",
                    demo="3 fictional meters, 24 monthly readings, 1 note revision; no private data",
                    assets=entries)
    (args.output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    readme = """# ZählerstandLog – Play-Store-Bilder, Build 7

Die PNG-Dateien sind fertig für den Upload. Video kannst du leer lassen.
Die App und dein Smartphone wurden nicht verändert. Kein neuer Release gebaut,
nichts hochgeladen oder veröffentlicht.

## In der Play Console zuordnen

| Feld | Ordner / Datei |
| --- | --- |
| App icon | `icon/app-icon.png` |
| Feature graphic | `feature/feature-graphic.png` |
| Phone screenshots | `phone/01.png` bis `06.png`, in dieser Reihenfolge |
| 7-inch tablet screenshots | alle vier PNGs aus `tablet7`, nach Dateinamen sortiert |
| 10-inch tablet screenshots | alle vier PNGs aus `tablet10`, nach Dateinamen sortiert |

`VORSCHAU.png` ist nur die Gesamtübersicht, nicht zum Store-Upload.
`raw/` und HTML-Dateien sind Arbeitsmaterial, nicht zum Upload.
Das ZIP enthält nur fertige Bilder, diese Anleitung und das Prüfmanifest.

## Herkunft und Kontrolle

Echte Screenshots des vorhandenen Store-Builds 1.0.0+7 im isolierten API-35-Emulator.
Die APK wurde aus dem unveränderten AAB erzeugt und ausschließlich für diesen
Emulator lokal signiert. Telefon/Dev/Play-Installationen bleiben unverändert.
Tablet-Bilder sind jeweils separat in Tablet-Größe gerendert, keine gestreckten
Smartphone-Bilder. Die Smartphone-Gestaltung umrahmt die unveränderte Oberfläche.

Sämtliche Zählerdaten sind fiktiv. Historische Bilder sind ausdrücklich als Demo
gekennzeichnet und ihre Ziffern passen zu den gespeicherten Werten. Das Foto für
die Erkennungsansicht stammt aus den vorhandenen synthetischen App-Beispielen.
Die dort sichtbare Erkennung wurde tatsächlich lokal ausgeführt.
Das Backup wurde über die bestehende Wiederherstellung importiert.
Die PDF wurde in der echten App erzeugt; die Vorschau funktionierte bei diesem
Durchlauf. Das ist kein Nachweis, dass frühere sporadische Preview-Probleme
generell behoben wären. Es wurden keine Fehler aus Screenshots retuschiert.

Nebenbefund beim wiederholten Demo-Import: Die bereits geladene Korrekturansicht
zeigte zunächst noch den vorherigen Stand. Nach einem App-Neustart erschien die
importierte Revision korrekt. Dieser UI-Aktualisierungsfehler wurde dokumentiert,
aber im Rahmen der Bilderstellung nicht im App-Code behoben.

Alle 16 Upload-Bilder sind opake RGB-PNGs; Maße und Dateigrößen wurden geprüft.
Die größte zulässige Screenshot-Datei ist 8 MB; das Icon bleibt unter 1 MB.

## Bildbeschreibungen (optional in der Play Console)

"""
    readme += "\n".join(f"{entry['file']}\n{entry['alt']}\n" for entry in entries)
    (args.output / "README.md").write_text(readme)
    archive = args.output / "zaehlerstandlog-build-7-play-store-bilder.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as result:
        for relative in [entry["file"] for entry in entries] + ["README.md", "manifest.json", "VORSCHAU.png"]:
            path = args.output / relative
            if path.exists():
                result.write(path, relative)
    print(f"Validated {len(entries)} upload images; largest: {max(e['bytes'] for e in entries):,} bytes")
    print(archive)


if __name__ == "__main__":
    main()
