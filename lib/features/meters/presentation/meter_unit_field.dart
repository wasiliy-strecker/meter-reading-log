import 'package:flutter/material.dart';

import '../domain/meter.dart';

const _moreUnitValue = '\u0000more-unit';

class MeterUnitField extends StatefulWidget {
  const MeterUnitField({
    super.key,
    required this.meterType,
    required this.value,
    required this.labelText,
    required this.onChanged,
    this.enabled = true,
  });

  final MeterType meterType;
  final String value;
  final String labelText;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<MeterUnitField> createState() => _MeterUnitFieldState();
}

class _MeterUnitFieldState extends State<MeterUnitField> {
  var _fieldVersion = 0;

  @override
  Widget build(BuildContext context) {
    final suggested = [...widget.meterType.availableUnits];
    if (!suggested.contains(widget.value)) suggested.add(widget.value);

    return DropdownButtonFormField<String>(
      key: ValueKey('${widget.meterType.name}-${widget.value}-$_fieldVersion'),
      initialValue: widget.value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: meterUnitDescription(widget.value),
        prefixIcon: const Icon(Icons.straighten_outlined),
      ),
      items: [
        for (final unit in suggested)
          DropdownMenuItem(value: unit, child: Text(unit)),
        const DropdownMenuItem(
          value: _moreUnitValue,
          child: Row(
            children: [
              Icon(Icons.more_horiz),
              SizedBox(width: 10),
              Text('Weitere Einheit …'),
            ],
          ),
        ),
      ],
      onChanged: !widget.enabled
          ? null
          : (value) async {
              if (value == null) return;
              if (value != _moreUnitValue) {
                widget.onChanged(value);
                return;
              }
              final selected = await showMeterUnitPicker(
                context,
                currentValue: widget.value,
              );
              if (!mounted) return;
              if (selected != null) widget.onChanged(selected);
              setState(() => _fieldVersion++);
            },
    );
  }
}

Future<String?> showMeterUnitPicker(
  BuildContext context, {
  required String currentValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.86,
      child: _MeterUnitPickerSheet(currentValue: currentValue),
    ),
  );
}

class _MeterUnitPickerSheet extends StatefulWidget {
  const _MeterUnitPickerSheet({required this.currentValue});

  final String currentValue;

  @override
  State<_MeterUnitPickerSheet> createState() => _MeterUnitPickerSheetState();
}

class _MeterUnitPickerSheetState extends State<_MeterUnitPickerSheet> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final options = meterUnitCatalog.where((option) {
      if (normalizedQuery.isEmpty) return true;
      return option.value.toLowerCase().contains(normalizedQuery) ||
          option.description.toLowerCase().contains(normalizedQuery) ||
          option.category.label.toLowerCase().contains(normalizedQuery);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Weitere Einheit auswählen',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Einheiten durchsuchen',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Suche löschen',
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: options.isEmpty
                ? const Center(child: Text('Keine passende Einheit gefunden.'))
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(option.value),
                        subtitle: Text(
                          '${option.category.label} · ${option.description}',
                        ),
                        trailing: option.value == widget.currentValue
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => Navigator.pop(context, option.value),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _chooseCustomUnit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Eigene Einheit eingeben'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseCustomUnit() async {
    FocusScope.of(context).unfocus();
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => const _CustomUnitDialog(),
    );
    if (selected != null && mounted) Navigator.pop(context, selected);
  }
}

class _CustomUnitDialog extends StatefulWidget {
  const _CustomUnitDialog();

  @override
  State<_CustomUnitDialog> createState() => _CustomUnitDialogState();
}

class _CustomUnitDialogState extends State<_CustomUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eigene Einheit'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            labelText: 'Einheit *',
            hintText: 'z. B. Zyklen',
          ),
          textInputAction: TextInputAction.done,
          validator: (value) {
            final unit = value?.trim() ?? '';
            if (unit.isEmpty) return 'Bitte eine Einheit eingeben.';
            if (unit.length > 20) return 'Maximal 20 Zeichen erlaubt.';
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: _submit,
                child: const Text('Übernehmen', textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }
}
