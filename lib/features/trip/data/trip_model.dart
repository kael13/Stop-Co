import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart';
import '../../destination/data/destination_model.dart';
import '../domain/route_result.dart';

enum TripStatus { monitoring, alarmTriggered, cancelled, completed }

class ActiveTrip {
  final Destination destination;
  final TripStatus status;
  final DateTime startedAt;
  final double? currentDistance;
  final bool hasAlerted;
  final RouteResult? routeResult;
  final List<LatLng> gpsBreadcrumbs;

  const ActiveTrip({
    required this.destination,
    this.status = TripStatus.monitoring,
    required this.startedAt,
    this.currentDistance,
    this.hasAlerted = false,
    this.routeResult,
    this.gpsBreadcrumbs = const [],
  });

  ActiveTrip copyWith({
    Destination? destination,
    TripStatus? status,
    DateTime? startedAt,
    double? currentDistance,
    bool? hasAlerted,
    RouteResult? routeResult,
    List<LatLng>? gpsBreadcrumbs,
  }) {
    return ActiveTrip(
      destination: destination ?? this.destination,
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
        other.destination.id == destination.id &&
        other.status == status &&
        other.hasAlerted == hasAlerted &&
        const DeepCollectionEquality()
            .equals(other.currentDistance, currentDistance);
  }

  @override
  int get hashCode => Object.hash(destination.id, status, hasAlerted);
}
