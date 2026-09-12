import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Keep visibility aligned with the dev-only assets in pubspec.yaml. Debug
// mode alone is not sufficient: other flavors must not expose this preview.
final meterPhotoExamplesEnabledProvider = Provider<bool>(
  (ref) => appFlavor == 'dev',
);

const meterPhotoExamples = [
  (
    label: 'Strom · digital',
    asset: 'assets/dev/meter_photo_examples/01_strom_digital_001842-7_kwh.jpg',
  ),
  (
    label: 'Gas · mechanisch',
    asset: 'assets/dev/meter_photo_examples/02_gas_mechanisch_004731-82_m3.jpg',
  ),
  (
    label: 'Wasser',
    asset: 'assets/dev/meter_photo_examples/03_wasser_000286-4_m3.jpg',
  ),
  (
    label: 'Strom · analog',
    asset: 'assets/dev/meter_photo_examples/04_strom_alt_012958-6_kwh.jpg',
  ),
];

class MeterPhotoExamplesButton extends ConsumerStatefulWidget {
  const MeterPhotoExamplesButton({super.key, this.enabled = true});

  final bool enabled;

  @override
  ConsumerState<MeterPhotoExamplesButton> createState() =>
      _MeterPhotoExamplesButtonState();
}

class _MeterPhotoExamplesButtonState
    extends ConsumerState<MeterPhotoExamplesButton> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(meterPhotoExamplesEnabledProvider)) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: widget.enabled && !_opening ? _showExamples : null,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        icon: const Icon(Icons.collections_outlined, size: 22),
        label: const Text('Beispiele ansehen', textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _showExamples() async {
    setState(() => _opening = true);
    FocusScope.of(context).unfocus();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const FractionallySizedBox(
          heightFactor: 0.9,
          child: _MeterPhotoExamplesGallery(),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
}

class _MeterPhotoExamplesGallery extends StatefulWidget {
  const _MeterPhotoExamplesGallery();

  @override
  State<_MeterPhotoExamplesGallery> createState() =>
      _MeterPhotoExamplesGalleryState();
}

class _MeterPhotoExamplesGalleryState
    extends State<_MeterPhotoExamplesGallery> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Beispielfotos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Schließen',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Zählerstand und Einheit gut lesbar fotografieren. '
                'Spiegelungen vermeiden.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: constraints.maxHeight * 0.58,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: meterPhotoExamples.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final example = meterPhotoExamples[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ColoredBox(
                          color: theme.colorScheme.surfaceContainerLow,
                          child: Image.asset(
                            example.asset,
                            fit: BoxFit.contain,
                            cacheWidth: 768,
                            semanticLabel: 'Beispielfoto: ${example.label}',
                            errorBuilder: (_, _, _) => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Beispiel konnte nicht geladen werden.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                meterPhotoExamples[_index].label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                    tooltip: 'Vorheriges Beispiel',
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Flexible(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        '${_index + 1} von ${meterPhotoExamples.length}',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _index < meterPhotoExamples.length - 1
                        ? () => _goTo(_index + 1)
                        : null,
                    tooltip: 'Nächstes Beispiel',
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Text(
                'KI-generierte Beispiele · nur zur Ansicht',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
