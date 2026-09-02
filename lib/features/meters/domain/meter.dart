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
    MeterType.electricity => const ['kWh', 'MWh', 'Wh'],
    MeterType.electricityFeedIn => const ['kWh', 'MWh'],
    MeterType.gas => const ['m³', 'kWh'],
    MeterType.water ||
    MeterType.coldWater ||
    MeterType.hotWater => const ['m³', 'Liter'],
    MeterType.heat => const ['kWh', 'MWh', 'GJ'],
    MeterType.heatingCostAllocator => const ['Einheiten'],
    MeterType.oil => const ['Liter', '%'],
    MeterType.other => const [
      'Einheiten',
      'kWh',
      'MWh',
      'Wh',
      'm³',
      'Liter',
      'GJ',
      '%',
    ],
  };

  String get defaultUnit => availableUnits.first;
}

String meterUnitDescription(String unit) => switch (unit) {
  'kWh' => 'Kilowattstunde – Energieverbrauch oder Erzeugung',
  'MWh' => 'Megawattstunde – entspricht 1.000 kWh',
  'Wh' => 'Wattstunde – kleine Energiemenge',
  'm³' => 'Kubikmeter – Volumen von Gas oder Wasser',
  'Liter' => 'Liter – Volumen oder Tankinhalt',
  'GJ' => 'Gigajoule – Einheit für Wärmeenergie',
  '%' => 'Prozent – relativer Füllstand',
  'Einheiten' => 'Abrechnungseinheiten ohne physikalische Maßeinheit',
  _ => 'Gespeicherte Einheit dieses Zählers',
};

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
