import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'trip_providers.dart';

class GeofenceManager {
  final Ref _ref;
  StreamSubscription<Position>? _subscription;
  bool _isMonitoring = false;

  GeofenceManager(this._ref);

  bool get isMonitoring => _isMonitoring;

  Future<void> startMonitoring() async {
    final locationService = _ref.read(locationServiceProvider);
    final hasPerm = await locationService.ensurePermissions();
    if (!hasPerm) return;

    _isMonitoring = true;

    final stream = locationService.getPositionStream();
    _subscription = stream.listen(
      (position) => _checkPosition(position),
      onError: (_) => stopMonitoring(),
    );
  }

  void _checkPosition(Position position) {
    final locationService = _ref.read(locationServiceProvider);
    final trip = _ref.read(activeTripProvider);

    if (trip == null || !trip.isActive) return;
    if (!locationService.isPositionValid(position)) return;

    final distance = locationService.calculateDistanceTo(
      trip.destination.latitude,
      trip.destination.longitude,
      currentLat: position.latitude,
      currentLon: position.longitude,
    );

    _ref.read(activeTripProvider.notifier).updateDistance(distance);

    if (distance <= trip.destination.alertRadius) {
      _ref.read(activeTripProvider.notifier).triggerAlarm();
      stopMonitoring();
    }
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _isMonitoring = false;
  }

  void dispose() {
    stopMonitoring();
  }
}

final geofenceManagerProvider = Provider<GeofenceManager>((ref) {
  return GeofenceManager(ref);
});
