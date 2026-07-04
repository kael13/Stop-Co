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

  const ActiveTrip({
    required this.waypoints,
    this.currentWaypointIndex = 0,
    this.status = TripStatus.monitoring,
    required this.startedAt,
    this.currentDistance,
    this.hasAlerted = false,
    this.routeResult,
    this.gpsBreadcrumbs = const [],
  });

  Waypoint get currentWaypoint => waypoints[currentWaypointIndex];

  bool get hasMultipleStops => waypoints.length > 1;

  int get totalStops => waypoints.length;

  ActiveTrip copyWith({
    List<Waypoint>? waypoints,
    int? currentWaypointIndex,
    TripStatus? status,
    DateTime? startedAt,
    double? currentDistance,
    bool? hasAlerted,
    RouteResult? routeResult,
    List<LatLng>? gpsBreadcrumbs,
  }) {
    return ActiveTrip(
      waypoints: waypoints ?? this.waypoints,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      currentDistance: currentDistance ?? this.currentDistance,
      hasAlerted: hasAlerted ?? this.hasAlerted,
      routeResult: routeResult ?? this.routeResult,
      gpsBreadcrumbs: gpsBreadcrumbs ?? this.gpsBreadcrumbs,
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
