enum MeterType {
  electricity,
  electricityFeedIn,
  gas,
  water,
  coldWater,
  hotWater,
  heat,
  heatingCostAllocator,
  oil,
  other,
}

extension MeterTypeX on MeterType {
  String get wireName => name;

  String get label => switch (this) {
    MeterType.electricity => 'Strom (Bezug)',
    MeterType.electricityFeedIn => 'Strom (Einspeisung / PV)',
    MeterType.gas => 'Gas',
    MeterType.water => 'Wasser (allgemein)',
    MeterType.coldWater => 'Kaltwasser',
    MeterType.hotWater => 'Warmwasser',
    MeterType.heat => 'Wärme / Fernwärme',
    MeterType.heatingCostAllocator => 'Heizkostenverteiler',
    MeterType.oil => 'Heizöl / Tank',
    MeterType.other => 'Sonstiger Zähler',
  };

  List<String> get availableUnits => switch (this) {
    MeterType.electricity => const ['kWh', 'MWh', 'Wh', 'GWh', 'kvarh', 'kVAh'],
    MeterType.electricityFeedIn => const [
      'kWh',
      'MWh',
      'Wh',
      'GWh',
      'kvarh',
      'kVAh',
    ],
    MeterType.gas => const ['m³', 'kWh', 'MWh', 'ft³'],
    MeterType.water ||
    MeterType.coldWater ||
    MeterType.hotWater => const ['m³', 'Liter', 'ml'],
    MeterType.heat => const ['kWh', 'MWh', 'Wh', 'MJ', 'GJ'],
    MeterType.heatingCostAllocator => const ['Einheiten'],
    MeterType.oil => const ['Liter', 'm³', '%', 'kg', 't'],
    MeterType.other => meterUnitCatalogValues,
  };

  String get defaultUnit => availableUnits.first;
}

enum MeterUnitCategory {
  energy('Energie'),
  electrical('Elektrische Spezialwerte'),
  volume('Volumen'),
  massAndLevel('Masse und Füllstand'),
  general('Allgemein');

  const MeterUnitCategory(this.label);

  final String label;
}

class MeterUnitOption {
  const MeterUnitOption({
    required this.value,
    required this.description,
    required this.category,
  });

  final String value;
  final String description;
  final MeterUnitCategory category;
}

const meterUnitCatalog = <MeterUnitOption>[
  MeterUnitOption(
    value: 'Wh',
    description: 'Wattstunde – kleine Energiemenge',
    category: MeterUnitCategory.energy,
  ),
  MeterUnitOption(
    value: 'kWh',
    description: 'Kilowattstunde – Energieverbrauch oder Erzeugung',
    category: MeterUnitCategory.energy,
  ),
  MeterUnitOption(
    value: 'MWh',
    description: 'Megawattstunde – entspricht 1.000 kWh',
    category: MeterUnitCategory.energy,
  ),
  MeterUnitOption(
    value: 'GWh',
    description: 'Gigawattstunde – entspricht 1.000 MWh',
    category: MeterUnitCategory.energy,
  ),
  MeterUnitOption(
    value: 'kJ',
    description: 'Kilojoule – kleine Wärme- oder Energiemenge',
    category: MeterUnitCategory.energy,
  ),
  MeterUnitOption(
    value: 'MJ',
    description: 'Megajoule – Wärme- oder Energiemenge',
    category: MeterUnitCategory.energy,
  ),
  MeterUnitOption(
    value: 'GJ',
    description: 'Gigajoule – Einheit für Wärmeenergie',
    category: MeterUnitCategory.energy,
  ),
  MeterUnitOption(
    value: 'varh',
    description: 'Varstunde – elektrische Blindenergie',
    category: MeterUnitCategory.electrical,
  ),
  MeterUnitOption(
    value: 'kvarh',
    description: 'Kilovarstunde – elektrische Blindenergie',
    category: MeterUnitCategory.electrical,
  ),
  MeterUnitOption(
    value: 'Mvarh',
    description: 'Megavarstunde – elektrische Blindenergie',
    category: MeterUnitCategory.electrical,
  ),
  MeterUnitOption(
    value: 'VAh',
    description: 'Voltampere-Stunde – elektrische Scheinenergie',
    category: MeterUnitCategory.electrical,
  ),
  MeterUnitOption(
    value: 'kVAh',
    description: 'Kilovoltampere-Stunde – elektrische Scheinenergie',
    category: MeterUnitCategory.electrical,
  ),
  MeterUnitOption(
    value: 'MVAh',
    description: 'Megavoltampere-Stunde – elektrische Scheinenergie',
    category: MeterUnitCategory.electrical,
  ),
  MeterUnitOption(
    value: 'ml',
    description: 'Milliliter – kleine Flüssigkeitsmenge',
    category: MeterUnitCategory.volume,
  ),
  MeterUnitOption(
    value: 'Liter',
    description: 'Liter – Volumen oder Tankinhalt',
    category: MeterUnitCategory.volume,
  ),
  MeterUnitOption(
    value: 'm³',
    description: 'Kubikmeter – Volumen von Gas oder Wasser',
    category: MeterUnitCategory.volume,
  ),
  MeterUnitOption(
    value: 'ft³',
    description: 'Kubikfuß – angloamerikanische Volumeneinheit',
    category: MeterUnitCategory.volume,
  ),
  MeterUnitOption(
    value: 'kg',
    description: 'Kilogramm – Masse oder Vorratsmenge',
    category: MeterUnitCategory.massAndLevel,
  ),
  MeterUnitOption(
    value: 't',
    description: 'Tonne – entspricht 1.000 kg',
    category: MeterUnitCategory.massAndLevel,
  ),
  MeterUnitOption(
    value: '%',
    description: 'Prozent – relativer Füllstand',
    category: MeterUnitCategory.massAndLevel,
  ),
  MeterUnitOption(
    value: 'Einheiten',
    description: 'Abrechnungseinheiten ohne physikalische Maßeinheit',
    category: MeterUnitCategory.general,
  ),
  MeterUnitOption(
    value: 'Impulse',
    description: 'Gezählte elektrische oder mechanische Impulse',
    category: MeterUnitCategory.general,
  ),
  MeterUnitOption(
    value: 'Stück',
    description: 'Gezählte Anzahl einzelner Elemente',
    category: MeterUnitCategory.general,
  ),
  MeterUnitOption(
    value: 'h',
    description: 'Stunden – zum Beispiel für Betriebsstundenzähler',
    category: MeterUnitCategory.general,
  ),
  MeterUnitOption(
    value: 'km',
    description: 'Kilometer – zurückgelegte Strecke',
    category: MeterUnitCategory.general,
  ),
];

final meterUnitCatalogValues = List<String>.unmodifiable(
  meterUnitCatalog.map((option) => option.value),
);

MeterUnitOption? meterUnitOption(String unit) {
  for (final option in meterUnitCatalog) {
    if (option.value == unit) return option;
  }
  return null;
}

String meterUnitDescription(String unit) =>
    meterUnitOption(unit)?.description ?? 'Eigene Einheit dieses Zählers';

enum ReminderInterval { monthly, yearly }

class ReadingReminderSchedule {
  const ReadingReminderSchedule({
    required this.interval,
    required this.day,
    required this.hour,
    required this.minute,
    this.month,
  });

  final ReminderInterval interval;
  final int day;
  final int hour;
  final int minute;
  final int? month;

  Map<String, dynamic> toJson() => {
    'interval': interval.name,
    'day': day,
    'hour': hour,
    'minute': minute,
    'month': month,
  };

  factory ReadingReminderSchedule.fromJson(Map<String, dynamic> json) {
    return ReadingReminderSchedule(
      interval: ReminderInterval.values.byName(json['interval'] as String),
      day: (json['day'] as num).toInt(),
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      month: (json['month'] as num?)?.toInt(),
    );
  }
}

class Meter {
  const Meter({
    required this.id,
    required this.label,
    required this.type,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
    this.meterNumber = '',
    this.location = '',
    this.reminder,
  });

  final String id;
  final String label;
  final MeterType type;
  final String unit;
  final String meterNumber;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReadingReminderSchedule? reminder;

  Meter copyWith({
    String? label,
    MeterType? type,
    String? unit,
    String? meterNumber,
    String? location,
    DateTime? updatedAt,
    ReadingReminderSchedule? reminder,
    bool clearReminder = false,
  }) {
    return Meter(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      meterNumber: meterNumber ?? this.meterNumber,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminder: clearReminder ? null : reminder ?? this.reminder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    'unit': unit,
    'meterNumber': meterNumber,
    'location': location,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'reminder': reminder?.toJson(),
  };

  factory Meter.fromJson(Map<String, dynamic> json) {
    final reminderJson = json['reminder'];
    return Meter(
      id: json['id'] as String,
      label: json['label'] as String,
      type: MeterType.values.byName(json['type'] as String),
      unit: json['unit'] as String,
      meterNumber: json['meterNumber'] as String? ?? '',
      location: json['location'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      reminder: reminderJson is Map
          ? ReadingReminderSchedule.fromJson(
              Map<String, dynamic>.from(reminderJson),
            )
          : null,
    );
  }
}

class MeterSnapshot {
  const MeterSnapshot({
    required this.id,
    required this.label,
    required this.type,
    required this.unit,
    required this.meterNumber,
    required this.location,
  });

  factory MeterSnapshot.fromMeter(Meter meter) => MeterSnapshot(
    id: meter.id,
    label: meter.label,
    type: meter.type,
    unit: meter.unit,
    meterNumber: meter.meterNumber,
    location: meter.location,
  );

  final String id;
  final String label;
  final MeterType type;
  final String unit;
  final String meterNumber;
  final String location;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    'unit': unit,
    'meterNumber': meterNumber,
    'location': location,
  };

  factory MeterSnapshot.fromJson(Map<String, dynamic> json) {
    return MeterSnapshot(
      id: json['id'] as String,
      label: json['label'] as String,
      type: MeterType.values.byName(json['type'] as String),
      unit: json['unit'] as String,
      meterNumber: json['meterNumber'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }
}
