import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meter_reading_log/app/app_theme.dart';
import 'package:meter_reading_log/features/meters/presentation/meter_photo_examples.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('previews are small JPEGs rather than full-size original fixtures', () {
    for (final example in meterPhotoExamples) {
      expect(example.asset, startsWith('assets/dev/meter_photo_examples/'));
      expect(example.asset, endsWith('.jpg'));
      final bytes = File(example.asset).readAsBytesSync();
      expect(bytes.length, lessThanOrEqualTo(150 * 1024));
      final decoded = img.decodeJpg(bytes)!;
      expect(decoded.width, lessThanOrEqualTo(1024));
      expect(decoded.height, lessThanOrEqualTo(1024));
    }
  });

  test(
    'visibility and bundled images are restricted to the dev flavor',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final isDev = appFlavor == 'dev';
      expect(container.read(meterPhotoExamplesEnabledProvider), isDev);
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final bundledExamples = manifest.listAssets().where(
        (asset) => asset.contains('meter_photo_examples/'),
      );
      expect(
        manifest.listAssets().where((asset) => asset.contains('meter_photos/')),
        isEmpty,
      );
      expect(
        bundledExamples,
        unorderedEquals(isDev ? meterPhotoExamples.map((e) => e.asset) : []),
      );
      for (final example in meterPhotoExamples) {
        if (isDev) {
          expect(
            (await rootBundle.load(example.asset)).lengthInBytes,
            greaterThan(0),
          );
        }
      }
    },
  );

  Future<_ExampleAssetBundle> pumpButton(
    WidgetTester tester, {
    bool visible = true,
    bool enabled = true,
    double textScale = 1,
    bool dark = false,
    bool failImages = false,
  }) async {
    final bundle = _ExampleAssetBundle(failImages: failImages);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meterPhotoExamplesEnabledProvider.overrideWithValue(visible),
        ],
        child: DefaultAssetBundle(
          bundle: bundle,
          child: MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: Scaffold(body: MeterPhotoExamplesButton(enabled: enabled)),
          ),
        ),
      ),
    );
    return bundle;
  }

  testWidgets('hidden in non-dev UI without loading example images', (
    tester,
  ) async {
    final bundle = await pumpButton(tester, visible: false);

    expect(find.text('Beispiele ansehen'), findsNothing);
    expect(bundle.loadedImages, isEmpty);
  });

  testWidgets('busy photo processing disables the link', (tester) async {
    final bundle = await pumpButton(tester, enabled: false);
    await tester.tap(find.text('Beispiele ansehen'));
    await tester.pumpAndSettle();

    expect(find.text('Beispielfotos'), findsNothing);
    expect(bundle.loadedImages, isEmpty);
  });

  testWidgets('example action is centered with a compact label and icon', (
    tester,
  ) async {
    await pumpButton(tester);
    final button = find.widgetWithText(TextButton, 'Beispiele ansehen');
    expect(
      tester.getCenter(button).dx,
      closeTo(tester.getCenter(find.byType(Scaffold)).dx, 0.01),
    );
    final style = tester.widget<TextButton>(button).style!;
    expect(style.textStyle!.resolve({})!.fontSize, 14);
    expect(style.textStyle!.resolve({})!.fontWeight, FontWeight.w500);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.collections_outlined)).size,
      20,
    );
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  });

  testWidgets('opens only on demand, supports swiping and arrows, and closes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final bundle = await pumpButton(tester);
    expect(bundle.loadedImages, isEmpty);
    expect(find.text('Beispielfotos'), findsNothing);

    await tester.tap(find.text('Beispiele ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Beispielfotos'), findsOneWidget);
    expect(find.text('Strom · digital'), findsOneWidget);
    expect(find.text('1 von 4'), findsOneWidget);
    expect(bundle.loadedImages, contains(meterPhotoExamples.first.asset));
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton &&
                  widget.tooltip == 'Vorheriges Beispiel',
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('Gas · mechanisch'), findsOneWidget);
    expect(find.text('2 von 4'), findsOneWidget);
    await tester.tap(find.byTooltip('Nächstes Beispiel'));
    await tester.pumpAndSettle();
    expect(find.text('Wasser'), findsOneWidget);
    await tester.tap(find.byTooltip('Nächstes Beispiel'));
    await tester.pumpAndSettle();
    expect(find.text('Strom · analog'), findsOneWidget);
    expect(find.text('4 von 4'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Nächstes Beispiel',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Vorheriges Beispiel'));
    await tester.pumpAndSettle();
    expect(find.text('3 von 4'), findsOneWidget);

    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(find.text('Beispielfotos'), findsNothing);
    await tester.tap(find.text('Beispiele ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('1 von 4'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Beispielfotos'), findsNothing);
    expect(find.text('Beispiele ansehen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stays scrollable with large text in a small landscape viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpButton(tester, textScale: 2, dark: true);

      await tester.tap(find.text('Beispiele ansehen'));
      await tester.pumpAndSettle();
      expect(find.text('Beispielfotos'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Nächstes Beispiel'));
      await tester.tap(find.byTooltip('Nächstes Beispiel'));
      await tester.pumpAndSettle();
      expect(find.text('2 von 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('a missing example does not block closing or the photo flow', (
    tester,
  ) async {
    await pumpButton(tester, failImages: true);
    await tester.tap(find.text('Beispiele ansehen'));
    await tester.pumpAndSettle();

    expect(find.text('Beispiel konnte nicht geladen werden.'), findsOneWidget);
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(find.text('Beispiele ansehen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ExampleAssetBundle extends CachingAssetBundle {
  _ExampleAssetBundle({this.failImages = false});

  final bool failImages;
  final loadedImages = <String>[];

  @override
  Future<ByteData> load(String key) async {
    if (!key.contains('meter_photo_examples/')) return rootBundle.load(key);
    loadedImages.add(key);
    if (failImages) throw FlutterError('Synthetic missing image');
    // Tiny, synthetic image keeps layout tests independent of the selected
    // flavor. Actual asset inclusion/exclusion is verified above in each flavor.
    return ByteData.sublistView(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
  }
}
