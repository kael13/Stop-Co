import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/destination/data/destination_model.dart';
import '../../features/settings/data/settings_providers.dart';
import '../../features/trip/data/trip_record.dart';
import '../../features/trip/data/trip_model.dart';

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
  BoolColumn get napModeEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get customAlarmSoundPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TripsRow')
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get destinationId => text()();
  TextColumn get destinationName => text()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  RealColumn get totalDistance => real()();
  RealColumn get plannedRouteDistance => real().nullable()();
  RealColumn get plannedRouteDuration => real().nullable()();
  TextColumn get routeCoordinatesJson => text().nullable()();
  TextColumn get gpsBreadcrumbsJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Destinations, AppSettingsTable, Trips])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(trips);
      }
      if (from < 3) {
        await migrator.addColumn(
            appSettingsTable, appSettingsTable.napModeEnabled);
        await migrator.addColumn(
            appSettingsTable, appSettingsTable.customAlarmSoundPath);
      }
      if (from < 4) {
        await migrator.addColumn(trips, trips.gpsBreadcrumbsJson);
      }
    },
  );

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
      napModeEnabled: row.napModeEnabled,
      customAlarmSoundPath: row.customAlarmSoundPath,
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
        napModeEnabled: Value(settings.napModeEnabled),
        customAlarmSoundPath:
            Value.absentIfNull(settings.customAlarmSoundPath),
      ),
      mode: InsertMode.replace,
    );
  }

  // ---------------------------------------------------------------------------
  // Trips DAO
  // ---------------------------------------------------------------------------

  Stream<List<TripRecord>> watchRecentTrips({int limit = 10}) {
    return (select(trips)
          ..orderBy([(t) => OrderingTerm(
              expression: t.startedAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map(_toTripRecord).toList());
  }

  Future<List<TripRecord>> getRecentTrips({int limit = 10}) async {
    final rows = await (select(trips)
          ..orderBy([(t) => OrderingTerm(
              expression: t.startedAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
    return rows.map(_toTripRecord).toList();
  }

  Future<void> saveTrip(TripRecord trip) {
    return into(trips).insert(TripsCompanion(
      id: Value(trip.id),
      destinationId: Value(trip.destinationId),
      destinationName: Value(trip.destinationName),
      status: Value(trip.status.name),
      startedAt: Value(trip.startedAt),
      endedAt: Value(trip.endedAt),
      totalDistance: Value(trip.totalDistance),
      plannedRouteDistance: Value.absentIfNull(trip.plannedRouteDistance),
      plannedRouteDuration: Value.absentIfNull(trip.plannedRouteDuration),
      routeCoordinatesJson: Value.absentIfNull(trip.routeCoordinatesJson),
      gpsBreadcrumbsJson: Value.absentIfNull(trip.gpsBreadcrumbsJson),
      createdAt: Value(trip.createdAt),
    ));
  }

  Future<void> deleteTrip(String id) {
    return (delete(trips)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteAllTrips() {
    return delete(trips).go();
  }

  TripRecord _toTripRecord(TripsRow row) {
    return TripRecord(
      id: row.id,
      destinationId: row.destinationId,
      destinationName: row.destinationName,
      status: TripStatus.values.firstWhere((s) => s.name == row.status),
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      totalDistance: row.totalDistance,
      plannedRouteDistance: row.plannedRouteDistance,
      plannedRouteDuration: row.plannedRouteDuration,
      routeCoordinatesJson: row.routeCoordinatesJson,
      gpsBreadcrumbsJson: row.gpsBreadcrumbsJson,
      createdAt: row.createdAt,
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
