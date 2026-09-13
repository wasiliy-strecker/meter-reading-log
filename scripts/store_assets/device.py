"""Small, emulator-only capture helper. Never accepts a physical-device serial."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET


def validate_serial(serial):
    if not re.fullmatch(r"emulator-\d+", serial):
        raise ValueError("Only an explicitly selected emulator is permitted")
    return serial


class Device:
    def __init__(self, serial):
        self.serial = validate_serial(serial)
        self.adb = os.environ.get("ZSL_ADB", "/home/unknown/Android/Sdk/platform-tools/adb")
        if self.run("shell", "getprop", "ro.kernel.qemu").strip() != b"1":
            raise ValueError("Target is not an Android emulator")
        name = self.run("emu", "avd", "name").decode().splitlines()[0]
        if not name.startswith("zsl_store_assets"):
            raise ValueError("Target must be a dedicated zsl_store_assets AVD")

    def run(self, *args):
        return subprocess.check_output([self.adb, "-s", self.serial, *args])

    def nodes(self):
        self.run("shell", "uiautomator", "dump", "/sdcard/zsl-store-ui.xml")
        return ET.fromstring(self.run("shell", "cat", "/sdcard/zsl-store-ui.xml")).iter("node")

    def tap(self, label):
        matches = [n for n in self.nodes() if any(
            value == label or value.startswith(label + "\n")
            for value in (n.get("text", ""), n.get("content-desc", "")))]
        if not matches:
            raise ValueError(f"Visible UI element not found: {label}")
        a, b, c, d = map(int, re.findall(r"\d+", matches[0].get("bounds")))
        self.run("shell", "input", "tap", str((a+c)//2), str((b+d)//2))
        time.sleep(0.6)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("serial")
    parser.add_argument("action", choices=["dump", "tap", "capture", "status"])
    parser.add_argument("value", nargs="?")
    args = parser.parse_args()
    device = Device(args.serial)
    if args.action == "status":
        device.run("shell", "settings", "put", "global", "sysui_demo_allowed", "1")
        for extras in [
            ["command", "exit"], ["command", "enter"],
            ["command", "clock", "hhmm", "0941"],
            ["command", "network", "wifi", "show", "level", "4", "fully", "true", "mobile", "hide", "nosim", "hide"],
            ["command", "battery", "level", "100", "plugged", "false"],
            ["command", "notifications", "visible", "false"],
        ]:
            pairs = [part for i in range(0, len(extras), 2)
                     for part in ("-e", extras[i], extras[i+1])]
            device.run("shell", "am", "broadcast", "-a", "com.android.systemui.demo", *pairs)
    elif args.action == "dump":
        for node in device.nodes():
            text = node.get("text") or node.get("content-desc")
            if text:
                print(node.get("bounds"), repr(text))
    elif args.action == "tap":
        device.tap(args.value)
    else:
        path = Path(args.value)
        path.parent.mkdir(parents=True, exist_ok=True)
        time.sleep(1.5)  # Let the actual Android/Flutter frame settle after navigation.
        path.write_bytes(device.run("exec-out", "screencap", "-p"))
        subprocess.run(["convert", str(path), f"PNG24:{path}"], check=True)


if __name__ == "__main__":
    main()
