import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'trip_model.dart';

class TripRecord {
  final String id;
  final String destinationId;
  final String destinationName;
  final TripStatus status;
  final DateTime startedAt;
  final DateTime endedAt;
  final double totalDistance;
  final double? plannedRouteDistance;
  final double? plannedRouteDuration;
  final String? routeCoordinatesJson;
  final String? gpsBreadcrumbsJson;
  final DateTime createdAt;

  const TripRecord({
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
    this.gpsBreadcrumbsJson,
    required this.createdAt,
  });

  List<LatLng> get routeCoordinates => _deserializeCoordinates(routeCoordinatesJson);

  List<LatLng> get gpsBreadcrumbs => _deserializeCoordinates(gpsBreadcrumbsJson);

  Duration get duration => endedAt.difference(startedAt);

  static String? serializeCoordinates(List<LatLng>? coordinates) {
    if (coordinates == null || coordinates.isEmpty) return null;
    final list = coordinates
        .map((c) => [c.latitude, c.longitude])
        .toList();
    return jsonEncode(list);
  }

  static List<LatLng> _deserializeCoordinates(String? json) {
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((item) => LatLng(
              (item as List<dynamic>)[0] as double,
              item[1] as double,
            ))
        .toList();
  }
}
