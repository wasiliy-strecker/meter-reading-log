// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MeterRecordsTable extends MeterRecords
    with TableInfo<$MeterRecordsTable, StoredMeterRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeterRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meterNumberMeta = const VerificationMeta(
    'meterNumber',
  );
  @override
  late final GeneratedColumn<String> meterNumber = GeneratedColumn<String>(
    'meter_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderJsonMeta = const VerificationMeta(
    'reminderJson',
  );
  @override
  late final GeneratedColumn<String> reminderJson = GeneratedColumn<String>(
    'reminder_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    type,
    unit,
    meterNumber,
    location,
    createdAtMillis,
    updatedAtMillis,
    reminderJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meter_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredMeterRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('meter_number')) {
      context.handle(
        _meterNumberMeta,
        meterNumber.isAcceptableOrUnknown(
          data['meter_number']!,
          _meterNumberMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    if (data.containsKey('reminder_json')) {
      context.handle(
        _reminderJsonMeta,
        reminderJson.isAcceptableOrUnknown(
          data['reminder_json']!,
          _reminderJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredMeterRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredMeterRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      meterNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meter_number'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
      reminderJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_json'],
      ),
    );
  }

  @override
  $MeterRecordsTable createAlias(String alias) {
    return $MeterRecordsTable(attachedDatabase, alias);
  }
}

class StoredMeterRecord extends DataClass
    implements Insertable<StoredMeterRecord> {
  final String id;
  final String label;
  final String type;
  final String unit;
  final String meterNumber;
  final String location;
  final int createdAtMillis;
  final int updatedAtMillis;
  final String? reminderJson;
  const StoredMeterRecord({
    required this.id,
    required this.label,
    required this.type,
    required this.unit,
    required this.meterNumber,
    required this.location,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.reminderJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['type'] = Variable<String>(type);
    map['unit'] = Variable<String>(unit);
    map['meter_number'] = Variable<String>(meterNumber);
    map['location'] = Variable<String>(location);
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    if (!nullToAbsent || reminderJson != null) {
      map['reminder_json'] = Variable<String>(reminderJson);
    }
    return map;
  }

  MeterRecordsCompanion toCompanion(bool nullToAbsent) {
    return MeterRecordsCompanion(
      id: Value(id),
      label: Value(label),
      type: Value(type),
      unit: Value(unit),
      meterNumber: Value(meterNumber),
      location: Value(location),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
      reminderJson: reminderJson == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderJson),
    );
  }

  factory StoredMeterRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredMeterRecord(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      type: serializer.fromJson<String>(json['type']),
      unit: serializer.fromJson<String>(json['unit']),
      meterNumber: serializer.fromJson<String>(json['meterNumber']),
      location: serializer.fromJson<String>(json['location']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
      reminderJson: serializer.fromJson<String?>(json['reminderJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'type': serializer.toJson<String>(type),
      'unit': serializer.toJson<String>(unit),
      'meterNumber': serializer.toJson<String>(meterNumber),
      'location': serializer.toJson<String>(location),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
      'reminderJson': serializer.toJson<String?>(reminderJson),
    };
  }

  StoredMeterRecord copyWith({
    String? id,
    String? label,
    String? type,
    String? unit,
    String? meterNumber,
    String? location,
    int? createdAtMillis,
    int? updatedAtMillis,
    Value<String?> reminderJson = const Value.absent(),
  }) => StoredMeterRecord(
    id: id ?? this.id,
    label: label ?? this.label,
    type: type ?? this.type,
    unit: unit ?? this.unit,
    meterNumber: meterNumber ?? this.meterNumber,
    location: location ?? this.location,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    reminderJson: reminderJson.present ? reminderJson.value : this.reminderJson,
  );
  StoredMeterRecord copyWithCompanion(MeterRecordsCompanion data) {
    return StoredMeterRecord(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      type: data.type.present ? data.type.value : this.type,
      unit: data.unit.present ? data.unit.value : this.unit,
      meterNumber: data.meterNumber.present
          ? data.meterNumber.value
          : this.meterNumber,
      location: data.location.present ? data.location.value : this.location,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
      reminderJson: data.reminderJson.present
          ? data.reminderJson.value
          : this.reminderJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredMeterRecord(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('unit: $unit, ')
          ..write('meterNumber: $meterNumber, ')
          ..write('location: $location, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('reminderJson: $reminderJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    type,
    unit,
    meterNumber,
    location,
    createdAtMillis,
    updatedAtMillis,
    reminderJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredMeterRecord &&
          other.id == this.id &&
          other.label == this.label &&
          other.type == this.type &&
          other.unit == this.unit &&
          other.meterNumber == this.meterNumber &&
          other.location == this.location &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis &&
          other.reminderJson == this.reminderJson);
}

class MeterRecordsCompanion extends UpdateCompanion<StoredMeterRecord> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> type;
  final Value<String> unit;
  final Value<String> meterNumber;
  final Value<String> location;
  final Value<int> createdAtMillis;
  final Value<int> updatedAtMillis;
  final Value<String?> reminderJson;
  final Value<int> rowid;
  const MeterRecordsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.type = const Value.absent(),
    this.unit = const Value.absent(),
    this.meterNumber = const Value.absent(),
    this.location = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.reminderJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeterRecordsCompanion.insert({
    required String id,
    required String label,
    required String type,
    required String unit,
    this.meterNumber = const Value.absent(),
    this.location = const Value.absent(),
    required int createdAtMillis,
    required int updatedAtMillis,
    this.reminderJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       type = Value(type),
       unit = Value(unit),
       createdAtMillis = Value(createdAtMillis),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<StoredMeterRecord> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? type,
    Expression<String>? unit,
    Expression<String>? meterNumber,
    Expression<String>? location,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
    Expression<String>? reminderJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (type != null) 'type': type,
      if (unit != null) 'unit': unit,
      if (meterNumber != null) 'meter_number': meterNumber,
      if (location != null) 'location': location,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (reminderJson != null) 'reminder_json': reminderJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeterRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? type,
    Value<String>? unit,
    Value<String>? meterNumber,
    Value<String>? location,
    Value<int>? createdAtMillis,
    Value<int>? updatedAtMillis,
    Value<String?>? reminderJson,
    Value<int>? rowid,
  }) {
    return MeterRecordsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      meterNumber: meterNumber ?? this.meterNumber,
      location: location ?? this.location,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      reminderJson: reminderJson ?? this.reminderJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (meterNumber.present) {
      map['meter_number'] = Variable<String>(meterNumber.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (reminderJson.present) {
      map['reminder_json'] = Variable<String>(reminderJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeterRecordsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('unit: $unit, ')
          ..write('meterNumber: $meterNumber, ')
          ..write('location: $location, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('reminderJson: $reminderJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingRecordsTable extends ReadingRecords
    with TableInfo<$ReadingRecordsTable, StoredReadingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meterIdMeta = const VerificationMeta(
    'meterId',
  );
  @override
  late final GeneratedColumn<String> meterId = GeneratedColumn<String>(
    'meter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meterSnapshotJsonMeta = const VerificationMeta(
    'meterSnapshotJson',
  );
  @override
  late final GeneratedColumn<String> meterSnapshotJson =
      GeneratedColumn<String>(
        'meter_snapshot_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _displayValueMeta = const VerificationMeta(
    'displayValue',
  );
  @override
  late final GeneratedColumn<String> displayValue = GeneratedColumn<String>(
    'display_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueDigitsMeta = const VerificationMeta(
    'valueDigits',
  );
  @override
  late final GeneratedColumn<String> valueDigits = GeneratedColumn<String>(
    'value_digits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueScaleMeta = const VerificationMeta(
    'valueScale',
  );
  @override
  late final GeneratedColumn<int> valueScale = GeneratedColumn<int>(
    'value_scale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMillisMeta = const VerificationMeta(
    'capturedAtMillis',
  );
  @override
  late final GeneratedColumn<int> capturedAtMillis = GeneratedColumn<int>(
    'captured_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneOffsetMinutesMeta =
      const VerificationMeta('timezoneOffsetMinutes');
  @override
  late final GeneratedColumn<int> timezoneOffsetMinutes = GeneratedColumn<int>(
    'timezone_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedAtMillisMeta = const VerificationMeta(
    'storedAtMillis',
  );
  @override
  late final GeneratedColumn<int> storedAtMillis = GeneratedColumn<int>(
    'stored_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoSha256Meta = const VerificationMeta(
    'photoSha256',
  );
  @override
  late final GeneratedColumn<String> photoSha256 = GeneratedColumn<String>(
    'photo_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ocrRawTextMeta = const VerificationMeta(
    'ocrRawText',
  );
  @override
  late final GeneratedColumn<String> ocrRawText = GeneratedColumn<String>(
    'ocr_raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ocrCandidateMeta = const VerificationMeta(
    'ocrCandidate',
  );
  @override
  late final GeneratedColumn<String> ocrCandidate = GeneratedColumn<String>(
    'ocr_candidate',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ocrConfidenceMeta = const VerificationMeta(
    'ocrConfidence',
  );
  @override
  late final GeneratedColumn<double> ocrConfidence = GeneratedColumn<double>(
    'ocr_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoAddedAtMillisMeta =
      const VerificationMeta('photoAddedAtMillis');
  @override
  late final GeneratedColumn<int> photoAddedAtMillis = GeneratedColumn<int>(
    'photo_added_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoHistoryJsonMeta = const VerificationMeta(
    'photoHistoryJson',
  );
  @override
  late final GeneratedColumn<String> photoHistoryJson = GeneratedColumn<String>(
    'photo_history_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _lowerReadingReasonMeta =
      const VerificationMeta('lowerReadingReason');
  @override
  late final GeneratedColumn<String> lowerReadingReason =
      GeneratedColumn<String>(
        'lower_reading_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _manifestSha256Meta = const VerificationMeta(
    'manifestSha256',
  );
  @override
  late final GeneratedColumn<String> manifestSha256 = GeneratedColumn<String>(
    'manifest_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    meterId,
    meterSnapshotJson,
    displayValue,
    valueDigits,
    valueScale,
    capturedAtMillis,
    timezoneOffsetMinutes,
    storedAtMillis,
    updatedAtMillis,
    source,
    photoPath,
    photoSha256,
    ocrRawText,
    ocrCandidate,
    ocrConfidence,
    photoAddedAtMillis,
    photoHistoryJson,
    lowerReadingReason,
    note,
    manifestSha256,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredReadingRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meter_id')) {
      context.handle(
        _meterIdMeta,
        meterId.isAcceptableOrUnknown(data['meter_id']!, _meterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meterIdMeta);
    }
    if (data.containsKey('meter_snapshot_json')) {
      context.handle(
        _meterSnapshotJsonMeta,
        meterSnapshotJson.isAcceptableOrUnknown(
          data['meter_snapshot_json']!,
          _meterSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_meterSnapshotJsonMeta);
    }
    if (data.containsKey('display_value')) {
      context.handle(
        _displayValueMeta,
        displayValue.isAcceptableOrUnknown(
          data['display_value']!,
          _displayValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayValueMeta);
    }
    if (data.containsKey('value_digits')) {
      context.handle(
        _valueDigitsMeta,
        valueDigits.isAcceptableOrUnknown(
          data['value_digits']!,
          _valueDigitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valueDigitsMeta);
    }
    if (data.containsKey('value_scale')) {
      context.handle(
        _valueScaleMeta,
        valueScale.isAcceptableOrUnknown(data['value_scale']!, _valueScaleMeta),
      );
    } else if (isInserting) {
      context.missing(_valueScaleMeta);
    }
    if (data.containsKey('captured_at_millis')) {
      context.handle(
        _capturedAtMillisMeta,
        capturedAtMillis.isAcceptableOrUnknown(
          data['captured_at_millis']!,
          _capturedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMillisMeta);
    }
    if (data.containsKey('timezone_offset_minutes')) {
      context.handle(
        _timezoneOffsetMinutesMeta,
        timezoneOffsetMinutes.isAcceptableOrUnknown(
          data['timezone_offset_minutes']!,
          _timezoneOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timezoneOffsetMinutesMeta);
    }
    if (data.containsKey('stored_at_millis')) {
      context.handle(
        _storedAtMillisMeta,
        storedAtMillis.isAcceptableOrUnknown(
          data['stored_at_millis']!,
          _storedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storedAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('photo_sha256')) {
      context.handle(
        _photoSha256Meta,
        photoSha256.isAcceptableOrUnknown(
          data['photo_sha256']!,
          _photoSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_photoSha256Meta);
    }
    if (data.containsKey('ocr_raw_text')) {
      context.handle(
        _ocrRawTextMeta,
        ocrRawText.isAcceptableOrUnknown(
          data['ocr_raw_text']!,
          _ocrRawTextMeta,
        ),
      );
    }
    if (data.containsKey('ocr_candidate')) {
      context.handle(
        _ocrCandidateMeta,
        ocrCandidate.isAcceptableOrUnknown(
          data['ocr_candidate']!,
          _ocrCandidateMeta,
        ),
      );
    }
    if (data.containsKey('ocr_confidence')) {
      context.handle(
        _ocrConfidenceMeta,
        ocrConfidence.isAcceptableOrUnknown(
          data['ocr_confidence']!,
          _ocrConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('photo_added_at_millis')) {
      context.handle(
        _photoAddedAtMillisMeta,
        photoAddedAtMillis.isAcceptableOrUnknown(
          data['photo_added_at_millis']!,
          _photoAddedAtMillisMeta,
        ),
      );
    }
    if (data.containsKey('photo_history_json')) {
      context.handle(
        _photoHistoryJsonMeta,
        photoHistoryJson.isAcceptableOrUnknown(
          data['photo_history_json']!,
          _photoHistoryJsonMeta,
        ),
      );
    }
    if (data.containsKey('lower_reading_reason')) {
      context.handle(
        _lowerReadingReasonMeta,
        lowerReadingReason.isAcceptableOrUnknown(
          data['lower_reading_reason']!,
          _lowerReadingReasonMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('manifest_sha256')) {
      context.handle(
        _manifestSha256Meta,
        manifestSha256.isAcceptableOrUnknown(
          data['manifest_sha256']!,
          _manifestSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manifestSha256Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredReadingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredReadingRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      meterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meter_id'],
      )!,
      meterSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meter_snapshot_json'],
      )!,
      displayValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_value'],
      )!,
      valueDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_digits'],
      )!,
      valueScale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value_scale'],
      )!,
      capturedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captured_at_millis'],
      )!,
      timezoneOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timezone_offset_minutes'],
      )!,
      storedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stored_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      )!,
      photoSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_sha256'],
      )!,
      ocrRawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_raw_text'],
      )!,
      ocrCandidate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_candidate'],
      )!,
      ocrConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ocr_confidence'],
      ),
      photoAddedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_added_at_millis'],
      ),
      photoHistoryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_history_json'],
      )!,
      lowerReadingReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lower_reading_reason'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      manifestSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manifest_sha256'],
      )!,
    );
  }

  @override
  $ReadingRecordsTable createAlias(String alias) {
    return $ReadingRecordsTable(attachedDatabase, alias);
  }
}

class StoredReadingRecord extends DataClass
    implements Insertable<StoredReadingRecord> {
  final String id;
  final String meterId;
  final String meterSnapshotJson;
  final String displayValue;
  final String valueDigits;
  final int valueScale;
  final int capturedAtMillis;
  final int timezoneOffsetMinutes;
  final int storedAtMillis;
  final int updatedAtMillis;
  final String source;
  final String photoPath;
  final String photoSha256;
  final String ocrRawText;
  final String ocrCandidate;
  final double? ocrConfidence;
  final int? photoAddedAtMillis;
  final String photoHistoryJson;
  final String? lowerReadingReason;
  final String note;
  final String manifestSha256;
  const StoredReadingRecord({
    required this.id,
    required this.meterId,
    required this.meterSnapshotJson,
    required this.displayValue,
    required this.valueDigits,
    required this.valueScale,
    required this.capturedAtMillis,
    required this.timezoneOffsetMinutes,
    required this.storedAtMillis,
    required this.updatedAtMillis,
    required this.source,
    required this.photoPath,
    required this.photoSha256,
    required this.ocrRawText,
    required this.ocrCandidate,
    this.ocrConfidence,
    this.photoAddedAtMillis,
    required this.photoHistoryJson,
    this.lowerReadingReason,
    required this.note,
    required this.manifestSha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meter_id'] = Variable<String>(meterId);
    map['meter_snapshot_json'] = Variable<String>(meterSnapshotJson);
    map['display_value'] = Variable<String>(displayValue);
    map['value_digits'] = Variable<String>(valueDigits);
    map['value_scale'] = Variable<int>(valueScale);
    map['captured_at_millis'] = Variable<int>(capturedAtMillis);
    map['timezone_offset_minutes'] = Variable<int>(timezoneOffsetMinutes);
    map['stored_at_millis'] = Variable<int>(storedAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    map['source'] = Variable<String>(source);
    map['photo_path'] = Variable<String>(photoPath);
    map['photo_sha256'] = Variable<String>(photoSha256);
    map['ocr_raw_text'] = Variable<String>(ocrRawText);
    map['ocr_candidate'] = Variable<String>(ocrCandidate);
    if (!nullToAbsent || ocrConfidence != null) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence);
    }
    if (!nullToAbsent || photoAddedAtMillis != null) {
      map['photo_added_at_millis'] = Variable<int>(photoAddedAtMillis);
    }
    map['photo_history_json'] = Variable<String>(photoHistoryJson);
    if (!nullToAbsent || lowerReadingReason != null) {
      map['lower_reading_reason'] = Variable<String>(lowerReadingReason);
    }
    map['note'] = Variable<String>(note);
    map['manifest_sha256'] = Variable<String>(manifestSha256);
    return map;
  }

  ReadingRecordsCompanion toCompanion(bool nullToAbsent) {
    return ReadingRecordsCompanion(
      id: Value(id),
      meterId: Value(meterId),
      meterSnapshotJson: Value(meterSnapshotJson),
      displayValue: Value(displayValue),
      valueDigits: Value(valueDigits),
      valueScale: Value(valueScale),
      capturedAtMillis: Value(capturedAtMillis),
      timezoneOffsetMinutes: Value(timezoneOffsetMinutes),
      storedAtMillis: Value(storedAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
      source: Value(source),
      photoPath: Value(photoPath),
      photoSha256: Value(photoSha256),
      ocrRawText: Value(ocrRawText),
      ocrCandidate: Value(ocrCandidate),
      ocrConfidence: ocrConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrConfidence),
      photoAddedAtMillis: photoAddedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(photoAddedAtMillis),
      photoHistoryJson: Value(photoHistoryJson),
      lowerReadingReason: lowerReadingReason == null && nullToAbsent
          ? const Value.absent()
          : Value(lowerReadingReason),
      note: Value(note),
      manifestSha256: Value(manifestSha256),
    );
  }

  factory StoredReadingRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredReadingRecord(
      id: serializer.fromJson<String>(json['id']),
      meterId: serializer.fromJson<String>(json['meterId']),
      meterSnapshotJson: serializer.fromJson<String>(json['meterSnapshotJson']),
      displayValue: serializer.fromJson<String>(json['displayValue']),
      valueDigits: serializer.fromJson<String>(json['valueDigits']),
      valueScale: serializer.fromJson<int>(json['valueScale']),
      capturedAtMillis: serializer.fromJson<int>(json['capturedAtMillis']),
      timezoneOffsetMinutes: serializer.fromJson<int>(
        json['timezoneOffsetMinutes'],
      ),
      storedAtMillis: serializer.fromJson<int>(json['storedAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
      source: serializer.fromJson<String>(json['source']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      photoSha256: serializer.fromJson<String>(json['photoSha256']),
      ocrRawText: serializer.fromJson<String>(json['ocrRawText']),
      ocrCandidate: serializer.fromJson<String>(json['ocrCandidate']),
      ocrConfidence: serializer.fromJson<double?>(json['ocrConfidence']),
      photoAddedAtMillis: serializer.fromJson<int?>(json['photoAddedAtMillis']),
      photoHistoryJson: serializer.fromJson<String>(json['photoHistoryJson']),
      lowerReadingReason: serializer.fromJson<String?>(
        json['lowerReadingReason'],
      ),
      note: serializer.fromJson<String>(json['note']),
      manifestSha256: serializer.fromJson<String>(json['manifestSha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meterId': serializer.toJson<String>(meterId),
      'meterSnapshotJson': serializer.toJson<String>(meterSnapshotJson),
      'displayValue': serializer.toJson<String>(displayValue),
      'valueDigits': serializer.toJson<String>(valueDigits),
      'valueScale': serializer.toJson<int>(valueScale),
      'capturedAtMillis': serializer.toJson<int>(capturedAtMillis),
      'timezoneOffsetMinutes': serializer.toJson<int>(timezoneOffsetMinutes),
      'storedAtMillis': serializer.toJson<int>(storedAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
      'source': serializer.toJson<String>(source),
      'photoPath': serializer.toJson<String>(photoPath),
      'photoSha256': serializer.toJson<String>(photoSha256),
      'ocrRawText': serializer.toJson<String>(ocrRawText),
      'ocrCandidate': serializer.toJson<String>(ocrCandidate),
      'ocrConfidence': serializer.toJson<double?>(ocrConfidence),
      'photoAddedAtMillis': serializer.toJson<int?>(photoAddedAtMillis),
      'photoHistoryJson': serializer.toJson<String>(photoHistoryJson),
      'lowerReadingReason': serializer.toJson<String?>(lowerReadingReason),
      'note': serializer.toJson<String>(note),
      'manifestSha256': serializer.toJson<String>(manifestSha256),
    };
  }

  StoredReadingRecord copyWith({
    String? id,
    String? meterId,
    String? meterSnapshotJson,
    String? displayValue,
    String? valueDigits,
    int? valueScale,
    int? capturedAtMillis,
    int? timezoneOffsetMinutes,
    int? storedAtMillis,
    int? updatedAtMillis,
    String? source,
    String? photoPath,
    String? photoSha256,
    String? ocrRawText,
    String? ocrCandidate,
    Value<double?> ocrConfidence = const Value.absent(),
    Value<int?> photoAddedAtMillis = const Value.absent(),
    String? photoHistoryJson,
    Value<String?> lowerReadingReason = const Value.absent(),
    String? note,
    String? manifestSha256,
  }) => StoredReadingRecord(
    id: id ?? this.id,
    meterId: meterId ?? this.meterId,
    meterSnapshotJson: meterSnapshotJson ?? this.meterSnapshotJson,
    displayValue: displayValue ?? this.displayValue,
    valueDigits: valueDigits ?? this.valueDigits,
    valueScale: valueScale ?? this.valueScale,
    capturedAtMillis: capturedAtMillis ?? this.capturedAtMillis,
    timezoneOffsetMinutes: timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
    storedAtMillis: storedAtMillis ?? this.storedAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    source: source ?? this.source,
    photoPath: photoPath ?? this.photoPath,
    photoSha256: photoSha256 ?? this.photoSha256,
    ocrRawText: ocrRawText ?? this.ocrRawText,
    ocrCandidate: ocrCandidate ?? this.ocrCandidate,
    ocrConfidence: ocrConfidence.present
        ? ocrConfidence.value
        : this.ocrConfidence,
    photoAddedAtMillis: photoAddedAtMillis.present
        ? photoAddedAtMillis.value
        : this.photoAddedAtMillis,
    photoHistoryJson: photoHistoryJson ?? this.photoHistoryJson,
    lowerReadingReason: lowerReadingReason.present
        ? lowerReadingReason.value
        : this.lowerReadingReason,
    note: note ?? this.note,
    manifestSha256: manifestSha256 ?? this.manifestSha256,
  );
  StoredReadingRecord copyWithCompanion(ReadingRecordsCompanion data) {
    return StoredReadingRecord(
      id: data.id.present ? data.id.value : this.id,
      meterId: data.meterId.present ? data.meterId.value : this.meterId,
      meterSnapshotJson: data.meterSnapshotJson.present
          ? data.meterSnapshotJson.value
          : this.meterSnapshotJson,
      displayValue: data.displayValue.present
          ? data.displayValue.value
          : this.displayValue,
      valueDigits: data.valueDigits.present
          ? data.valueDigits.value
          : this.valueDigits,
      valueScale: data.valueScale.present
          ? data.valueScale.value
          : this.valueScale,
      capturedAtMillis: data.capturedAtMillis.present
          ? data.capturedAtMillis.value
          : this.capturedAtMillis,
      timezoneOffsetMinutes: data.timezoneOffsetMinutes.present
          ? data.timezoneOffsetMinutes.value
          : this.timezoneOffsetMinutes,
      storedAtMillis: data.storedAtMillis.present
          ? data.storedAtMillis.value
          : this.storedAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
      source: data.source.present ? data.source.value : this.source,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoSha256: data.photoSha256.present
          ? data.photoSha256.value
          : this.photoSha256,
      ocrRawText: data.ocrRawText.present
          ? data.ocrRawText.value
          : this.ocrRawText,
      ocrCandidate: data.ocrCandidate.present
          ? data.ocrCandidate.value
          : this.ocrCandidate,
      ocrConfidence: data.ocrConfidence.present
          ? data.ocrConfidence.value
          : this.ocrConfidence,
      photoAddedAtMillis: data.photoAddedAtMillis.present
          ? data.photoAddedAtMillis.value
          : this.photoAddedAtMillis,
      photoHistoryJson: data.photoHistoryJson.present
          ? data.photoHistoryJson.value
          : this.photoHistoryJson,
      lowerReadingReason: data.lowerReadingReason.present
          ? data.lowerReadingReason.value
          : this.lowerReadingReason,
      note: data.note.present ? data.note.value : this.note,
      manifestSha256: data.manifestSha256.present
          ? data.manifestSha256.value
          : this.manifestSha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredReadingRecord(')
          ..write('id: $id, ')
          ..write('meterId: $meterId, ')
          ..write('meterSnapshotJson: $meterSnapshotJson, ')
          ..write('displayValue: $displayValue, ')
          ..write('valueDigits: $valueDigits, ')
          ..write('valueScale: $valueScale, ')
          ..write('capturedAtMillis: $capturedAtMillis, ')
          ..write('timezoneOffsetMinutes: $timezoneOffsetMinutes, ')
          ..write('storedAtMillis: $storedAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('source: $source, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoSha256: $photoSha256, ')
          ..write('ocrRawText: $ocrRawText, ')
          ..write('ocrCandidate: $ocrCandidate, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('photoAddedAtMillis: $photoAddedAtMillis, ')
          ..write('photoHistoryJson: $photoHistoryJson, ')
          ..write('lowerReadingReason: $lowerReadingReason, ')
          ..write('note: $note, ')
          ..write('manifestSha256: $manifestSha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    meterId,
    meterSnapshotJson,
    displayValue,
    valueDigits,
    valueScale,
    capturedAtMillis,
    timezoneOffsetMinutes,
    storedAtMillis,
    updatedAtMillis,
    source,
    photoPath,
    photoSha256,
    ocrRawText,
    ocrCandidate,
    ocrConfidence,
    photoAddedAtMillis,
    photoHistoryJson,
    lowerReadingReason,
    note,
    manifestSha256,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredReadingRecord &&
          other.id == this.id &&
          other.meterId == this.meterId &&
          other.meterSnapshotJson == this.meterSnapshotJson &&
          other.displayValue == this.displayValue &&
          other.valueDigits == this.valueDigits &&
          other.valueScale == this.valueScale &&
          other.capturedAtMillis == this.capturedAtMillis &&
          other.timezoneOffsetMinutes == this.timezoneOffsetMinutes &&
          other.storedAtMillis == this.storedAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis &&
          other.source == this.source &&
          other.photoPath == this.photoPath &&
          other.photoSha256 == this.photoSha256 &&
          other.ocrRawText == this.ocrRawText &&
          other.ocrCandidate == this.ocrCandidate &&
          other.ocrConfidence == this.ocrConfidence &&
          other.photoAddedAtMillis == this.photoAddedAtMillis &&
          other.photoHistoryJson == this.photoHistoryJson &&
          other.lowerReadingReason == this.lowerReadingReason &&
          other.note == this.note &&
          other.manifestSha256 == this.manifestSha256);
}

class ReadingRecordsCompanion extends UpdateCompanion<StoredReadingRecord> {
  final Value<String> id;
  final Value<String> meterId;
  final Value<String> meterSnapshotJson;
  final Value<String> displayValue;
  final Value<String> valueDigits;
  final Value<int> valueScale;
  final Value<int> capturedAtMillis;
  final Value<int> timezoneOffsetMinutes;
  final Value<int> storedAtMillis;
  final Value<int> updatedAtMillis;
  final Value<String> source;
  final Value<String> photoPath;
  final Value<String> photoSha256;
  final Value<String> ocrRawText;
  final Value<String> ocrCandidate;
  final Value<double?> ocrConfidence;
  final Value<int?> photoAddedAtMillis;
  final Value<String> photoHistoryJson;
  final Value<String?> lowerReadingReason;
  final Value<String> note;
  final Value<String> manifestSha256;
  final Value<int> rowid;
  const ReadingRecordsCompanion({
    this.id = const Value.absent(),
    this.meterId = const Value.absent(),
    this.meterSnapshotJson = const Value.absent(),
    this.displayValue = const Value.absent(),
    this.valueDigits = const Value.absent(),
    this.valueScale = const Value.absent(),
    this.capturedAtMillis = const Value.absent(),
    this.timezoneOffsetMinutes = const Value.absent(),
    this.storedAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.source = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoSha256 = const Value.absent(),
    this.ocrRawText = const Value.absent(),
    this.ocrCandidate = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    this.photoAddedAtMillis = const Value.absent(),
    this.photoHistoryJson = const Value.absent(),
    this.lowerReadingReason = const Value.absent(),
    this.note = const Value.absent(),
    this.manifestSha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingRecordsCompanion.insert({
    required String id,
    required String meterId,
    required String meterSnapshotJson,
    required String displayValue,
    required String valueDigits,
    required int valueScale,
    required int capturedAtMillis,
    required int timezoneOffsetMinutes,
    required int storedAtMillis,
    required int updatedAtMillis,
    required String source,
    required String photoPath,
    required String photoSha256,
    this.ocrRawText = const Value.absent(),
    this.ocrCandidate = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    this.photoAddedAtMillis = const Value.absent(),
    this.photoHistoryJson = const Value.absent(),
    this.lowerReadingReason = const Value.absent(),
    this.note = const Value.absent(),
    required String manifestSha256,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       meterId = Value(meterId),
       meterSnapshotJson = Value(meterSnapshotJson),
       displayValue = Value(displayValue),
       valueDigits = Value(valueDigits),
       valueScale = Value(valueScale),
       capturedAtMillis = Value(capturedAtMillis),
       timezoneOffsetMinutes = Value(timezoneOffsetMinutes),
       storedAtMillis = Value(storedAtMillis),
       updatedAtMillis = Value(updatedAtMillis),
       source = Value(source),
       photoPath = Value(photoPath),
       photoSha256 = Value(photoSha256),
       manifestSha256 = Value(manifestSha256);
  static Insertable<StoredReadingRecord> custom({
    Expression<String>? id,
    Expression<String>? meterId,
    Expression<String>? meterSnapshotJson,
    Expression<String>? displayValue,
    Expression<String>? valueDigits,
    Expression<int>? valueScale,
    Expression<int>? capturedAtMillis,
    Expression<int>? timezoneOffsetMinutes,
    Expression<int>? storedAtMillis,
    Expression<int>? updatedAtMillis,
    Expression<String>? source,
    Expression<String>? photoPath,
    Expression<String>? photoSha256,
    Expression<String>? ocrRawText,
    Expression<String>? ocrCandidate,
    Expression<double>? ocrConfidence,
    Expression<int>? photoAddedAtMillis,
    Expression<String>? photoHistoryJson,
    Expression<String>? lowerReadingReason,
    Expression<String>? note,
    Expression<String>? manifestSha256,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meterId != null) 'meter_id': meterId,
      if (meterSnapshotJson != null) 'meter_snapshot_json': meterSnapshotJson,
      if (displayValue != null) 'display_value': displayValue,
      if (valueDigits != null) 'value_digits': valueDigits,
      if (valueScale != null) 'value_scale': valueScale,
      if (capturedAtMillis != null) 'captured_at_millis': capturedAtMillis,
      if (timezoneOffsetMinutes != null)
        'timezone_offset_minutes': timezoneOffsetMinutes,
      if (storedAtMillis != null) 'stored_at_millis': storedAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (source != null) 'source': source,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoSha256 != null) 'photo_sha256': photoSha256,
      if (ocrRawText != null) 'ocr_raw_text': ocrRawText,
      if (ocrCandidate != null) 'ocr_candidate': ocrCandidate,
      if (ocrConfidence != null) 'ocr_confidence': ocrConfidence,
      if (photoAddedAtMillis != null)
        'photo_added_at_millis': photoAddedAtMillis,
      if (photoHistoryJson != null) 'photo_history_json': photoHistoryJson,
      if (lowerReadingReason != null)
        'lower_reading_reason': lowerReadingReason,
      if (note != null) 'note': note,
      if (manifestSha256 != null) 'manifest_sha256': manifestSha256,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? meterId,
    Value<String>? meterSnapshotJson,
    Value<String>? displayValue,
    Value<String>? valueDigits,
    Value<int>? valueScale,
    Value<int>? capturedAtMillis,
    Value<int>? timezoneOffsetMinutes,
    Value<int>? storedAtMillis,
    Value<int>? updatedAtMillis,
    Value<String>? source,
    Value<String>? photoPath,
    Value<String>? photoSha256,
    Value<String>? ocrRawText,
    Value<String>? ocrCandidate,
    Value<double?>? ocrConfidence,
    Value<int?>? photoAddedAtMillis,
    Value<String>? photoHistoryJson,
    Value<String?>? lowerReadingReason,
    Value<String>? note,
    Value<String>? manifestSha256,
    Value<int>? rowid,
  }) {
    return ReadingRecordsCompanion(
      id: id ?? this.id,
      meterId: meterId ?? this.meterId,
      meterSnapshotJson: meterSnapshotJson ?? this.meterSnapshotJson,
      displayValue: displayValue ?? this.displayValue,
      valueDigits: valueDigits ?? this.valueDigits,
      valueScale: valueScale ?? this.valueScale,
      capturedAtMillis: capturedAtMillis ?? this.capturedAtMillis,
      timezoneOffsetMinutes:
          timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
      storedAtMillis: storedAtMillis ?? this.storedAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      source: source ?? this.source,
      photoPath: photoPath ?? this.photoPath,
      photoSha256: photoSha256 ?? this.photoSha256,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      ocrCandidate: ocrCandidate ?? this.ocrCandidate,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      photoAddedAtMillis: photoAddedAtMillis ?? this.photoAddedAtMillis,
      photoHistoryJson: photoHistoryJson ?? this.photoHistoryJson,
      lowerReadingReason: lowerReadingReason ?? this.lowerReadingReason,
      note: note ?? this.note,
      manifestSha256: manifestSha256 ?? this.manifestSha256,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (meterId.present) {
      map['meter_id'] = Variable<String>(meterId.value);
    }
    if (meterSnapshotJson.present) {
      map['meter_snapshot_json'] = Variable<String>(meterSnapshotJson.value);
    }
    if (displayValue.present) {
      map['display_value'] = Variable<String>(displayValue.value);
    }
    if (valueDigits.present) {
      map['value_digits'] = Variable<String>(valueDigits.value);
    }
    if (valueScale.present) {
      map['value_scale'] = Variable<int>(valueScale.value);
    }
    if (capturedAtMillis.present) {
      map['captured_at_millis'] = Variable<int>(capturedAtMillis.value);
    }
    if (timezoneOffsetMinutes.present) {
      map['timezone_offset_minutes'] = Variable<int>(
        timezoneOffsetMinutes.value,
      );
    }
    if (storedAtMillis.present) {
      map['stored_at_millis'] = Variable<int>(storedAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoSha256.present) {
      map['photo_sha256'] = Variable<String>(photoSha256.value);
    }
    if (ocrRawText.present) {
      map['ocr_raw_text'] = Variable<String>(ocrRawText.value);
    }
    if (ocrCandidate.present) {
      map['ocr_candidate'] = Variable<String>(ocrCandidate.value);
    }
    if (ocrConfidence.present) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence.value);
    }
    if (photoAddedAtMillis.present) {
      map['photo_added_at_millis'] = Variable<int>(photoAddedAtMillis.value);
    }
    if (photoHistoryJson.present) {
      map['photo_history_json'] = Variable<String>(photoHistoryJson.value);
    }
    if (lowerReadingReason.present) {
      map['lower_reading_reason'] = Variable<String>(lowerReadingReason.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (manifestSha256.present) {
      map['manifest_sha256'] = Variable<String>(manifestSha256.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingRecordsCompanion(')
          ..write('id: $id, ')
          ..write('meterId: $meterId, ')
          ..write('meterSnapshotJson: $meterSnapshotJson, ')
          ..write('displayValue: $displayValue, ')
          ..write('valueDigits: $valueDigits, ')
          ..write('valueScale: $valueScale, ')
          ..write('capturedAtMillis: $capturedAtMillis, ')
          ..write('timezoneOffsetMinutes: $timezoneOffsetMinutes, ')
          ..write('storedAtMillis: $storedAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('source: $source, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoSha256: $photoSha256, ')
          ..write('ocrRawText: $ocrRawText, ')
          ..write('ocrCandidate: $ocrCandidate, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('photoAddedAtMillis: $photoAddedAtMillis, ')
          ..write('photoHistoryJson: $photoHistoryJson, ')
          ..write('lowerReadingReason: $lowerReadingReason, ')
          ..write('note: $note, ')
          ..write('manifestSha256: $manifestSha256, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RevisionRecordsTable extends RevisionRecords
    with TableInfo<$RevisionRecordsTable, StoredRevisionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RevisionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingIdMeta = const VerificationMeta(
    'readingId',
  );
  @override
  late final GeneratedColumn<String> readingId = GeneratedColumn<String>(
    'reading_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changedAtMillisMeta = const VerificationMeta(
    'changedAtMillis',
  );
  @override
  late final GeneratedColumn<int> changedAtMillis = GeneratedColumn<int>(
    'changed_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changesJsonMeta = const VerificationMeta(
    'changesJson',
  );
  @override
  late final GeneratedColumn<String> changesJson = GeneratedColumn<String>(
    'changes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    readingId,
    changedAtMillis,
    reason,
    changesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'revision_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredRevisionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reading_id')) {
      context.handle(
        _readingIdMeta,
        readingId.isAcceptableOrUnknown(data['reading_id']!, _readingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_readingIdMeta);
    }
    if (data.containsKey('changed_at_millis')) {
      context.handle(
        _changedAtMillisMeta,
        changedAtMillis.isAcceptableOrUnknown(
          data['changed_at_millis']!,
          _changedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changedAtMillisMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('changes_json')) {
      context.handle(
        _changesJsonMeta,
        changesJson.isAcceptableOrUnknown(
          data['changes_json']!,
          _changesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changesJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredRevisionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredRevisionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      readingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_id'],
      )!,
      changedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}changed_at_millis'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      changesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changes_json'],
      )!,
    );
  }

  @override
  $RevisionRecordsTable createAlias(String alias) {
    return $RevisionRecordsTable(attachedDatabase, alias);
  }
}

class StoredRevisionRecord extends DataClass
    implements Insertable<StoredRevisionRecord> {
  final String id;
  final String readingId;
  final int changedAtMillis;
  final String reason;
  final String changesJson;
  const StoredRevisionRecord({
    required this.id,
    required this.readingId,
    required this.changedAtMillis,
    required this.reason,
    required this.changesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reading_id'] = Variable<String>(readingId);
    map['changed_at_millis'] = Variable<int>(changedAtMillis);
    map['reason'] = Variable<String>(reason);
    map['changes_json'] = Variable<String>(changesJson);
    return map;
  }

  RevisionRecordsCompanion toCompanion(bool nullToAbsent) {
    return RevisionRecordsCompanion(
      id: Value(id),
      readingId: Value(readingId),
      changedAtMillis: Value(changedAtMillis),
      reason: Value(reason),
      changesJson: Value(changesJson),
    );
  }

  factory StoredRevisionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredRevisionRecord(
      id: serializer.fromJson<String>(json['id']),
      readingId: serializer.fromJson<String>(json['readingId']),
      changedAtMillis: serializer.fromJson<int>(json['changedAtMillis']),
      reason: serializer.fromJson<String>(json['reason']),
      changesJson: serializer.fromJson<String>(json['changesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'readingId': serializer.toJson<String>(readingId),
      'changedAtMillis': serializer.toJson<int>(changedAtMillis),
      'reason': serializer.toJson<String>(reason),
      'changesJson': serializer.toJson<String>(changesJson),
    };
  }

  StoredRevisionRecord copyWith({
    String? id,
    String? readingId,
    int? changedAtMillis,
    String? reason,
    String? changesJson,
  }) => StoredRevisionRecord(
    id: id ?? this.id,
    readingId: readingId ?? this.readingId,
    changedAtMillis: changedAtMillis ?? this.changedAtMillis,
    reason: reason ?? this.reason,
    changesJson: changesJson ?? this.changesJson,
  );
  StoredRevisionRecord copyWithCompanion(RevisionRecordsCompanion data) {
    return StoredRevisionRecord(
      id: data.id.present ? data.id.value : this.id,
      readingId: data.readingId.present ? data.readingId.value : this.readingId,
      changedAtMillis: data.changedAtMillis.present
          ? data.changedAtMillis.value
          : this.changedAtMillis,
      reason: data.reason.present ? data.reason.value : this.reason,
      changesJson: data.changesJson.present
          ? data.changesJson.value
          : this.changesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredRevisionRecord(')
          ..write('id: $id, ')
          ..write('readingId: $readingId, ')
          ..write('changedAtMillis: $changedAtMillis, ')
          ..write('reason: $reason, ')
          ..write('changesJson: $changesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, readingId, changedAtMillis, reason, changesJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredRevisionRecord &&
          other.id == this.id &&
          other.readingId == this.readingId &&
          other.changedAtMillis == this.changedAtMillis &&
          other.reason == this.reason &&
          other.changesJson == this.changesJson);
}

class RevisionRecordsCompanion extends UpdateCompanion<StoredRevisionRecord> {
  final Value<String> id;
  final Value<String> readingId;
  final Value<int> changedAtMillis;
  final Value<String> reason;
  final Value<String> changesJson;
  final Value<int> rowid;
  const RevisionRecordsCompanion({
    this.id = const Value.absent(),
    this.readingId = const Value.absent(),
    this.changedAtMillis = const Value.absent(),
    this.reason = const Value.absent(),
    this.changesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RevisionRecordsCompanion.insert({
    required String id,
    required String readingId,
    required int changedAtMillis,
    required String reason,
    required String changesJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       readingId = Value(readingId),
       changedAtMillis = Value(changedAtMillis),
       reason = Value(reason),
       changesJson = Value(changesJson);
  static Insertable<StoredRevisionRecord> custom({
    Expression<String>? id,
    Expression<String>? readingId,
    Expression<int>? changedAtMillis,
    Expression<String>? reason,
    Expression<String>? changesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (readingId != null) 'reading_id': readingId,
      if (changedAtMillis != null) 'changed_at_millis': changedAtMillis,
      if (reason != null) 'reason': reason,
      if (changesJson != null) 'changes_json': changesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RevisionRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? readingId,
    Value<int>? changedAtMillis,
    Value<String>? reason,
    Value<String>? changesJson,
    Value<int>? rowid,
  }) {
    return RevisionRecordsCompanion(
      id: id ?? this.id,
      readingId: readingId ?? this.readingId,
      changedAtMillis: changedAtMillis ?? this.changedAtMillis,
      reason: reason ?? this.reason,
      changesJson: changesJson ?? this.changesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (readingId.present) {
      map['reading_id'] = Variable<String>(readingId.value);
    }
    if (changedAtMillis.present) {
      map['changed_at_millis'] = Variable<int>(changedAtMillis.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (changesJson.present) {
      map['changes_json'] = Variable<String>(changesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevisionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('readingId: $readingId, ')
          ..write('changedAtMillis: $changedAtMillis, ')
          ..write('reason: $reason, ')
          ..write('changesJson: $changesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvidenceExportRecordsTable extends EvidenceExportRecords
    with TableInfo<$EvidenceExportRecordsTable, StoredEvidenceExportRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvidenceExportRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meterIdMeta = const VerificationMeta(
    'meterId',
  );
  @override
  late final GeneratedColumn<String> meterId = GeneratedColumn<String>(
    'meter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingIdsJsonMeta = const VerificationMeta(
    'readingIdsJson',
  );
  @override
  late final GeneratedColumn<String> readingIdsJson = GeneratedColumn<String>(
    'reading_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pdfSha256Meta = const VerificationMeta(
    'pdfSha256',
  );
  @override
  late final GeneratedColumn<String> pdfSha256 = GeneratedColumn<String>(
    'pdf_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manifestSha256Meta = const VerificationMeta(
    'manifestSha256',
  );
  @override
  late final GeneratedColumn<String> manifestSha256 = GeneratedColumn<String>(
    'manifest_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    meterId,
    kind,
    readingIdsJson,
    createdAtMillis,
    fileName,
    filePath,
    pdfSha256,
    manifestSha256,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evidence_export_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredEvidenceExportRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meter_id')) {
      context.handle(
        _meterIdMeta,
        meterId.isAcceptableOrUnknown(data['meter_id']!, _meterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meterIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('reading_ids_json')) {
      context.handle(
        _readingIdsJsonMeta,
        readingIdsJson.isAcceptableOrUnknown(
          data['reading_ids_json']!,
          _readingIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_readingIdsJsonMeta);
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('pdf_sha256')) {
      context.handle(
        _pdfSha256Meta,
        pdfSha256.isAcceptableOrUnknown(data['pdf_sha256']!, _pdfSha256Meta),
      );
    } else if (isInserting) {
      context.missing(_pdfSha256Meta);
    }
    if (data.containsKey('manifest_sha256')) {
      context.handle(
        _manifestSha256Meta,
        manifestSha256.isAcceptableOrUnknown(
          data['manifest_sha256']!,
          _manifestSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manifestSha256Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredEvidenceExportRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredEvidenceExportRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      meterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meter_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      readingIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_ids_json'],
      )!,
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      pdfSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_sha256'],
      )!,
      manifestSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manifest_sha256'],
      )!,
    );
  }

  @override
  $EvidenceExportRecordsTable createAlias(String alias) {
    return $EvidenceExportRecordsTable(attachedDatabase, alias);
  }
}

class StoredEvidenceExportRecord extends DataClass
    implements Insertable<StoredEvidenceExportRecord> {
  final String id;
  final String meterId;
  final String kind;
  final String readingIdsJson;
  final int createdAtMillis;
  final String fileName;
  final String filePath;
  final String pdfSha256;
  final String manifestSha256;
  const StoredEvidenceExportRecord({
    required this.id,
    required this.meterId,
    required this.kind,
    required this.readingIdsJson,
    required this.createdAtMillis,
    required this.fileName,
    required this.filePath,
    required this.pdfSha256,
    required this.manifestSha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meter_id'] = Variable<String>(meterId);
    map['kind'] = Variable<String>(kind);
    map['reading_ids_json'] = Variable<String>(readingIdsJson);
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['file_name'] = Variable<String>(fileName);
    map['file_path'] = Variable<String>(filePath);
    map['pdf_sha256'] = Variable<String>(pdfSha256);
    map['manifest_sha256'] = Variable<String>(manifestSha256);
    return map;
  }

  EvidenceExportRecordsCompanion toCompanion(bool nullToAbsent) {
    return EvidenceExportRecordsCompanion(
      id: Value(id),
      meterId: Value(meterId),
      kind: Value(kind),
      readingIdsJson: Value(readingIdsJson),
      createdAtMillis: Value(createdAtMillis),
      fileName: Value(fileName),
      filePath: Value(filePath),
      pdfSha256: Value(pdfSha256),
      manifestSha256: Value(manifestSha256),
    );
  }

  factory StoredEvidenceExportRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredEvidenceExportRecord(
      id: serializer.fromJson<String>(json['id']),
      meterId: serializer.fromJson<String>(json['meterId']),
      kind: serializer.fromJson<String>(json['kind']),
      readingIdsJson: serializer.fromJson<String>(json['readingIdsJson']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      fileName: serializer.fromJson<String>(json['fileName']),
      filePath: serializer.fromJson<String>(json['filePath']),
      pdfSha256: serializer.fromJson<String>(json['pdfSha256']),
      manifestSha256: serializer.fromJson<String>(json['manifestSha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meterId': serializer.toJson<String>(meterId),
      'kind': serializer.toJson<String>(kind),
      'readingIdsJson': serializer.toJson<String>(readingIdsJson),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'fileName': serializer.toJson<String>(fileName),
      'filePath': serializer.toJson<String>(filePath),
      'pdfSha256': serializer.toJson<String>(pdfSha256),
      'manifestSha256': serializer.toJson<String>(manifestSha256),
    };
  }

  StoredEvidenceExportRecord copyWith({
    String? id,
    String? meterId,
    String? kind,
    String? readingIdsJson,
    int? createdAtMillis,
    String? fileName,
    String? filePath,
    String? pdfSha256,
    String? manifestSha256,
  }) => StoredEvidenceExportRecord(
    id: id ?? this.id,
    meterId: meterId ?? this.meterId,
    kind: kind ?? this.kind,
    readingIdsJson: readingIdsJson ?? this.readingIdsJson,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    fileName: fileName ?? this.fileName,
    filePath: filePath ?? this.filePath,
    pdfSha256: pdfSha256 ?? this.pdfSha256,
    manifestSha256: manifestSha256 ?? this.manifestSha256,
  );
  StoredEvidenceExportRecord copyWithCompanion(
    EvidenceExportRecordsCompanion data,
  ) {
    return StoredEvidenceExportRecord(
      id: data.id.present ? data.id.value : this.id,
      meterId: data.meterId.present ? data.meterId.value : this.meterId,
      kind: data.kind.present ? data.kind.value : this.kind,
      readingIdsJson: data.readingIdsJson.present
          ? data.readingIdsJson.value
          : this.readingIdsJson,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      pdfSha256: data.pdfSha256.present ? data.pdfSha256.value : this.pdfSha256,
      manifestSha256: data.manifestSha256.present
          ? data.manifestSha256.value
          : this.manifestSha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredEvidenceExportRecord(')
          ..write('id: $id, ')
          ..write('meterId: $meterId, ')
          ..write('kind: $kind, ')
          ..write('readingIdsJson: $readingIdsJson, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('pdfSha256: $pdfSha256, ')
          ..write('manifestSha256: $manifestSha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    meterId,
    kind,
    readingIdsJson,
    createdAtMillis,
    fileName,
    filePath,
    pdfSha256,
    manifestSha256,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredEvidenceExportRecord &&
          other.id == this.id &&
          other.meterId == this.meterId &&
          other.kind == this.kind &&
          other.readingIdsJson == this.readingIdsJson &&
          other.createdAtMillis == this.createdAtMillis &&
          other.fileName == this.fileName &&
          other.filePath == this.filePath &&
          other.pdfSha256 == this.pdfSha256 &&
          other.manifestSha256 == this.manifestSha256);
}

class EvidenceExportRecordsCompanion
    extends UpdateCompanion<StoredEvidenceExportRecord> {
  final Value<String> id;
  final Value<String> meterId;
  final Value<String> kind;
  final Value<String> readingIdsJson;
  final Value<int> createdAtMillis;
  final Value<String> fileName;
  final Value<String> filePath;
  final Value<String> pdfSha256;
  final Value<String> manifestSha256;
  final Value<int> rowid;
  const EvidenceExportRecordsCompanion({
    this.id = const Value.absent(),
    this.meterId = const Value.absent(),
    this.kind = const Value.absent(),
    this.readingIdsJson = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.fileName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.pdfSha256 = const Value.absent(),
    this.manifestSha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvidenceExportRecordsCompanion.insert({
    required String id,
    required String meterId,
    required String kind,
    required String readingIdsJson,
    required int createdAtMillis,
    required String fileName,
    required String filePath,
    required String pdfSha256,
    required String manifestSha256,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       meterId = Value(meterId),
       kind = Value(kind),
       readingIdsJson = Value(readingIdsJson),
       createdAtMillis = Value(createdAtMillis),
       fileName = Value(fileName),
       filePath = Value(filePath),
       pdfSha256 = Value(pdfSha256),
       manifestSha256 = Value(manifestSha256);
  static Insertable<StoredEvidenceExportRecord> custom({
    Expression<String>? id,
    Expression<String>? meterId,
    Expression<String>? kind,
    Expression<String>? readingIdsJson,
    Expression<int>? createdAtMillis,
    Expression<String>? fileName,
    Expression<String>? filePath,
    Expression<String>? pdfSha256,
    Expression<String>? manifestSha256,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meterId != null) 'meter_id': meterId,
      if (kind != null) 'kind': kind,
      if (readingIdsJson != null) 'reading_ids_json': readingIdsJson,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (fileName != null) 'file_name': fileName,
      if (filePath != null) 'file_path': filePath,
      if (pdfSha256 != null) 'pdf_sha256': pdfSha256,
      if (manifestSha256 != null) 'manifest_sha256': manifestSha256,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvidenceExportRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? meterId,
    Value<String>? kind,
    Value<String>? readingIdsJson,
    Value<int>? createdAtMillis,
    Value<String>? fileName,
    Value<String>? filePath,
    Value<String>? pdfSha256,
    Value<String>? manifestSha256,
    Value<int>? rowid,
  }) {
    return EvidenceExportRecordsCompanion(
      id: id ?? this.id,
      meterId: meterId ?? this.meterId,
      kind: kind ?? this.kind,
      readingIdsJson: readingIdsJson ?? this.readingIdsJson,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      pdfSha256: pdfSha256 ?? this.pdfSha256,
      manifestSha256: manifestSha256 ?? this.manifestSha256,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (meterId.present) {
      map['meter_id'] = Variable<String>(meterId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (readingIdsJson.present) {
      map['reading_ids_json'] = Variable<String>(readingIdsJson.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (pdfSha256.present) {
      map['pdf_sha256'] = Variable<String>(pdfSha256.value);
    }
    if (manifestSha256.present) {
      map['manifest_sha256'] = Variable<String>(manifestSha256.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceExportRecordsCompanion(')
          ..write('id: $id, ')
          ..write('meterId: $meterId, ')
          ..write('kind: $kind, ')
          ..write('readingIdsJson: $readingIdsJson, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('pdfSha256: $pdfSha256, ')
          ..write('manifestSha256: $manifestSha256, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MeterRecordsTable meterRecords = $MeterRecordsTable(this);
  late final $ReadingRecordsTable readingRecords = $ReadingRecordsTable(this);
  late final $RevisionRecordsTable revisionRecords = $RevisionRecordsTable(
    this,
  );
  late final $EvidenceExportRecordsTable evidenceExportRecords =
      $EvidenceExportRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    meterRecords,
    readingRecords,
    revisionRecords,
    evidenceExportRecords,
  ];
}

typedef $$MeterRecordsTableCreateCompanionBuilder =
    MeterRecordsCompanion Function({
      required String id,
      required String label,
      required String type,
      required String unit,
      Value<String> meterNumber,
      Value<String> location,
      required int createdAtMillis,
      required int updatedAtMillis,
      Value<String?> reminderJson,
      Value<int> rowid,
    });
typedef $$MeterRecordsTableUpdateCompanionBuilder =
    MeterRecordsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<String> type,
      Value<String> unit,
      Value<String> meterNumber,
      Value<String> location,
      Value<int> createdAtMillis,
      Value<int> updatedAtMillis,
      Value<String?> reminderJson,
      Value<int> rowid,
    });

class $$MeterRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MeterRecordsTable> {
  $$MeterRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meterNumber => $composableBuilder(
    column: $table.meterNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderJson => $composableBuilder(
    column: $table.reminderJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeterRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeterRecordsTable> {
  $$MeterRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meterNumber => $composableBuilder(
    column: $table.meterNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderJson => $composableBuilder(
    column: $table.reminderJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeterRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeterRecordsTable> {
  $$MeterRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get meterNumber => $composableBuilder(
    column: $table.meterNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderJson => $composableBuilder(
    column: $table.reminderJson,
    builder: (column) => column,
  );
}

class $$MeterRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeterRecordsTable,
          StoredMeterRecord,
          $$MeterRecordsTableFilterComposer,
          $$MeterRecordsTableOrderingComposer,
          $$MeterRecordsTableAnnotationComposer,
          $$MeterRecordsTableCreateCompanionBuilder,
          $$MeterRecordsTableUpdateCompanionBuilder,
          (
            StoredMeterRecord,
            BaseReferences<
              _$AppDatabase,
              $MeterRecordsTable,
              StoredMeterRecord
            >,
          ),
          StoredMeterRecord,
          PrefetchHooks Function()
        > {
  $$MeterRecordsTableTableManager(_$AppDatabase db, $MeterRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeterRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeterRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeterRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> meterNumber = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
                Value<String?> reminderJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeterRecordsCompanion(
                id: id,
                label: label,
                type: type,
                unit: unit,
                meterNumber: meterNumber,
                location: location,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                reminderJson: reminderJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String type,
                required String unit,
                Value<String> meterNumber = const Value.absent(),
                Value<String> location = const Value.absent(),
                required int createdAtMillis,
                required int updatedAtMillis,
                Value<String?> reminderJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeterRecordsCompanion.insert(
                id: id,
                label: label,
                type: type,
                unit: unit,
                meterNumber: meterNumber,
                location: location,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                reminderJson: reminderJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MeterRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeterRecordsTable,
      StoredMeterRecord,
      $$MeterRecordsTableFilterComposer,
      $$MeterRecordsTableOrderingComposer,
      $$MeterRecordsTableAnnotationComposer,
      $$MeterRecordsTableCreateCompanionBuilder,
      $$MeterRecordsTableUpdateCompanionBuilder,
      (
        StoredMeterRecord,
        BaseReferences<_$AppDatabase, $MeterRecordsTable, StoredMeterRecord>,
      ),
      StoredMeterRecord,
      PrefetchHooks Function()
    >;
typedef $$ReadingRecordsTableCreateCompanionBuilder =
    ReadingRecordsCompanion Function({
      required String id,
      required String meterId,
      required String meterSnapshotJson,
      required String displayValue,
      required String valueDigits,
      required int valueScale,
      required int capturedAtMillis,
      required int timezoneOffsetMinutes,
      required int storedAtMillis,
      required int updatedAtMillis,
      required String source,
      required String photoPath,
      required String photoSha256,
      Value<String> ocrRawText,
      Value<String> ocrCandidate,
      Value<double?> ocrConfidence,
      Value<int?> photoAddedAtMillis,
      Value<String> photoHistoryJson,
      Value<String?> lowerReadingReason,
      Value<String> note,
      required String manifestSha256,
      Value<int> rowid,
    });
typedef $$ReadingRecordsTableUpdateCompanionBuilder =
    ReadingRecordsCompanion Function({
      Value<String> id,
      Value<String> meterId,
      Value<String> meterSnapshotJson,
      Value<String> displayValue,
      Value<String> valueDigits,
      Value<int> valueScale,
      Value<int> capturedAtMillis,
      Value<int> timezoneOffsetMinutes,
      Value<int> storedAtMillis,
      Value<int> updatedAtMillis,
      Value<String> source,
      Value<String> photoPath,
      Value<String> photoSha256,
      Value<String> ocrRawText,
      Value<String> ocrCandidate,
      Value<double?> ocrConfidence,
      Value<int?> photoAddedAtMillis,
      Value<String> photoHistoryJson,
      Value<String?> lowerReadingReason,
      Value<String> note,
      Value<String> manifestSha256,
      Value<int> rowid,
    });

class $$ReadingRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingRecordsTable> {
  $$ReadingRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meterId => $composableBuilder(
    column: $table.meterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meterSnapshotJson => $composableBuilder(
    column: $table.meterSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueDigits => $composableBuilder(
    column: $table.valueDigits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valueScale => $composableBuilder(
    column: $table.valueScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capturedAtMillis => $composableBuilder(
    column: $table.capturedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timezoneOffsetMinutes => $composableBuilder(
    column: $table.timezoneOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storedAtMillis => $composableBuilder(
    column: $table.storedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoSha256 => $composableBuilder(
    column: $table.photoSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrRawText => $composableBuilder(
    column: $table.ocrRawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrCandidate => $composableBuilder(
    column: $table.ocrCandidate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get photoAddedAtMillis => $composableBuilder(
    column: $table.photoAddedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoHistoryJson => $composableBuilder(
    column: $table.photoHistoryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lowerReadingReason => $composableBuilder(
    column: $table.lowerReadingReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manifestSha256 => $composableBuilder(
    column: $table.manifestSha256,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingRecordsTable> {
  $$ReadingRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meterId => $composableBuilder(
    column: $table.meterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meterSnapshotJson => $composableBuilder(
    column: $table.meterSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueDigits => $composableBuilder(
    column: $table.valueDigits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valueScale => $composableBuilder(
    column: $table.valueScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedAtMillis => $composableBuilder(
    column: $table.capturedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timezoneOffsetMinutes => $composableBuilder(
    column: $table.timezoneOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storedAtMillis => $composableBuilder(
    column: $table.storedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoSha256 => $composableBuilder(
    column: $table.photoSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrRawText => $composableBuilder(
    column: $table.ocrRawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrCandidate => $composableBuilder(
    column: $table.ocrCandidate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get photoAddedAtMillis => $composableBuilder(
    column: $table.photoAddedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoHistoryJson => $composableBuilder(
    column: $table.photoHistoryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lowerReadingReason => $composableBuilder(
    column: $table.lowerReadingReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manifestSha256 => $composableBuilder(
    column: $table.manifestSha256,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingRecordsTable> {
  $$ReadingRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get meterId =>
      $composableBuilder(column: $table.meterId, builder: (column) => column);

  GeneratedColumn<String> get meterSnapshotJson => $composableBuilder(
    column: $table.meterSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valueDigits => $composableBuilder(
    column: $table.valueDigits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valueScale => $composableBuilder(
    column: $table.valueScale,
    builder: (column) => column,
  );

  GeneratedColumn<int> get capturedAtMillis => $composableBuilder(
    column: $table.capturedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timezoneOffsetMinutes => $composableBuilder(
    column: $table.timezoneOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get storedAtMillis => $composableBuilder(
    column: $table.storedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get photoSha256 => $composableBuilder(
    column: $table.photoSha256,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrRawText => $composableBuilder(
    column: $table.ocrRawText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrCandidate => $composableBuilder(
    column: $table.ocrCandidate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get photoAddedAtMillis => $composableBuilder(
    column: $table.photoAddedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoHistoryJson => $composableBuilder(
    column: $table.photoHistoryJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lowerReadingReason => $composableBuilder(
    column: $table.lowerReadingReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get manifestSha256 => $composableBuilder(
    column: $table.manifestSha256,
    builder: (column) => column,
  );
}

class $$ReadingRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingRecordsTable,
          StoredReadingRecord,
          $$ReadingRecordsTableFilterComposer,
          $$ReadingRecordsTableOrderingComposer,
          $$ReadingRecordsTableAnnotationComposer,
          $$ReadingRecordsTableCreateCompanionBuilder,
          $$ReadingRecordsTableUpdateCompanionBuilder,
          (
            StoredReadingRecord,
            BaseReferences<
              _$AppDatabase,
              $ReadingRecordsTable,
              StoredReadingRecord
            >,
          ),
          StoredReadingRecord,
          PrefetchHooks Function()
        > {
  $$ReadingRecordsTableTableManager(
    _$AppDatabase db,
    $ReadingRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> meterId = const Value.absent(),
                Value<String> meterSnapshotJson = const Value.absent(),
                Value<String> displayValue = const Value.absent(),
                Value<String> valueDigits = const Value.absent(),
                Value<int> valueScale = const Value.absent(),
                Value<int> capturedAtMillis = const Value.absent(),
                Value<int> timezoneOffsetMinutes = const Value.absent(),
                Value<int> storedAtMillis = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> photoPath = const Value.absent(),
                Value<String> photoSha256 = const Value.absent(),
                Value<String> ocrRawText = const Value.absent(),
                Value<String> ocrCandidate = const Value.absent(),
                Value<double?> ocrConfidence = const Value.absent(),
                Value<int?> photoAddedAtMillis = const Value.absent(),
                Value<String> photoHistoryJson = const Value.absent(),
                Value<String?> lowerReadingReason = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> manifestSha256 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingRecordsCompanion(
                id: id,
                meterId: meterId,
                meterSnapshotJson: meterSnapshotJson,
                displayValue: displayValue,
                valueDigits: valueDigits,
                valueScale: valueScale,
                capturedAtMillis: capturedAtMillis,
                timezoneOffsetMinutes: timezoneOffsetMinutes,
                storedAtMillis: storedAtMillis,
                updatedAtMillis: updatedAtMillis,
                source: source,
                photoPath: photoPath,
                photoSha256: photoSha256,
                ocrRawText: ocrRawText,
                ocrCandidate: ocrCandidate,
                ocrConfidence: ocrConfidence,
                photoAddedAtMillis: photoAddedAtMillis,
                photoHistoryJson: photoHistoryJson,
                lowerReadingReason: lowerReadingReason,
                note: note,
                manifestSha256: manifestSha256,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String meterId,
                required String meterSnapshotJson,
                required String displayValue,
                required String valueDigits,
                required int valueScale,
                required int capturedAtMillis,
                required int timezoneOffsetMinutes,
                required int storedAtMillis,
                required int updatedAtMillis,
                required String source,
                required String photoPath,
                required String photoSha256,
                Value<String> ocrRawText = const Value.absent(),
                Value<String> ocrCandidate = const Value.absent(),
                Value<double?> ocrConfidence = const Value.absent(),
                Value<int?> photoAddedAtMillis = const Value.absent(),
                Value<String> photoHistoryJson = const Value.absent(),
                Value<String?> lowerReadingReason = const Value.absent(),
                Value<String> note = const Value.absent(),
                required String manifestSha256,
                Value<int> rowid = const Value.absent(),
              }) => ReadingRecordsCompanion.insert(
                id: id,
                meterId: meterId,
                meterSnapshotJson: meterSnapshotJson,
                displayValue: displayValue,
                valueDigits: valueDigits,
                valueScale: valueScale,
                capturedAtMillis: capturedAtMillis,
                timezoneOffsetMinutes: timezoneOffsetMinutes,
                storedAtMillis: storedAtMillis,
                updatedAtMillis: updatedAtMillis,
                source: source,
                photoPath: photoPath,
                photoSha256: photoSha256,
                ocrRawText: ocrRawText,
                ocrCandidate: ocrCandidate,
                ocrConfidence: ocrConfidence,
                photoAddedAtMillis: photoAddedAtMillis,
                photoHistoryJson: photoHistoryJson,
                lowerReadingReason: lowerReadingReason,
                note: note,
                manifestSha256: manifestSha256,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingRecordsTable,
      StoredReadingRecord,
      $$ReadingRecordsTableFilterComposer,
      $$ReadingRecordsTableOrderingComposer,
      $$ReadingRecordsTableAnnotationComposer,
      $$ReadingRecordsTableCreateCompanionBuilder,
      $$ReadingRecordsTableUpdateCompanionBuilder,
      (
        StoredReadingRecord,
        BaseReferences<
          _$AppDatabase,
          $ReadingRecordsTable,
          StoredReadingRecord
        >,
      ),
      StoredReadingRecord,
      PrefetchHooks Function()
    >;
typedef $$RevisionRecordsTableCreateCompanionBuilder =
    RevisionRecordsCompanion Function({
      required String id,
      required String readingId,
      required int changedAtMillis,
      required String reason,
      required String changesJson,
      Value<int> rowid,
    });
typedef $$RevisionRecordsTableUpdateCompanionBuilder =
    RevisionRecordsCompanion Function({
      Value<String> id,
      Value<String> readingId,
      Value<int> changedAtMillis,
      Value<String> reason,
      Value<String> changesJson,
      Value<int> rowid,
    });

class $$RevisionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RevisionRecordsTable> {
  $$RevisionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readingId => $composableBuilder(
    column: $table.readingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changedAtMillis => $composableBuilder(
    column: $table.changedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changesJson => $composableBuilder(
    column: $table.changesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RevisionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RevisionRecordsTable> {
  $$RevisionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingId => $composableBuilder(
    column: $table.readingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changedAtMillis => $composableBuilder(
    column: $table.changedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changesJson => $composableBuilder(
    column: $table.changesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RevisionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RevisionRecordsTable> {
  $$RevisionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get readingId =>
      $composableBuilder(column: $table.readingId, builder: (column) => column);

  GeneratedColumn<int> get changedAtMillis => $composableBuilder(
    column: $table.changedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get changesJson => $composableBuilder(
    column: $table.changesJson,
    builder: (column) => column,
  );
}

class $$RevisionRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RevisionRecordsTable,
          StoredRevisionRecord,
          $$RevisionRecordsTableFilterComposer,
          $$RevisionRecordsTableOrderingComposer,
          $$RevisionRecordsTableAnnotationComposer,
          $$RevisionRecordsTableCreateCompanionBuilder,
          $$RevisionRecordsTableUpdateCompanionBuilder,
          (
            StoredRevisionRecord,
            BaseReferences<
              _$AppDatabase,
              $RevisionRecordsTable,
              StoredRevisionRecord
            >,
          ),
          StoredRevisionRecord,
          PrefetchHooks Function()
        > {
  $$RevisionRecordsTableTableManager(
    _$AppDatabase db,
    $RevisionRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RevisionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RevisionRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RevisionRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> readingId = const Value.absent(),
                Value<int> changedAtMillis = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> changesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionRecordsCompanion(
                id: id,
                readingId: readingId,
                changedAtMillis: changedAtMillis,
                reason: reason,
                changesJson: changesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String readingId,
                required int changedAtMillis,
                required String reason,
                required String changesJson,
                Value<int> rowid = const Value.absent(),
              }) => RevisionRecordsCompanion.insert(
                id: id,
                readingId: readingId,
                changedAtMillis: changedAtMillis,
                reason: reason,
                changesJson: changesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RevisionRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RevisionRecordsTable,
      StoredRevisionRecord,
      $$RevisionRecordsTableFilterComposer,
      $$RevisionRecordsTableOrderingComposer,
      $$RevisionRecordsTableAnnotationComposer,
      $$RevisionRecordsTableCreateCompanionBuilder,
      $$RevisionRecordsTableUpdateCompanionBuilder,
      (
        StoredRevisionRecord,
        BaseReferences<
          _$AppDatabase,
          $RevisionRecordsTable,
          StoredRevisionRecord
        >,
      ),
      StoredRevisionRecord,
      PrefetchHooks Function()
    >;
typedef $$EvidenceExportRecordsTableCreateCompanionBuilder =
    EvidenceExportRecordsCompanion Function({
      required String id,
      required String meterId,
      required String kind,
      required String readingIdsJson,
      required int createdAtMillis,
      required String fileName,
      required String filePath,
      required String pdfSha256,
      required String manifestSha256,
      Value<int> rowid,
    });
typedef $$EvidenceExportRecordsTableUpdateCompanionBuilder =
    EvidenceExportRecordsCompanion Function({
      Value<String> id,
      Value<String> meterId,
      Value<String> kind,
      Value<String> readingIdsJson,
      Value<int> createdAtMillis,
      Value<String> fileName,
      Value<String> filePath,
      Value<String> pdfSha256,
      Value<String> manifestSha256,
      Value<int> rowid,
    });

class $$EvidenceExportRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $EvidenceExportRecordsTable> {
  $$EvidenceExportRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meterId => $composableBuilder(
    column: $table.meterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readingIdsJson => $composableBuilder(
    column: $table.readingIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfSha256 => $composableBuilder(
    column: $table.pdfSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manifestSha256 => $composableBuilder(
    column: $table.manifestSha256,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EvidenceExportRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $EvidenceExportRecordsTable> {
  $$EvidenceExportRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meterId => $composableBuilder(
    column: $table.meterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingIdsJson => $composableBuilder(
    column: $table.readingIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfSha256 => $composableBuilder(
    column: $table.pdfSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manifestSha256 => $composableBuilder(
    column: $table.manifestSha256,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EvidenceExportRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EvidenceExportRecordsTable> {
  $$EvidenceExportRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get meterId =>
      $composableBuilder(column: $table.meterId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get readingIdsJson => $composableBuilder(
    column: $table.readingIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get pdfSha256 =>
      $composableBuilder(column: $table.pdfSha256, builder: (column) => column);

  GeneratedColumn<String> get manifestSha256 => $composableBuilder(
    column: $table.manifestSha256,
    builder: (column) => column,
  );
}

class $$EvidenceExportRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EvidenceExportRecordsTable,
          StoredEvidenceExportRecord,
          $$EvidenceExportRecordsTableFilterComposer,
          $$EvidenceExportRecordsTableOrderingComposer,
          $$EvidenceExportRecordsTableAnnotationComposer,
          $$EvidenceExportRecordsTableCreateCompanionBuilder,
          $$EvidenceExportRecordsTableUpdateCompanionBuilder,
          (
            StoredEvidenceExportRecord,
            BaseReferences<
              _$AppDatabase,
              $EvidenceExportRecordsTable,
              StoredEvidenceExportRecord
            >,
          ),
          StoredEvidenceExportRecord,
          PrefetchHooks Function()
        > {
  $$EvidenceExportRecordsTableTableManager(
    _$AppDatabase db,
    $EvidenceExportRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvidenceExportRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EvidenceExportRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EvidenceExportRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> meterId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> readingIdsJson = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> pdfSha256 = const Value.absent(),
                Value<String> manifestSha256 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidenceExportRecordsCompanion(
                id: id,
                meterId: meterId,
                kind: kind,
                readingIdsJson: readingIdsJson,
                createdAtMillis: createdAtMillis,
                fileName: fileName,
                filePath: filePath,
                pdfSha256: pdfSha256,
                manifestSha256: manifestSha256,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String meterId,
                required String kind,
                required String readingIdsJson,
                required int createdAtMillis,
                required String fileName,
                required String filePath,
                required String pdfSha256,
                required String manifestSha256,
                Value<int> rowid = const Value.absent(),
              }) => EvidenceExportRecordsCompanion.insert(
                id: id,
                meterId: meterId,
                kind: kind,
                readingIdsJson: readingIdsJson,
                createdAtMillis: createdAtMillis,
                fileName: fileName,
                filePath: filePath,
                pdfSha256: pdfSha256,
                manifestSha256: manifestSha256,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EvidenceExportRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EvidenceExportRecordsTable,
      StoredEvidenceExportRecord,
      $$EvidenceExportRecordsTableFilterComposer,
      $$EvidenceExportRecordsTableOrderingComposer,
      $$EvidenceExportRecordsTableAnnotationComposer,
      $$EvidenceExportRecordsTableCreateCompanionBuilder,
      $$EvidenceExportRecordsTableUpdateCompanionBuilder,
      (
        StoredEvidenceExportRecord,
        BaseReferences<
          _$AppDatabase,
          $EvidenceExportRecordsTable,
          StoredEvidenceExportRecord
        >,
      ),
      StoredEvidenceExportRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MeterRecordsTableTableManager get meterRecords =>
      $$MeterRecordsTableTableManager(_db, _db.meterRecords);
  $$ReadingRecordsTableTableManager get readingRecords =>
      $$ReadingRecordsTableTableManager(_db, _db.readingRecords);
  $$RevisionRecordsTableTableManager get revisionRecords =>
      $$RevisionRecordsTableTableManager(_db, _db.revisionRecords);
  $$EvidenceExportRecordsTableTableManager get evidenceExportRecords =>
      $$EvidenceExportRecordsTableTableManager(_db, _db.evidenceExportRecords);
}
