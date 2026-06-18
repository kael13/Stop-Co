import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/destination/data/destination_model.dart';
import '../../features/settings/data/settings_providers.dart';

part 'database.g.dart';

@DataClassName('DestinationsRow')
class Destinations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get alertRadius => real().withDefault(const Constant(300))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettingsTable extends Table {
  IntColumn get id => integer()();
  RealColumn get defaultAlertRadius =>
      real().withDefault(const Constant(300))();
  TextColumn get alarmType => text()();
  TextColumn get commuteMode => text()();
  BoolColumn get repeatedAlarm =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Destinations, AppSettingsTable])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------------------
  // Destinations DAO
  // ---------------------------------------------------------------------------

  Stream<List<Destination>> watchAllDestinations() {
    return (select(destinations)
          ..orderBy([(t) => OrderingTerm(
              expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch()
        .map((rows) => rows.map(_toDestination).toList());
  }

  Future<List<Destination>> getAllDestinations() async {
    final rows = await (select(destinations)
          ..orderBy([(t) => OrderingTerm(
              expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
    return rows.map(_toDestination).toList();
  }

  Future<void> saveDestination(Destination destination) {
    return into(destinations).insert(DestinationsCompanion(
      id: Value(destination.id),
      name: Value(destination.name),
      latitude: Value(destination.latitude),
      longitude: Value(destination.longitude),
      alertRadius: Value(destination.alertRadius),
      isFavorite: Value(destination.isFavorite),
      createdAt: Value(destination.createdAt),
    ));
  }

  Future<void> updateDestination(Destination destination) {
    return update(destinations).replace(DestinationsCompanion(
      id: Value(destination.id),
      name: Value(destination.name),
      latitude: Value(destination.latitude),
      longitude: Value(destination.longitude),
      alertRadius: Value(destination.alertRadius),
      isFavorite: Value(destination.isFavorite),
      createdAt: Value(destination.createdAt),
    ));
  }

  Future<void> deleteDestination(String id) {
    return (delete(destinations)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteAllDestinations() {
    return delete(destinations).go();
  }

  Destination _toDestination(DestinationsRow row) {
    return Destination(
      id: row.id,
      name: row.name,
      latitude: row.latitude,
      longitude: row.longitude,
      alertRadius: row.alertRadius,
      isFavorite: row.isFavorite,
      createdAt: row.createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // AppSettings DAO
  // ---------------------------------------------------------------------------

  Future<AppSettings?> getAppSettings() async {
    final rows = await select(appSettingsTable).get();
    if (rows.isEmpty) return null;
    final row = rows.first;
    return AppSettings(
      defaultAlertRadius: row.defaultAlertRadius,
      alarmType:
          AlarmType.values.firstWhere((e) => e.name == row.alarmType),
      commuteMode:
          CommuteMode.values.firstWhere((e) => e.name == row.commuteMode),
      repeatedAlarm: row.repeatedAlarm,
    );
  }

  Future<void> saveAppSettings(AppSettings settings) {
    return into(appSettingsTable).insert(
      AppSettingsTableCompanion(
        id: const Value(1),
        defaultAlertRadius: Value(settings.defaultAlertRadius),
        alarmType: Value(settings.alarmType.name),
        commuteMode: Value(settings.commuteMode.name),
        repeatedAlarm: Value(settings.repeatedAlarm),
      ),
      mode: InsertMode.replace,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'stop_co.db'));
    return NativeDatabase(file);
  });
}
