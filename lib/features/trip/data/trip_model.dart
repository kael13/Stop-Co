import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart';
import '../domain/route_result.dart';
import 'waypoint.dart';

enum TripStatus { monitoring, alarmTriggered, cancelled, completed }

class ActiveTrip {
  final List<Waypoint> waypoints;
  final int currentWaypointIndex;
  final TripStatus status;
  final DateTime startedAt;
  final double? currentDistance;
  final bool hasAlerted;
  final RouteResult? routeResult;
  final List<LatLng> gpsBreadcrumbs;
  final int napSnoozeRemaining;

  const ActiveTrip({
    required this.waypoints,
    this.currentWaypointIndex = 0,
    this.status = TripStatus.monitoring,
    required this.startedAt,
    this.currentDistance,
    this.hasAlerted = false,
    this.routeResult,
    this.gpsBreadcrumbs = const [],
    this.napSnoozeRemaining = 3,
  });

  Waypoint get currentWaypoint => waypoints[currentWaypointIndex];

  bool get hasMultipleStops => waypoints.length > 1;

  int get totalStops => waypoints.length;

  static const _sentinel = Object();

  ActiveTrip copyWith({
    List<Waypoint>? waypoints,
    int? currentWaypointIndex,
    TripStatus? status,
    DateTime? startedAt,
    Object? currentDistance = _sentinel,
    bool? hasAlerted,
    Object? routeResult = _sentinel,
    List<LatLng>? gpsBreadcrumbs,
    int? napSnoozeRemaining,
  }) {
    return ActiveTrip(
      waypoints: waypoints ?? this.waypoints,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      currentDistance: currentDistance == _sentinel
          ? this.currentDistance
          : currentDistance as double?,
      hasAlerted: hasAlerted ?? this.hasAlerted,
      routeResult: routeResult == _sentinel
          ? this.routeResult
          : routeResult as RouteResult?,
      gpsBreadcrumbs: gpsBreadcrumbs ?? this.gpsBreadcrumbs,
      napSnoozeRemaining: napSnoozeRemaining ?? this.napSnoozeRemaining,
    );
  }

  bool get isActive => status == TripStatus.monitoring && !hasAlerted;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveTrip &&
        const DeepCollectionEquality()
            .equals(other.waypoints.map((w) => w.id).toList(), waypoints.map((w) => w.id).toList()) &&
        other.currentWaypointIndex == currentWaypointIndex &&
        other.status == status &&
        other.hasAlerted == hasAlerted &&
        const DeepCollectionEquality()
            .equals(other.currentDistance, currentDistance);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(waypoints.map((w) => w.id)),
    currentWaypointIndex,
    status,
    hasAlerted,
  );
}
