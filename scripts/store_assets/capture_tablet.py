"""Capture the seeded Store app in real tablet geometry, starting at Dashboard."""
import argparse
from pathlib import Path
import re
import subprocess
import time

from device import Device


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("serial")
    parser.add_argument("size", choices=["7", "10"])
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    d = Device(args.serial)
    if not any(n.get("content-desc") == "Dashboard" or n.get("text") == "Dashboard" for n in d.nodes()):
        raise ValueError("Start on Dashboard with the synthetic backup restored")
    width, height = (1920, 1080) if args.size == "7" else (2560, 1440)
    d.run("shell", "wm", "size", f"{width}x{height}")
    d.run("shell", "wm", "density", "288")
    d.run("shell", "cmd", "uimode", "night", "no")
    time.sleep(2)
    subprocess.run(["python3", str(Path(__file__).with_name("device.py")), args.serial, "status"], check=True)
    folder = args.output / f"tablet{args.size}"
    folder.mkdir(parents=True, exist_ok=True)

    def capture(name):
        time.sleep(1.5)
        path = folder / name
        path.write_bytes(d.run("exec-out", "screencap", "-p"))
        subprocess.run(["convert", str(path), f"PNG24:{path}"], check=True)
        print(path, flush=True)

    capture("01-dashboard.png")
    d.tap("Einstellungen")
    capture("04-backup.png")
    d.tap("Zurück")
    d.tap("Strom Wohnung")
    for attempt in range(12):
        if any(n.get("content-desc") == "Alle Ablesungen anzeigen" for n in d.nodes()):
            break
        d.run("shell", "input", "swipe", str(width//2), str(int(height*.84)),
              str(width//2), str(int(height*.2)), "60")
    d.tap("Alle Ablesungen anzeigen")
    capture("02-history.png")
    d.tap("Abgelesen am 01.09.2026, 10:00 Uhr")
    for attempt in range(8):
        match = next((n for n in d.nodes() if n.get("content-desc") == "1842.7 kWh"), None)
        if match is not None:
            _, y, _, _ = map(int, re.findall(r"\d+", match.get("bounds")))
            distance = y - int(height*.2)
            if distance < 30:
                break
        else:
            distance = int(height*.6)
        start = int(height*.86)
        d.run("shell", "input", "swipe", str(width//2), str(start),
              str(width//2), str(max(int(height*.2), start-distance)), "450")
    capture("03-reading.png")
    d.tap("Zurück")
    d.tap("Zurück")
    d.tap("Zurück")


if __name__ == "__main__":
    main()
