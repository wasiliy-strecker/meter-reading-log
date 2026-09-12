# Synthetic meter photo fixtures

These images are synthetic, AI-generated fixtures for manual camera and OCR
testing. They contain no real customer, device, location, or billing data.

| File | Meter type | Visible reading |
| --- | --- | --- |
| `01_strom_digital_001842-7_kwh.png` | digital electricity | `001842.7 kWh` |
| `02_gas_mechanisch_004731-82_m3.png` | mechanical gas | `004731,82 m³` |
| `03_wasser_000286-4_m3.png` | cold water | `000286,4 m³` |
| `04_strom_alt_012958-6_kwh.png` | Ferraris electricity | `012958,6 kWh` |

Display one image at full size or print it, photograph it through the app, and
compare the OCR candidate with the visible reading. The app deliberately
requires manual confirmation because punctuation and roller transitions can be
misread by OCR.

## In-app development preview

The `dev` flavor bundles reduced JPEG previews of these four PNGs for the
optional **Beispiele ansehen** gallery before camera/gallery
selection, photo replacement, and correction. This is a read-only illustration:
viewing a sample does not import it, trigger OCR, or create a reading.

The entry point requires `appFlavor == 'dev'`, and the individual asset entries
in `pubspec.yaml` are restricted to that flavor. Store and unflavored builds
do not bundle the example photos. The original PNGs are never bundled; they
remain unchanged for manual OCR testing independently of this preview.

Regenerate the committed previews with
`dart run scripts/prepare_meter_photo_examples.dart` from the app directory.
Output: `assets/dev/meter_photo_examples/`, JPEG, at most 1024 pixels on the
longest edge and 150 KiB per image. This does not change processing of users'
actual evidence photos.

## Generation prompt set

All four prompts requested a portrait, straight-on, photorealistic and
unbranded household meter on a neutral utility background. Each prompt required
one large, high-contrast reading, diffuse light without glare, no serial number,
QR code, barcode, other digits, hands, logo, or watermark. The variants were a
modern digital electricity meter, a lightly aged mechanical gas meter, a
blue-rimmed cold-water meter, and an older Ferraris electricity meter.
