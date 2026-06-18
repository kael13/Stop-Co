import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/route_result.dart';

class RoutingService {
  final http.Client _client;
  static const int _timeoutSeconds = 5;

  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  Future<RouteResult?> fetchRoute(LatLng from, LatLng to) async {
    final url = _buildUrl(from, to);
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: _timeoutSeconds));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List;
      if (routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final distance = (route['distance'] as num).toDouble();
      final duration = (route['duration'] as num).toDouble();

      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List;
      final coordinates = coords.map((c) {
        final lon = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();

      return RouteResult(
        distanceMeters: distance,
        durationSeconds: duration,
        coordinates: coordinates,
      );
    } catch (_) {
      return null;
    }
  }

  String _buildUrl(LatLng from, LatLng to) {
    return '${AppConstants.osrmBaseUrl}/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson';
  }

  void dispose() {
    _client.close();
  }
}

final routingServiceProvider = Provider<RoutingService>((ref) {
  final service = RoutingService();
  ref.onDispose(() => service.dispose());
  return service;
});
