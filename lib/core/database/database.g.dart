// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DestinationsTable extends Destinations
    with TableInfo<$DestinationsTable, DestinationsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DestinationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alertRadiusMeta = const VerificationMeta(
    'alertRadius',
  );
  @override
  late final GeneratedColumn<double> alertRadius = GeneratedColumn<double>(
    'alert_radius',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(300),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    latitude,
    longitude,
    alertRadius,
    isFavorite,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'destinations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DestinationsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('alert_radius')) {
      context.handle(
        _alertRadiusMeta,
        alertRadius.isAcceptableOrUnknown(
          data['alert_radius']!,
          _alertRadiusMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DestinationsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DestinationsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      alertRadius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alert_radius'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DestinationsTable createAlias(String alias) {
    return $DestinationsTable(attachedDatabase, alias);
  }
}

class DestinationsRow extends DataClass implements Insertable<DestinationsRow> {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double alertRadius;
  final bool isFavorite;
  final DateTime createdAt;
  const DestinationsRow({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.alertRadius,
    required this.isFavorite,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['alert_radius'] = Variable<double>(alertRadius);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DestinationsCompanion toCompanion(bool nullToAbsent) {
    return DestinationsCompanion(
      id: Value(id),
      name: Value(name),
      latitude: Value(latitude),
      longitude: Value(longitude),
      alertRadius: Value(alertRadius),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
    );
  }

  factory DestinationsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DestinationsRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      alertRadius: serializer.fromJson<double>(json['alertRadius']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'alertRadius': serializer.toJson<double>(alertRadius),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DestinationsRow copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? alertRadius,
    bool? isFavorite,
    DateTime? createdAt,
  }) => DestinationsRow(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    alertRadius: alertRadius ?? this.alertRadius,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
  );
  DestinationsRow copyWithCompanion(DestinationsCompanion data) {
    return DestinationsRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      alertRadius: data.alertRadius.present
          ? data.alertRadius.value
          : this.alertRadius,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DestinationsRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('alertRadius: $alertRadius, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    latitude,
    longitude,
    alertRadius,
    isFavorite,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DestinationsRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.alertRadius == this.alertRadius &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt);
}

class DestinationsCompanion extends UpdateCompanion<DestinationsRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> alertRadius;
  final Value<bool> isFavorite;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DestinationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.alertRadius = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DestinationsCompanion.insert({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    this.alertRadius = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude),
       createdAt = Value(createdAt);
  static Insertable<DestinationsRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? alertRadius,
    Expression<bool>? isFavorite,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (alertRadius != null) 'alert_radius': alertRadius,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DestinationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? alertRadius,
    Value<bool>? isFavorite,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DestinationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      alertRadius: alertRadius ?? this.alertRadius,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (alertRadius.present) {
      map['alert_radius'] = Variable<double>(alertRadius.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DestinationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('alertRadius: $alertRadius, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultAlertRadiusMeta =
      const VerificationMeta('defaultAlertRadius');
  @override
  late final GeneratedColumn<double> defaultAlertRadius =
      GeneratedColumn<double>(
        'default_alert_radius',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(300),
      );
  static const VerificationMeta _alarmTypeMeta = const VerificationMeta(
    'alarmType',
  );
  @override
  late final GeneratedColumn<String> alarmType = GeneratedColumn<String>(
    'alarm_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commuteModeMeta = const VerificationMeta(
    'commuteMode',
  );
  @override
  late final GeneratedColumn<String> commuteMode = GeneratedColumn<String>(
    'commute_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repeatedAlarmMeta = const VerificationMeta(
    'repeatedAlarm',
  );
  @override
  late final GeneratedColumn<bool> repeatedAlarm = GeneratedColumn<bool>(
    'repeated_alarm',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("repeated_alarm" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    defaultAlertRadius,
    alarmType,
    commuteMode,
    repeatedAlarm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('default_alert_radius')) {
      context.handle(
        _defaultAlertRadiusMeta,
        defaultAlertRadius.isAcceptableOrUnknown(
          data['default_alert_radius']!,
          _defaultAlertRadiusMeta,
        ),
      );
    }
    if (data.containsKey('alarm_type')) {
      context.handle(
        _alarmTypeMeta,
        alarmType.isAcceptableOrUnknown(data['alarm_type']!, _alarmTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_alarmTypeMeta);
    }
    if (data.containsKey('commute_mode')) {
      context.handle(
        _commuteModeMeta,
        commuteMode.isAcceptableOrUnknown(
          data['commute_mode']!,
          _commuteModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commuteModeMeta);
    }
    if (data.containsKey('repeated_alarm')) {
      context.handle(
        _repeatedAlarmMeta,
        repeatedAlarm.isAcceptableOrUnknown(
          data['repeated_alarm']!,
          _repeatedAlarmMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      defaultAlertRadius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_alert_radius'],
      )!,
      alarmType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_type'],
      )!,
      commuteMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commute_mode'],
      )!,
      repeatedAlarm: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}repeated_alarm'],
      )!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }
}

class AppSettingsTableData extends DataClass
    implements Insertable<AppSettingsTableData> {
  final int id;
  final double defaultAlertRadius;
  final String alarmType;
  final String commuteMode;
  final bool repeatedAlarm;
  const AppSettingsTableData({
    required this.id,
    required this.defaultAlertRadius,
    required this.alarmType,
    required this.commuteMode,
    required this.repeatedAlarm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['default_alert_radius'] = Variable<double>(defaultAlertRadius);
    map['alarm_type'] = Variable<String>(alarmType);
    map['commute_mode'] = Variable<String>(commuteMode);
    map['repeated_alarm'] = Variable<bool>(repeatedAlarm);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      id: Value(id),
      defaultAlertRadius: Value(defaultAlertRadius),
      alarmType: Value(alarmType),
      commuteMode: Value(commuteMode),
      repeatedAlarm: Value(repeatedAlarm),
    );
  }

  factory AppSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      defaultAlertRadius: serializer.fromJson<double>(
        json['defaultAlertRadius'],
      ),
      alarmType: serializer.fromJson<String>(json['alarmType']),
      commuteMode: serializer.fromJson<String>(json['commuteMode']),
      repeatedAlarm: serializer.fromJson<bool>(json['repeatedAlarm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'defaultAlertRadius': serializer.toJson<double>(defaultAlertRadius),
      'alarmType': serializer.toJson<String>(alarmType),
      'commuteMode': serializer.toJson<String>(commuteMode),
      'repeatedAlarm': serializer.toJson<bool>(repeatedAlarm),
    };
  }

  AppSettingsTableData copyWith({
    int? id,
    double? defaultAlertRadius,
    String? alarmType,
    String? commuteMode,
    bool? repeatedAlarm,
  }) => AppSettingsTableData(
    id: id ?? this.id,
    defaultAlertRadius: defaultAlertRadius ?? this.defaultAlertRadius,
    alarmType: alarmType ?? this.alarmType,
    commuteMode: commuteMode ?? this.commuteMode,
    repeatedAlarm: repeatedAlarm ?? this.repeatedAlarm,
  );
  AppSettingsTableData copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      defaultAlertRadius: data.defaultAlertRadius.present
          ? data.defaultAlertRadius.value
          : this.defaultAlertRadius,
      alarmType: data.alarmType.present ? data.alarmType.value : this.alarmType,
      commuteMode: data.commuteMode.present
          ? data.commuteMode.value
          : this.commuteMode,
      repeatedAlarm: data.repeatedAlarm.present
          ? data.repeatedAlarm.value
          : this.repeatedAlarm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableData(')
          ..write('id: $id, ')
          ..write('defaultAlertRadius: $defaultAlertRadius, ')
          ..write('alarmType: $alarmType, ')
          ..write('commuteMode: $commuteMode, ')
          ..write('repeatedAlarm: $repeatedAlarm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    defaultAlertRadius,
    alarmType,
    commuteMode,
    repeatedAlarm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsTableData &&
          other.id == this.id &&
          other.defaultAlertRadius == this.defaultAlertRadius &&
          other.alarmType == this.alarmType &&
          other.commuteMode == this.commuteMode &&
          other.repeatedAlarm == this.repeatedAlarm);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingsTableData> {
  final Value<int> id;
  final Value<double> defaultAlertRadius;
  final Value<String> alarmType;
  final Value<String> commuteMode;
  final Value<bool> repeatedAlarm;
  const AppSettingsTableCompanion({
    this.id = const Value.absent(),
    this.defaultAlertRadius = const Value.absent(),
    this.alarmType = const Value.absent(),
    this.commuteMode = const Value.absent(),
    this.repeatedAlarm = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.defaultAlertRadius = const Value.absent(),
    required String alarmType,
    required String commuteMode,
    this.repeatedAlarm = const Value.absent(),
  }) : alarmType = Value(alarmType),
       commuteMode = Value(commuteMode);
  static Insertable<AppSettingsTableData> custom({
    Expression<int>? id,
    Expression<double>? defaultAlertRadius,
    Expression<String>? alarmType,
    Expression<String>? commuteMode,
    Expression<bool>? repeatedAlarm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (defaultAlertRadius != null)
        'default_alert_radius': defaultAlertRadius,
      if (alarmType != null) 'alarm_type': alarmType,
      if (commuteMode != null) 'commute_mode': commuteMode,
      if (repeatedAlarm != null) 'repeated_alarm': repeatedAlarm,
    });
  }

  AppSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<double>? defaultAlertRadius,
    Value<String>? alarmType,
    Value<String>? commuteMode,
    Value<bool>? repeatedAlarm,
  }) {
    return AppSettingsTableCompanion(
      id: id ?? this.id,
      defaultAlertRadius: defaultAlertRadius ?? this.defaultAlertRadius,
      alarmType: alarmType ?? this.alarmType,
      commuteMode: commuteMode ?? this.commuteMode,
      repeatedAlarm: repeatedAlarm ?? this.repeatedAlarm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (defaultAlertRadius.present) {
      map['default_alert_radius'] = Variable<double>(defaultAlertRadius.value);
    }
    if (alarmType.present) {
      map['alarm_type'] = Variable<String>(alarmType.value);
    }
    if (commuteMode.present) {
      map['commute_mode'] = Variable<String>(commuteMode.value);
    }
    if (repeatedAlarm.present) {
      map['repeated_alarm'] = Variable<bool>(repeatedAlarm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('defaultAlertRadius: $defaultAlertRadius, ')
          ..write('alarmType: $alarmType, ')
          ..write('commuteMode: $commuteMode, ')
          ..write('repeatedAlarm: $repeatedAlarm')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, TripsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationIdMeta = const VerificationMeta(
    'destinationId',
  );
  @override
  late final GeneratedColumn<String> destinationId = GeneratedColumn<String>(
    'destination_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationNameMeta = const VerificationMeta(
    'destinationName',
  );
  @override
  late final GeneratedColumn<String> destinationName = GeneratedColumn<String>(
    'destination_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDistanceMeta = const VerificationMeta(
    'totalDistance',
  );
  @override
  late final GeneratedColumn<double> totalDistance = GeneratedColumn<double>(
    'total_distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedRouteDistanceMeta =
      const VerificationMeta('plannedRouteDistance');
  @override
  late final GeneratedColumn<double> plannedRouteDistance =
      GeneratedColumn<double>(
        'planned_route_distance',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _plannedRouteDurationMeta =
      const VerificationMeta('plannedRouteDuration');
  @override
  late final GeneratedColumn<double> plannedRouteDuration =
      GeneratedColumn<double>(
        'planned_route_duration',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _routeCoordinatesJsonMeta =
      const VerificationMeta('routeCoordinatesJson');
  @override
  late final GeneratedColumn<String> routeCoordinatesJson =
      GeneratedColumn<String>(
        'route_coordinates_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    destinationId,
    destinationName,
    status,
    startedAt,
    endedAt,
    totalDistance,
    plannedRouteDistance,
    plannedRouteDuration,
    routeCoordinatesJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('destination_id')) {
      context.handle(
        _destinationIdMeta,
        destinationId.isAcceptableOrUnknown(
          data['destination_id']!,
          _destinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationIdMeta);
    }
    if (data.containsKey('destination_name')) {
      context.handle(
        _destinationNameMeta,
        destinationName.isAcceptableOrUnknown(
          data['destination_name']!,
          _destinationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('total_distance')) {
      context.handle(
        _totalDistanceMeta,
        totalDistance.isAcceptableOrUnknown(
          data['total_distance']!,
          _totalDistanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalDistanceMeta);
    }
    if (data.containsKey('planned_route_distance')) {
      context.handle(
        _plannedRouteDistanceMeta,
        plannedRouteDistance.isAcceptableOrUnknown(
          data['planned_route_distance']!,
          _plannedRouteDistanceMeta,
        ),
      );
    }
    if (data.containsKey('planned_route_duration')) {
      context.handle(
        _plannedRouteDurationMeta,
        plannedRouteDuration.isAcceptableOrUnknown(
          data['planned_route_duration']!,
          _plannedRouteDurationMeta,
        ),
      );
    }
    if (data.containsKey('route_coordinates_json')) {
      context.handle(
        _routeCoordinatesJsonMeta,
        routeCoordinatesJson.isAcceptableOrUnknown(
          data['route_coordinates_json']!,
          _routeCoordinatesJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      destinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_id'],
      )!,
      destinationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      totalDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_distance'],
      )!,
      plannedRouteDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}planned_route_distance'],
      ),
      plannedRouteDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}planned_route_duration'],
      ),
      routeCoordinatesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_coordinates_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class TripsRow extends DataClass implements Insertable<TripsRow> {
  final String id;
  final String destinationId;
  final String destinationName;
  final String status;
  final DateTime startedAt;
  final DateTime endedAt;
  final double totalDistance;
  final double? plannedRouteDistance;
  final double? plannedRouteDuration;
  final String? routeCoordinatesJson;
  final DateTime createdAt;
  const TripsRow({
    required this.id,
    required this.destinationId,
    required this.destinationName,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.totalDistance,
    this.plannedRouteDistance,
    this.plannedRouteDuration,
    this.routeCoordinatesJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['destination_id'] = Variable<String>(destinationId);
    map['destination_name'] = Variable<String>(destinationName);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['total_distance'] = Variable<double>(totalDistance);
    if (!nullToAbsent || plannedRouteDistance != null) {
      map['planned_route_distance'] = Variable<double>(plannedRouteDistance);
    }
    if (!nullToAbsent || plannedRouteDuration != null) {
      map['planned_route_duration'] = Variable<double>(plannedRouteDuration);
    }
    if (!nullToAbsent || routeCoordinatesJson != null) {
      map['route_coordinates_json'] = Variable<String>(routeCoordinatesJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      destinationId: Value(destinationId),
      destinationName: Value(destinationName),
      status: Value(status),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      totalDistance: Value(totalDistance),
      plannedRouteDistance: plannedRouteDistance == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedRouteDistance),
      plannedRouteDuration: plannedRouteDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedRouteDuration),
      routeCoordinatesJson: routeCoordinatesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(routeCoordinatesJson),
      createdAt: Value(createdAt),
    );
  }

  factory TripsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripsRow(
      id: serializer.fromJson<String>(json['id']),
      destinationId: serializer.fromJson<String>(json['destinationId']),
      destinationName: serializer.fromJson<String>(json['destinationName']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      totalDistance: serializer.fromJson<double>(json['totalDistance']),
      plannedRouteDistance: serializer.fromJson<double?>(
        json['plannedRouteDistance'],
      ),
      plannedRouteDuration: serializer.fromJson<double?>(
        json['plannedRouteDuration'],
      ),
      routeCoordinatesJson: serializer.fromJson<String?>(
        json['routeCoordinatesJson'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'destinationId': serializer.toJson<String>(destinationId),
      'destinationName': serializer.toJson<String>(destinationName),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'totalDistance': serializer.toJson<double>(totalDistance),
      'plannedRouteDistance': serializer.toJson<double?>(plannedRouteDistance),
      'plannedRouteDuration': serializer.toJson<double?>(plannedRouteDuration),
      'routeCoordinatesJson': serializer.toJson<String?>(routeCoordinatesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TripsRow copyWith({
    String? id,
    String? destinationId,
    String? destinationName,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    double? totalDistance,
    Value<double?> plannedRouteDistance = const Value.absent(),
    Value<double?> plannedRouteDuration = const Value.absent(),
    Value<String?> routeCoordinatesJson = const Value.absent(),
    DateTime? createdAt,
  }) => TripsRow(
    id: id ?? this.id,
    destinationId: destinationId ?? this.destinationId,
    destinationName: destinationName ?? this.destinationName,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    totalDistance: totalDistance ?? this.totalDistance,
    plannedRouteDistance: plannedRouteDistance.present
        ? plannedRouteDistance.value
        : this.plannedRouteDistance,
    plannedRouteDuration: plannedRouteDuration.present
        ? plannedRouteDuration.value
        : this.plannedRouteDuration,
    routeCoordinatesJson: routeCoordinatesJson.present
        ? routeCoordinatesJson.value
        : this.routeCoordinatesJson,
    createdAt: createdAt ?? this.createdAt,
  );
  TripsRow copyWithCompanion(TripsCompanion data) {
    return TripsRow(
      id: data.id.present ? data.id.value : this.id,
      destinationId: data.destinationId.present
          ? data.destinationId.value
          : this.destinationId,
      destinationName: data.destinationName.present
          ? data.destinationName.value
          : this.destinationName,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      totalDistance: data.totalDistance.present
          ? data.totalDistance.value
          : this.totalDistance,
      plannedRouteDistance: data.plannedRouteDistance.present
          ? data.plannedRouteDistance.value
          : this.plannedRouteDistance,
      plannedRouteDuration: data.plannedRouteDuration.present
          ? data.plannedRouteDuration.value
          : this.plannedRouteDuration,
      routeCoordinatesJson: data.routeCoordinatesJson.present
          ? data.routeCoordinatesJson.value
          : this.routeCoordinatesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripsRow(')
          ..write('id: $id, ')
          ..write('destinationId: $destinationId, ')
          ..write('destinationName: $destinationName, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('plannedRouteDistance: $plannedRouteDistance, ')
          ..write('plannedRouteDuration: $plannedRouteDuration, ')
          ..write('routeCoordinatesJson: $routeCoordinatesJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    destinationId,
    destinationName,
    status,
    startedAt,
    endedAt,
    totalDistance,
    plannedRouteDistance,
    plannedRouteDuration,
    routeCoordinatesJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripsRow &&
          other.id == this.id &&
          other.destinationId == this.destinationId &&
          other.destinationName == this.destinationName &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.totalDistance == this.totalDistance &&
          other.plannedRouteDistance == this.plannedRouteDistance &&
          other.plannedRouteDuration == this.plannedRouteDuration &&
          other.routeCoordinatesJson == this.routeCoordinatesJson &&
          other.createdAt == this.createdAt);
}

class TripsCompanion extends UpdateCompanion<TripsRow> {
  final Value<String> id;
  final Value<String> destinationId;
  final Value<String> destinationName;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<double> totalDistance;
  final Value<double?> plannedRouteDistance;
  final Value<double?> plannedRouteDuration;
  final Value<String?> routeCoordinatesJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.destinationId = const Value.absent(),
    this.destinationName = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.totalDistance = const Value.absent(),
    this.plannedRouteDistance = const Value.absent(),
    this.plannedRouteDuration = const Value.absent(),
    this.routeCoordinatesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripsCompanion.insert({
    required String id,
    required String destinationId,
    required String destinationName,
    required String status,
    required DateTime startedAt,
    required DateTime endedAt,
    required double totalDistance,
    this.plannedRouteDistance = const Value.absent(),
    this.plannedRouteDuration = const Value.absent(),
    this.routeCoordinatesJson = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       destinationId = Value(destinationId),
       destinationName = Value(destinationName),
       status = Value(status),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       totalDistance = Value(totalDistance),
       createdAt = Value(createdAt);
  static Insertable<TripsRow> custom({
    Expression<String>? id,
    Expression<String>? destinationId,
    Expression<String>? destinationName,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? totalDistance,
    Expression<double>? plannedRouteDistance,
    Expression<double>? plannedRouteDuration,
    Expression<String>? routeCoordinatesJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (destinationId != null) 'destination_id': destinationId,
      if (destinationName != null) 'destination_name': destinationName,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (totalDistance != null) 'total_distance': totalDistance,
      if (plannedRouteDistance != null)
        'planned_route_distance': plannedRouteDistance,
      if (plannedRouteDuration != null)
        'planned_route_duration': plannedRouteDuration,
      if (routeCoordinatesJson != null)
        'route_coordinates_json': routeCoordinatesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripsCompanion copyWith({
    Value<String>? id,
    Value<String>? destinationId,
    Value<String>? destinationName,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<double>? totalDistance,
    Value<double?>? plannedRouteDistance,
    Value<double?>? plannedRouteDuration,
    Value<String?>? routeCoordinatesJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      totalDistance: totalDistance ?? this.totalDistance,
      plannedRouteDistance: plannedRouteDistance ?? this.plannedRouteDistance,
      plannedRouteDuration: plannedRouteDuration ?? this.plannedRouteDuration,
      routeCoordinatesJson: routeCoordinatesJson ?? this.routeCoordinatesJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (destinationId.present) {
      map['destination_id'] = Variable<String>(destinationId.value);
    }
    if (destinationName.present) {
      map['destination_name'] = Variable<String>(destinationName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (totalDistance.present) {
      map['total_distance'] = Variable<double>(totalDistance.value);
    }
    if (plannedRouteDistance.present) {
      map['planned_route_distance'] = Variable<double>(
        plannedRouteDistance.value,
      );
    }
    if (plannedRouteDuration.present) {
      map['planned_route_duration'] = Variable<double>(
        plannedRouteDuration.value,
      );
    }
    if (routeCoordinatesJson.present) {
      map['route_coordinates_json'] = Variable<String>(
        routeCoordinatesJson.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('destinationId: $destinationId, ')
          ..write('destinationName: $destinationName, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('plannedRouteDistance: $plannedRouteDistance, ')
          ..write('plannedRouteDuration: $plannedRouteDuration, ')
          ..write('routeCoordinatesJson: $routeCoordinatesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $DestinationsTable destinations = $DestinationsTable(this);
  late final $AppSettingsTableTable appSettingsTable = $AppSettingsTableTable(
    this,
  );
  late final $TripsTable trips = $TripsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    destinations,
    appSettingsTable,
    trips,
  ];
}

typedef $$DestinationsTableCreateCompanionBuilder =
    DestinationsCompanion Function({
      required String id,
      required String name,
      required double latitude,
      required double longitude,
      Value<double> alertRadius,
      Value<bool> isFavorite,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DestinationsTableUpdateCompanionBuilder =
    DestinationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> alertRadius,
      Value<bool> isFavorite,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DestinationsTableFilterComposer
    extends Composer<_$LocalDatabase, $DestinationsTable> {
  $$DestinationsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alertRadius => $composableBuilder(
    column: $table.alertRadius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DestinationsTableOrderingComposer
    extends Composer<_$LocalDatabase, $DestinationsTable> {
  $$DestinationsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alertRadius => $composableBuilder(
    column: $table.alertRadius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DestinationsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $DestinationsTable> {
  $$DestinationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get alertRadius => $composableBuilder(
    column: $table.alertRadius,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DestinationsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $DestinationsTable,
          DestinationsRow,
          $$DestinationsTableFilterComposer,
          $$DestinationsTableOrderingComposer,
          $$DestinationsTableAnnotationComposer,
          $$DestinationsTableCreateCompanionBuilder,
          $$DestinationsTableUpdateCompanionBuilder,
          (
            DestinationsRow,
            BaseReferences<
              _$LocalDatabase,
              $DestinationsTable,
              DestinationsRow
            >,
          ),
          DestinationsRow,
          PrefetchHooks Function()
        > {
  $$DestinationsTableTableManager(_$LocalDatabase db, $DestinationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DestinationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DestinationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DestinationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> alertRadius = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DestinationsCompanion(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                alertRadius: alertRadius,
                isFavorite: isFavorite,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double latitude,
                required double longitude,
                Value<double> alertRadius = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DestinationsCompanion.insert(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                alertRadius: alertRadius,
                isFavorite: isFavorite,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DestinationsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $DestinationsTable,
      DestinationsRow,
      $$DestinationsTableFilterComposer,
      $$DestinationsTableOrderingComposer,
      $$DestinationsTableAnnotationComposer,
      $$DestinationsTableCreateCompanionBuilder,
      $$DestinationsTableUpdateCompanionBuilder,
      (
        DestinationsRow,
        BaseReferences<_$LocalDatabase, $DestinationsTable, DestinationsRow>,
      ),
      DestinationsRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableTableCreateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<int> id,
      Value<double> defaultAlertRadius,
      required String alarmType,
      required String commuteMode,
      Value<bool> repeatedAlarm,
    });
typedef $$AppSettingsTableTableUpdateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<int> id,
      Value<double> defaultAlertRadius,
      Value<String> alarmType,
      Value<String> commuteMode,
      Value<bool> repeatedAlarm,
    });

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$LocalDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultAlertRadius => $composableBuilder(
    column: $table.defaultAlertRadius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmType => $composableBuilder(
    column: $table.alarmType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commuteMode => $composableBuilder(
    column: $table.commuteMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get repeatedAlarm => $composableBuilder(
    column: $table.repeatedAlarm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultAlertRadius => $composableBuilder(
    column: $table.defaultAlertRadius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmType => $composableBuilder(
    column: $table.alarmType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commuteMode => $composableBuilder(
    column: $table.commuteMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get repeatedAlarm => $composableBuilder(
    column: $table.repeatedAlarm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get defaultAlertRadius => $composableBuilder(
    column: $table.defaultAlertRadius,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alarmType =>
      $composableBuilder(column: $table.alarmType, builder: (column) => column);

  GeneratedColumn<String> get commuteMode => $composableBuilder(
    column: $table.commuteMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get repeatedAlarm => $composableBuilder(
    column: $table.repeatedAlarm,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $AppSettingsTableTable,
          AppSettingsTableData,
          $$AppSettingsTableTableFilterComposer,
          $$AppSettingsTableTableOrderingComposer,
          $$AppSettingsTableTableAnnotationComposer,
          $$AppSettingsTableTableCreateCompanionBuilder,
          $$AppSettingsTableTableUpdateCompanionBuilder,
          (
            AppSettingsTableData,
            BaseReferences<
              _$LocalDatabase,
              $AppSettingsTableTable,
              AppSettingsTableData
            >,
          ),
          AppSettingsTableData,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableTableManager(
    _$LocalDatabase db,
    $AppSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> defaultAlertRadius = const Value.absent(),
                Value<String> alarmType = const Value.absent(),
                Value<String> commuteMode = const Value.absent(),
                Value<bool> repeatedAlarm = const Value.absent(),
              }) => AppSettingsTableCompanion(
                id: id,
                defaultAlertRadius: defaultAlertRadius,
                alarmType: alarmType,
                commuteMode: commuteMode,
                repeatedAlarm: repeatedAlarm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> defaultAlertRadius = const Value.absent(),
                required String alarmType,
                required String commuteMode,
                Value<bool> repeatedAlarm = const Value.absent(),
              }) => AppSettingsTableCompanion.insert(
                id: id,
                defaultAlertRadius: defaultAlertRadius,
                alarmType: alarmType,
                commuteMode: commuteMode,
                repeatedAlarm: repeatedAlarm,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $AppSettingsTableTable,
      AppSettingsTableData,
      $$AppSettingsTableTableFilterComposer,
      $$AppSettingsTableTableOrderingComposer,
      $$AppSettingsTableTableAnnotationComposer,
      $$AppSettingsTableTableCreateCompanionBuilder,
      $$AppSettingsTableTableUpdateCompanionBuilder,
      (
        AppSettingsTableData,
        BaseReferences<
          _$LocalDatabase,
          $AppSettingsTableTable,
          AppSettingsTableData
        >,
      ),
      AppSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      required String id,
      required String destinationId,
      required String destinationName,
      required String status,
      required DateTime startedAt,
      required DateTime endedAt,
      required double totalDistance,
      Value<double?> plannedRouteDistance,
      Value<double?> plannedRouteDuration,
      Value<String?> routeCoordinatesJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<String> id,
      Value<String> destinationId,
      Value<String> destinationName,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<double> totalDistance,
      Value<double?> plannedRouteDistance,
      Value<double?> plannedRouteDuration,
      Value<String?> routeCoordinatesJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TripsTableFilterComposer
    extends Composer<_$LocalDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
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

  ColumnFilters<String> get destinationId => $composableBuilder(
    column: $table.destinationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationName => $composableBuilder(
    column: $table.destinationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get plannedRouteDistance => $composableBuilder(
    column: $table.plannedRouteDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get plannedRouteDuration => $composableBuilder(
    column: $table.plannedRouteDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeCoordinatesJson => $composableBuilder(
    column: $table.routeCoordinatesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TripsTableOrderingComposer
    extends Composer<_$LocalDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
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

  ColumnOrderings<String> get destinationId => $composableBuilder(
    column: $table.destinationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationName => $composableBuilder(
    column: $table.destinationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get plannedRouteDistance => $composableBuilder(
    column: $table.plannedRouteDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get plannedRouteDuration => $composableBuilder(
    column: $table.plannedRouteDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeCoordinatesJson => $composableBuilder(
    column: $table.routeCoordinatesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get destinationId => $composableBuilder(
    column: $table.destinationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationName => $composableBuilder(
    column: $table.destinationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get plannedRouteDistance => $composableBuilder(
    column: $table.plannedRouteDistance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get plannedRouteDuration => $composableBuilder(
    column: $table.plannedRouteDuration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routeCoordinatesJson => $composableBuilder(
    column: $table.routeCoordinatesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $TripsTable,
          TripsRow,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (TripsRow, BaseReferences<_$LocalDatabase, $TripsTable, TripsRow>),
          TripsRow,
          PrefetchHooks Function()
        > {
  $$TripsTableTableManager(_$LocalDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> destinationId = const Value.absent(),
                Value<String> destinationName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<double> totalDistance = const Value.absent(),
                Value<double?> plannedRouteDistance = const Value.absent(),
                Value<double?> plannedRouteDuration = const Value.absent(),
                Value<String?> routeCoordinatesJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                destinationId: destinationId,
                destinationName: destinationName,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                totalDistance: totalDistance,
                plannedRouteDistance: plannedRouteDistance,
                plannedRouteDuration: plannedRouteDuration,
                routeCoordinatesJson: routeCoordinatesJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String destinationId,
                required String destinationName,
                required String status,
                required DateTime startedAt,
                required DateTime endedAt,
                required double totalDistance,
                Value<double?> plannedRouteDistance = const Value.absent(),
                Value<double?> plannedRouteDuration = const Value.absent(),
                Value<String?> routeCoordinatesJson = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                destinationId: destinationId,
                destinationName: destinationName,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                totalDistance: totalDistance,
                plannedRouteDistance: plannedRouteDistance,
                plannedRouteDuration: plannedRouteDuration,
                routeCoordinatesJson: routeCoordinatesJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $TripsTable,
      TripsRow,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (TripsRow, BaseReferences<_$LocalDatabase, $TripsTable, TripsRow>),
      TripsRow,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$DestinationsTableTableManager get destinations =>
      $$DestinationsTableTableManager(_db, _db.destinations);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
}
