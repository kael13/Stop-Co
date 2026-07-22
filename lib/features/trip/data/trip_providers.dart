import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../destination/data/destination_model.dart';
import '../../settings/data/settings_providers.dart';
import '../domain/route_result.dart';
import 'alarm_notification_service.dart';
import 'trip_model.dart';
import 'trip_record.dart';
import 'trip_repository.dart';
import 'waypoint.dart';

const _uuid = Uuid();

final activeTripProvider = StateNotifierProvider<ActiveTripNotifier, ActiveTrip?>((ref) {
  return ActiveTripNotifier(ref);
});

class ActiveTripNotifier extends StateNotifier<ActiveTrip?> {
  final Ref _ref;

  ActiveTripNotifier(this._ref) : super(null);

  void startTrip(Destination destination) {
    final waypoint = Waypoint.fromDestination(destination, 0);
    state = ActiveTrip(
      waypoints: [waypoint],
      startedAt: DateTime.now(),
    );
  }

  void startTripWithWaypoints(List<Waypoint> waypoints) {
    state = ActiveTrip(
      waypoints: waypoints,
      startedAt: DateTime.now(),
    );
  }

  void updateDistance(double distance) {
    if (state == null) return;
    state = state!.copyWith(currentDistance: distance);
  }

  void setRouteResult(RouteResult route) {
    if (state == null) return;
    state = state!.copyWith(routeResult: route);
  }

  void addBreadcrumb(LatLng point) {
    if (state == null) return;
    state = state!.copyWith(
      gpsBreadcrumbs: [...state!.gpsBreadcrumbs, point],
    );
  }

  void triggerAlarm() {
    if (state == null) return;
    if (state!.hasAlerted) return;
    state = state!.copyWith(
      status: TripStatus.alarmTriggered,
      hasAlerted: true,
    );
    _ref.read(alarmNotifierProvider).showAlarmNotification(
      destinationName: state!.currentWaypoint.name,
      distance: state!.currentDistance ?? 0,
      alarmType: _ref.read(settingsProvider).alarmType,
    );
  }

  void advanceToNextWaypoint() {
    if (state == null) return;
    final nextIndex = state!.currentWaypointIndex + 1;
    if (nextIndex >= state!.waypoints.length) {
      completeTrip();
      return;
    }
    state = state!.copyWith(
      currentWaypointIndex: nextIndex,
      status: TripStatus.monitoring,
      hasAlerted: false,
      routeResult: null,
      currentDistance: null,
    );
  }

  void cancelTrip() {
    _persistTrip(TripStatus.cancelled);
    state = null;
    _ref.read(alarmNotifierProvider).dismissAlarm();
  }

  void completeTrip() {
    _persistTrip(TripStatus.completed);
    _ref.read(alarmNotifierProvider).dismissAlarm();
    if (state != null) {
      state = state!.copyWith(status: TripStatus.completed, hasAlerted: true);
    }
  }

  void clearTrip() {
    state = null;
  }

  void _persistTrip(TripStatus finalStatus) {
    final trip = state;
    if (trip == null) return;
    final repo = _ref.read(tripRepositoryProvider);
    repo.save(TripRecord(
      id: _uuid.v4(),
      destinationId: trip.waypoints.first.id,
      destinationName: trip.waypoints.first.name,
      status: finalStatus,
      startedAt: trip.startedAt,
      endedAt: DateTime.now(),
      totalDistance: trip.currentDistance ?? 0,
      plannedRouteDistance: trip.routeResult?.distanceMeters,
      plannedRouteDuration: trip.routeResult?.durationSeconds,
      routeCoordinatesJson:
          TripRecord.serializeCoordinates(trip.routeResult?.coordinates),
      gpsBreadcrumbsJson:
          TripRecord.serializeCoordinates(trip.gpsBreadcrumbs),
      waypointsJson: trip.hasMultipleStops
          ? Waypoint.serializeList(trip.waypoints)
          : null,
      createdAt: DateTime.now(),
    ));
  }
}

final recentTripsProvider = StreamProvider<List<TripRecord>>((ref) {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchRecent(limit: 10);
});
