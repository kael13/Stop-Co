import 'package:latlong2/latlong.dart';

class RouteResult {
  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> coordinates;

  const RouteResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.coordinates,
  });
}
