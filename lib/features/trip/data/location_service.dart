import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/gps_utils.dart';

class LocationService {
  LocationPermission? _permission;
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  bool _isListening = false;

  Future<bool> requestPermissions() async {
    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
    }
    if (_permission == LocationPermission.deniedForever) {
      return false;
    }
    return _permission == LocationPermission.always ||
        _permission == LocationPermission.whileInUse;
  }

  bool get hasPermission =>
      _permission == LocationPermission.always ||
      _permission == LocationPermission.whileInUse;

  Future<bool> ensurePermissions() async {
    if (hasPermission) return true;
    return requestPermissions();
  }

  Future<Geolocator?> get locationService async => null;

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPerm = await ensurePermissions();
      if (!hasPerm) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      _lastPosition = position;
      _lastPositionTime = DateTime.now();
      return position;
    } catch (_) {
      return null;
    }
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    );
  }

  bool isPositionValid(Position position) {
    if (!GpsUtils.isAccuracyAcceptable(position.accuracy)) return false;
    if (position.speed >= 0 && !GpsUtils.isSpeedPlausible(position.speed)) {
      return false;
    }
    if (_lastPosition != null && _lastPositionTime != null) {
      final delta = DateTime.now().difference(_lastPositionTime!).inSeconds;
      if (GpsUtils.isMovementSpike(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
        delta.toDouble(),
      )) {
        return false;
      }
    }
    _lastPosition = position;
    _lastPositionTime = DateTime.now();
    return true;
  }

  double calculateDistanceTo(
    double destLat, double destLon, {
    double? currentLat,
    double? currentLon,
  }) {
    if (currentLat != null && currentLon != null) {
      return GpsUtils.calculateDistance(
        currentLat, currentLon, destLat, destLon,
      );
    }
    if (_lastPosition != null) {
      return GpsUtils.calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        destLat,
        destLon,
      );
    }
    return double.infinity;
  }

  void startListening() => _isListening = true;
  void stopListening() => _isListening = false;
  bool get isListening => _isListening;
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
