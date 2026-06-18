import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/utils/gps_utils.dart';
import '../../destination/data/destination_model.dart';

class SimulatedPosition {
  final double latitude;
  final double longitude;
  final double accuracy;

  const SimulatedPosition({
    required this.latitude,
    required this.longitude,
    this.accuracy = 10,
  });
}

class SimulationService {
  Timer? _timer;
  SimulatedPosition? _currentPosition;
  Destination? _destination;
  double _speedMps = 1.4;
  bool _isRunning = false;

  List<LatLng>? _routeCoordinates;
  List<double> _cumulativeDistances = [];
  double _totalRouteDistance = 0;
  double _distanceTraveled = 0;
  int _currentSegIndex = 0;

  bool get isRunning => _isRunning;
  SimulatedPosition? get currentPosition => _currentPosition;
  double get speedMps => _speedMps;

  void start({
    required Destination destination,
    required double startLatitude,
    required double startLongitude,
    required double speedMps,
    List<LatLng>? routeCoordinates,
  }) {
    stop();
    _destination = destination;
    _speedMps = speedMps;
    _currentPosition = SimulatedPosition(
      latitude: startLatitude,
      longitude: startLongitude,
    );

    if (routeCoordinates != null && routeCoordinates.length >= 2) {
      _routeCoordinates = routeCoordinates;
      _cumulativeDistances = _buildCumulativeDistances(routeCoordinates);
      _totalRouteDistance = _cumulativeDistances.last;
      _distanceTraveled = 0;
      _currentSegIndex = 0;
    } else {
      _routeCoordinates = null;
      _cumulativeDistances = [];
      _totalRouteDistance = 0;
      _distanceTraveled = 0;
      _currentSegIndex = 0;
    }

    _isRunning = true;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
    _tick();
  }

  void setSpeed(double speedMps) {
    _speedMps = speedMps;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _destination = null;
    _currentPosition = null;
    _routeCoordinates = null;
    _cumulativeDistances = [];
    _totalRouteDistance = 0;
    _distanceTraveled = 0;
    _currentSegIndex = 0;
  }

  void _tick() {
    if (_destination == null || _currentPosition == null) return;

    if (_routeCoordinates != null && _routeCoordinates!.length >= 2) {
      _tickAlongRoute();
    } else {
      _tickStraightLine();
    }
  }

  void _tickStraightLine() {
    final destLat = _destination!.latitude;
    final destLon = _destination!.longitude;
    final curLat = _currentPosition!.latitude;
    final curLon = _currentPosition!.longitude;

    final dLat = destLat - curLat;
    final dLon = destLon - curLon;
    final distance = sqrt(dLat * dLat + dLon * dLon);

    if (distance < 0.00001) {
      _currentPosition = SimulatedPosition(
        latitude: destLat,
        longitude: destLon,
      );
      return;
    }

    const double metersPerDegree = 111320;
    final stepDegrees = (_speedMps / metersPerDegree);

    final ratio = stepDegrees / distance;
    final newLat = curLat + dLat * ratio;
    final newLon = curLon + dLon * ratio;

    _currentPosition = SimulatedPosition(
      latitude: newLat,
      longitude: newLon,
    );
  }

  void _tickAlongRoute() {
    final coords = _routeCoordinates!;
    _distanceTraveled += _speedMps;

    if (_distanceTraveled >= _totalRouteDistance) {
      _currentPosition = SimulatedPosition(
        latitude: _destination!.latitude,
        longitude: _destination!.longitude,
      );
      return;
    }

    while (_currentSegIndex < _cumulativeDistances.length - 2 &&
        _distanceTraveled >= _cumulativeDistances[_currentSegIndex + 1]) {
      _currentSegIndex++;
    }

    final segStart = _cumulativeDistances[_currentSegIndex];
    final segEnd = _cumulativeDistances[_currentSegIndex + 1];
    final segLen = segEnd - segStart;
    final t = segLen > 0
        ? (_distanceTraveled - segStart) / segLen
        : 0.0;

    final cur = coords[_currentSegIndex];
    final next = coords[_currentSegIndex + 1];
    final newLat = cur.latitude + (next.latitude - cur.latitude) * t;
    final newLon = cur.longitude + (next.longitude - cur.longitude) * t;

    _currentPosition = SimulatedPosition(
      latitude: newLat,
      longitude: newLon,
    );
  }

  List<double> _buildCumulativeDistances(List<LatLng> coords) {
    final distances = <double>[0];
    for (int i = 1; i < coords.length; i++) {
      final d = GpsUtils.calculateDistance(
        coords[i - 1].latitude, coords[i - 1].longitude,
        coords[i].latitude, coords[i].longitude,
      );
      distances.add(distances.last + d);
    }
    return distances;
  }

  void dispose() {
    stop();
  }
}

final simulationServiceProvider = Provider<SimulationService>((ref) {
  final service = SimulationService();
  ref.onDispose(() => service.dispose());
  return service;
});

final simulationEnabledProvider = StateProvider<bool>((ref) => false);
