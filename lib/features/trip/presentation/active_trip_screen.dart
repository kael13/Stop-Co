import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/animation/animation_presets.dart';
import '../../../core/components/app_button.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/gps_utils.dart';
import '../../../core/platform/foreground_service_channel.dart';
import '../../settings/data/settings_providers.dart';
import '../../simulation/data/simulation_service.dart';
import '../data/geofence_manager.dart';
import '../data/location_service.dart';
import '../data/routing_service.dart';
import '../data/trip_providers.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen>
    with WidgetsBindingObserver {
  StreamSubscription<Position>? _subscription;
  Timer? _pollTimer;
  Timer? _routeReFetchTimer;
  bool _permissionDenied = false;
  double? _lastSpeed;
  LatLng? _currentPosition;
  bool _isFetchingRoute = false;
  LatLng? _lastRouteStartPoint;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapController = MapController();
    _startMonitoring();
  }

  @override
  void dispose() {
    _routeReFetchTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _pollTimer?.cancel();
    ForegroundServiceChannel.stopTracking();
    _restoreScreenBrightness();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final trip = ref.read(activeTripProvider);
      if (trip == null || !trip.isActive) return;
      if (ref.read(simulationEnabledProvider)) {
        _startSimulationPolling();
      } else {
        _startPolling();
      }
    } else if (!ref.read(simulationEnabledProvider)) {
      _pollTimer?.cancel();
    }
  }

  Future<void> _startMonitoring() async {
    final simulationEnabled = ref.read(simulationEnabledProvider);

    if (simulationEnabled) {
      _startSimulationMonitoring();
      return;
    }

    final locationService = ref.read(locationServiceProvider);
    final hasPerm = await locationService.ensurePermissions();
    if (!hasPerm) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    _startRealMonitoring();
  }

  void _startRealMonitoring() {
    final locationService = ref.read(locationServiceProvider);
    final geofenceManager = ref.read(geofenceManagerProvider);

    geofenceManager.startMonitoring();
    _startForegroundService();
    _dimScreenIfNapMode();

    final stream = locationService.getPositionStream();
    _subscription = stream.listen((position) {
      if (!mounted) return;
      _updateDistance(position.latitude, position.longitude,
          speed: position.speed >= 0 ? position.speed : null);
    }, onError: (_) {
      if (mounted) setState(() => _permissionDenied = true);
    });

    _startPolling();
    _startPeriodicRouteReFetching();
  }

  void _startSimulationMonitoring() {
    _startForegroundService();
    _dimScreenIfNapMode();

    _scheduleSimulationRouteFetch();

    _startSimulationPolling();
    _startPeriodicRouteReFetching();
  }

  void _startForegroundService() {
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;
    final wp = trip.currentWaypoint;
    ForegroundServiceChannel.startTracking(
      latitude: wp.latitude,
      longitude: wp.longitude,
      radius: wp.alertRadius,
      destinationName: wp.name,
      destinationId: wp.id,
    );
  }

  void _updateForegroundNotification(String name, String distance) {
    ForegroundServiceChannel.updateTrackingNotification(
      destinationName: name,
      remainingDistance: distance,
    );
  }

  void _pollSimulation() {
    if (!mounted) return;
    final simulationService = ref.read(simulationServiceProvider);
    final position = simulationService.currentPosition;
    if (position != null) {
      _updateDistance(position.latitude, position.longitude);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pollLocation(),
    );
  }

  void _startSimulationPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _pollSimulation(),
    );
  }

  Future<void> _pollLocation() async {
    if (!mounted) return;
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();
    if (position != null && mounted) {
      _updateDistance(position.latitude, position.longitude,
          speed: position.speed >= 0 ? position.speed : null);
    }
  }

  void _scheduleSimulationRouteFetch() async {
    if (!mounted) return;
    final trip = ref.read(activeTripProvider);
    if (trip?.routeResult != null) return;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final simulationService = ref.read(simulationServiceProvider);
    final position = simulationService.currentPosition;
    final updatedTrip = ref.read(activeTripProvider);
    if (position == null || updatedTrip == null) return;

    final wp = updatedTrip.currentWaypoint;
    final from = LatLng(position.latitude, position.longitude);
    final to = LatLng(wp.latitude, wp.longitude);
    await _fetchAndStoreRoute(from, to);

    if (!mounted) return;
    final routeResult = ref.read(activeTripProvider)?.routeResult;
    if (routeResult == null) return;

    final settings = ref.read(settingsProvider);
    simulationService.start(
      destinationLatitude: wp.latitude,
      destinationLongitude: wp.longitude,
      destinationName: wp.name,
      startLatitude: position.latitude,
      startLongitude: position.longitude,
      speedMps: settings.simulationSpeedMps,
      routeCoordinates: routeResult.coordinates,
    );
  }

  void _updateDistance(double lat, double lon, {double? speed}) {
    final wasNull = _currentPosition == null;
    setState(() => _currentPosition = LatLng(lat, lon));
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;
    final wp = trip.currentWaypoint;

    if (wasNull) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
      if (!_isFetchingRoute) {
        final from = LatLng(lat, lon);
        final to = LatLng(wp.latitude, wp.longitude);
        _fetchAndStoreRoute(from, to);
      }
    }

    if (speed != null) {
      _lastSpeed = speed;
      _detectCommuteMode(speed);
    }

    final distance = GpsUtils.calculateDistance(
      lat, lon,
      wp.latitude, wp.longitude,
    );

    ref.read(activeTripProvider.notifier).updateDistance(distance);
    ref.read(activeTripProvider.notifier).addBreadcrumb(LatLng(lat, lon));

    _updateForegroundNotification(
      wp.name,
      GpsUtils.formatDistance(distance),
    );

    bool hasLeftPrevZone = true;
    if (trip.currentWaypointIndex > 0) {
      final prevWp = trip.waypoints[trip.currentWaypointIndex - 1];
      final distToPrev = GpsUtils.calculateDistance(
        lat, lon, prevWp.latitude, prevWp.longitude,
      );
      if (distToPrev <= prevWp.alertRadius) {
        hasLeftPrevZone = false;
      }
    }

    if (distance <= wp.alertRadius && hasLeftPrevZone) {
      HapticFeedback.heavyImpact();
      ref.read(activeTripProvider.notifier).triggerAlarm();
      _subscription?.cancel();
      _pollTimer?.cancel();
      _routeReFetchTimer?.cancel();
      Navigator.pushReplacementNamed(context, '/alarm');
    }
  }

  Future<void> _fetchAndStoreRoute(LatLng from, LatLng to) async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);

    final routingService = ref.read(routingServiceProvider);
    final route = await routingService.fetchRoute(from, to);

    if (route != null && mounted) {
      ref.read(activeTripProvider.notifier).setRouteResult(route);
      _lastRouteStartPoint = from;
    }

    if (mounted) {
      setState(() => _isFetchingRoute = false);
    }
  }

  void _startPeriodicRouteReFetching() {
    _routeReFetchTimer?.cancel();
    _routeReFetchTimer = Timer.periodic(
      const Duration(seconds: AppConstants.routeReFetchIntervalSec),
      (_) => _maybeReFetchRoute(),
    );
  }

  void _maybeReFetchRoute() {
    if (_isFetchingRoute || _currentPosition == null) return;

    final trip = ref.read(activeTripProvider);
    if (trip == null) return;

    if (_lastRouteStartPoint != null) {
      final dist = GpsUtils.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _lastRouteStartPoint!.latitude,
        _lastRouteStartPoint!.longitude,
      );
      if (dist < AppConstants.routeReFetchMinDistance) return;
    }

    final wp = trip.currentWaypoint;
    final from = _currentPosition!;
    final to = LatLng(wp.latitude, wp.longitude);
    _fetchAndStoreRoute(from, to);
  }

  void _fitMapBounds() {
    if (_currentPosition == null) return;
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;
    final wp = trip.currentWaypoint;
    final dest = LatLng(wp.latitude, wp.longitude);
    final lat1 = _currentPosition!.latitude;
    final lng1 = _currentPosition!.longitude;
    final lat2 = dest.latitude;
    final lng2 = dest.longitude;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(min(lat1, lat2), min(lng1, lng2)),
          LatLng(max(lat1, lat2), max(lng1, lng2)),
        ),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  CommuteMode _classifySpeed(double speedMps) {
    if (speedMps < 1.8) return CommuteMode.walking;
    if (speedMps < 9.0) return CommuteMode.bus;
    if (speedMps < 20.0) return CommuteMode.car;
    return CommuteMode.train;
  }

  void _detectCommuteMode(double speedMps) {
    final settings = ref.read(settingsProvider);
    final detected = _classifySpeed(speedMps);
    if (detected != settings.commuteMode) {
      ref.read(settingsProvider.notifier).setCommuteMode(detected);
    }
  }

  void _dimScreenIfNapMode() {
    final settings = ref.read(settingsProvider);
    if (settings.napModeEnabled) {
      ScreenBrightness().setApplicationScreenBrightness(0.0);
    }
  }

  void _restoreScreenBrightness() {
    ScreenBrightness().resetApplicationScreenBrightness();
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider);
    final simulationEnabled = ref.watch(simulationEnabledProvider);
    final settings = ref.watch(settingsProvider);

    if (trip == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox();
    }

    final distance = trip.currentDistance ?? 0;
    final distanceFormatted = GpsUtils.formatDistance(distance);
    final detectedMode = settings.commuteMode;
    final speedKmh = _lastSpeed != null ? (_lastSpeed! * 3.6).toStringAsFixed(1) : null;

    final routeCoordinates = trip.routeResult?.coordinates;

    return Scaffold(
      body: Stack(
        children: [
          if (_currentPosition != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.tileUrlTemplate,
                  userAgentPackageName: 'com.stopco.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 36,
                      height: 36,
                      child: const _UserMarker(),
                    ),
                    ...trip.waypoints.asMap().entries.map((entry) {
                      final i = entry.key;
                      final wp = entry.value;
                      final isCurrent = i == trip.currentWaypointIndex;
                      final isPast = i < trip.currentWaypointIndex;
                      if (trip.hasMultipleStops) {
                        return Marker(
                          point: LatLng(wp.latitude, wp.longitude),
                          width: 36,
                          height: 36,
                          child: _NumberedWaypointMarker(
                            number: i + 1,
                            isCurrent: isCurrent,
                            isPast: isPast,
                            withinThreshold:
                                isCurrent && distance <= wp.alertRadius,
                          ),
                        );
                      }
                      return Marker(
                        point: LatLng(wp.latitude, wp.longitude),
                        width: 36,
                        height: 36,
                        child: _DestinationPinMarker(
                          withinThreshold:
                              distance <= wp.alertRadius,
                        ),
                      );
                    }),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    if (routeCoordinates != null)
                      Polyline(
                        points: routeCoordinates,
                        color: context.primary.withValues(alpha: 0.4),
                        strokeWidth: 3,
                      ),
                  ],
                ),
              ],
            )
          else
            Container(color: context.scaffoldBackground),

          SafeArea(
            child: Column(
              children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: _InfoOverlay(
                      statusColor: simulationEnabled
                          ? context.secondary
                          : _permissionDenied
                              ? context.error
                              : context.success,
                      statusLabel: simulationEnabled
                          ? 'Simulating to'
                          : _permissionDenied
                              ? 'GPS unavailable'
                              : 'Tracking to',
                      destinationName: trip.currentWaypoint.name,
                      distanceFormatted: distanceFormatted,
                      stopLabel: trip.hasMultipleStops
                          ? 'Stop ${trip.currentWaypointIndex + 1} of ${trip.totalStops}'
                          : null,
                      speedKmh: speedKmh,
                      commuteMode: detectedMode,
                      progressValue: distance > 0 && trip.currentWaypoint.alertRadius > 0
                          ? (distance / trip.currentWaypoint.alertRadius).clamp(0.0, 1.0)
                          : 1.0,
                      isSimulation: simulationEnabled,
                    ),
                  ),
                if (_permissionDenied && !simulationEnabled)
                  _PermissionDeniedBanner(),
                if (simulationEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: _SimulationBadge(
                      speedMps: settings.simulationSpeedMps,
                      onSpeedChanged: (mode) {
                        ref.read(settingsProvider.notifier).setCommuteMode(mode);
                        final simulationService = ref.read(simulationServiceProvider);
                        final newSettings = AppSettings(commuteMode: mode);
                        simulationService.setSpeed(newSettings.simulationSpeedMps);
                      },
                      currentMode: settings.commuteMode,
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Cancel Trip',
                      isDestructive: true,
                       onPressed: () {
                        _subscription?.cancel();
                        _pollTimer?.cancel();
                        _routeReFetchTimer?.cancel();
                        ForegroundServiceChannel.stopTracking();
                        _restoreScreenBrightness();
                        WakelockPlus.disable();
                        if (simulationEnabled) {
                          ref.read(simulationServiceProvider).stop();
                          ref.read(simulationEnabledProvider.notifier).state = false;
                        }
                        ref.read(activeTripProvider.notifier).cancelTrip();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoOverlay extends StatelessWidget {
  final Color statusColor;
  final String statusLabel;
  final String destinationName;
  final String distanceFormatted;
  final String? stopLabel;
  final String? speedKmh;
  final CommuteMode? commuteMode;
  final double progressValue;
  final bool isSimulation;

  const _InfoOverlay({
    required this.statusColor,
    required this.statusLabel,
    required this.destinationName,
    required this.distanceFormatted,
    this.stopLabel,
    this.speedKmh,
    this.commuteMode,
    required this.progressValue,
    required this.isSimulation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stopLabel != null)
                      Text(
                        stopLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      '$statusLabel: $destinationName',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'active-trip-distance',
                      child: Text(
                        distanceFormatted,
                        style: AppTypography.distance.copyWith(
                          color: isSimulation ? context.secondary : context.primary,
                          fontSize: 48,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'away',
                      style: AppTypography.caption.copyWith(
                        color: context.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              if (speedKmh != null && !isSimulation) ...[
                const SizedBox(height: 2),
                Text(
                  '$speedKmh km/h',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: context.surfaceContainerLow,
                  valueColor: AlwaysStoppedAnimation(
                    isSimulation ? context.secondary : context.primary,
                  ),
                  minHeight: 5,
                ).subtleShimmerSweep(),
              ),
            ],
          ),
    );
  }
}

class _PermissionDeniedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gps_off_rounded, color: context.warning, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Location permission is required for tracking.\nPlease enable it in Settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.warning),
          ),
        ],
      ),
    );
  }
}

class _SimulationBadge extends StatelessWidget {
  final double speedMps;
  final ValueChanged<CommuteMode> onSpeedChanged;
  final CommuteMode currentMode;

  const _SimulationBadge({
    required this.speedMps,
    required this.onSpeedChanged,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: context.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.science_rounded,
                color: context.secondary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'Simulation Active',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(speedMps * 3.6).toStringAsFixed(0)} km/h',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xxs,
            children: CommuteMode.values.map((mode) {
              final selected = mode == currentMode;
              return GestureDetector(
                onTap: () => onSpeedChanged(mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? context.secondary : context.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    mode.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected ? context.textInverse : context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}

class _NumberedWaypointMarker extends StatelessWidget {
  final int number;
  final bool isCurrent;
  final bool isPast;
  final bool withinThreshold;

  const _NumberedWaypointMarker({
    required this.number,
    required this.isCurrent,
    required this.isPast,
    this.withinThreshold = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPast
        ? context.textTertiary
        : withinThreshold
            ? context.error
            : context.error;
    final bgColor = isPast
        ? context.textTertiary.withValues(alpha: 0.3)
        : context.error;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isCurrent && !withinThreshold)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isPast ? bgColor : bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: isPast
                ? Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DestinationPinMarker extends StatelessWidget {
  final bool withinThreshold;
  const _DestinationPinMarker({required this.withinThreshold});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Icon(
      Icons.location_on_rounded,
      color: color,
      size: 30,
    );
  }
}
