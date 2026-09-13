import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest


def module(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(name + ".py"))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


device = module("device")
package = module("package")


class StoreToolsTest(unittest.TestCase):
    def test_physical_device_and_implicit_target_rejected(self):
        for value in ["A5CS024205005243", "", "emulator-5580;echo", "localhost:5555"]:
            with self.assertRaises(ValueError):
                device.validate_serial(value)
        self.assertEqual(device.validate_serial("emulator-5580"), "emulator-5580")

    def test_metadata_and_alpha_rejection(self):
        with tempfile.TemporaryDirectory(prefix="zsl-png-test-") as folder:
            path = Path(folder) / "header.png"
            for color in (2, 6):
                path.write_bytes(b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 13) + b"IHDR"
                                 + struct.pack(">IIBB", 1080, 1920, 8, color))
                if color == 2:
                    self.assertEqual(package.png_info(path)[:2], (1080, 1920))
                else:
                    with self.assertRaises(ValueError):
                        package.png_info(path)

    def test_missing_assets_rejected(self):
        with tempfile.TemporaryDirectory(prefix="zsl-package-test-") as folder:
            with self.assertRaises(ValueError):
                package.validate(Path(folder))

    def test_alt_text_limits(self):
        self.assertTrue(all(0 < len(text) <= 140 for text in package.PHONE_ALT + package.TABLET_ALT))


if __name__ == "__main__":
    unittest.main()
