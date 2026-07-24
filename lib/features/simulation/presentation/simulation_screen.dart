import 'dart:async';
import 'package:audioplayers/audioplayers.dart' show AudioPlayer, DeviceFileSource;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/alarm_sound.dart';
import '../../../core/utils/gps_utils.dart';
import '../../destination/data/destination_model.dart';
import '../../destination/data/destination_providers.dart';
import '../../trip/data/saved_route.dart';
import '../../trip/data/saved_route_repository.dart';
import '../../settings/data/settings_providers.dart';
import '../../trip/data/trip_model.dart';
import '../../trip/data/trip_providers.dart';
import '../../trip/data/routing_service.dart';
import '../../trip/data/waypoint.dart';
import '../data/simulation_service.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  final List<Destination> _selectedWaypoints = [];
  bool _isSimulating = false;
  bool _isPlayingTest = false;
  AudioPlayer? _audioPlayer;
  StreamSubscription? _playerCompleteSub;
  final _customSpeedController = TextEditingController();
  double? _customSpeedKmh;

  bool get _canAddWaypoint => _selectedWaypoints.length < 5;

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    _audioPlayer?.dispose();
    _customSpeedController.dispose();
    super.dispose();
  }

  Future<void> _testAlarmSound(String? stored) async {
    final path = AlarmSoundHelper.getInternalPath(stored);
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No custom alarm sound selected')),
      );
      return;
    }

    if (_isPlayingTest) {
      await _audioPlayer?.stop();
      setState(() => _isPlayingTest = false);
      return;
    }

    _audioPlayer ??= AudioPlayer();
    setState(() => _isPlayingTest = true);

    try {
      final source = DeviceFileSource(
        path.startsWith('file://') ? path.substring(7) : path,
      );
      await _audioPlayer!.play(source);
      _playerCompleteSub?.cancel();
      _playerCompleteSub = _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingTest = false);
      });
    } catch (e) {
      setState(() => _isPlayingTest = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play audio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(destinationListProvider);
    final settings = ref.watch(settingsProvider);
    final simulationService = ref.watch(simulationServiceProvider);
    final activeTrip = ref.watch(activeTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.science_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'GPS Movement Simulation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Simulate GPS movement toward a destination for testing. '
                  'This bypasses real GPS and moves a virtual position at the selected speed.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
              title: 'Stops (${_selectedWaypoints.length}/5)',
              accentColor: const Color(0xFF0066FF),
            ),
          const SizedBox(height: AppSpacing.xs),
          if (_selectedWaypoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._selectedWaypoints.asMap().entries.map((entry) {
                    final i = entry.key;
                    final wp = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              wp.name,
                              style: AppTypography.secondary.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline_rounded,
                                size: 18, color: context.error),
                            onPressed: () {
                              setState(() => _selectedWaypoints.removeAt(i));
                            },
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          if (destinationsAsync.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (destinationsAsync.hasError)
            AppCard(
              child: Text(
                'Error loading destinations',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            )
          else
            _DestinationList(
              destinations: destinationsAsync.valueOrNull ?? [],
              selectedIds: _selectedWaypoints.map((w) => w.id).toSet(),
              onSelect: (dest) {
                setState(() {
                  if (_selectedWaypoints.any((w) => w.id == dest.id)) {
                    _selectedWaypoints.removeWhere((w) => w.id == dest.id);
                  } else if (_canAddWaypoint) {
                    _selectedWaypoints.add(dest);
                  }
                });
              },
            ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
              title: 'Saved Routes',
              accentColor: Theme.of(context).colorScheme.primary,
            ),
          const SizedBox(height: AppSpacing.xs),
          _SavedRoutesSection(
            selectedWaypointIds: _selectedWaypoints.map((w) => w.id).toSet(),
            onSelectRoute: (route) {
              setState(() {
                _selectedWaypoints.clear();
                for (final wp in route.waypoints) {
                  _selectedWaypoints.add(Destination(
                    id: wp.id,
                    name: wp.name,
                    latitude: wp.latitude,
                    longitude: wp.longitude,
                    alertRadius: wp.alertRadius,
                    createdAt: DateTime.now(),
                  ));
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
              title: 'Speed',
              accentColor: const Color(0xFFFF6B35),
            ),
          const SizedBox(height: AppSpacing.sm),
          _SpeedSelector(
            currentMode: _customSpeedKmh != null ? null : settings.commuteMode,
            onChanged: (mode) {
              _customSpeedController.clear();
              setState(() => _customSpeedKmh = null);
              ref.read(settingsProvider.notifier).setCommuteMode(mode);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text('Custom', style: AppTypography.secondary),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _customSpeedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                    hintText: 'km/h',
                  ),
                  onChanged: (val) {
                    setState(() => _customSpeedKmh = double.tryParse(val));
                  },
                ),
              ),
              const SizedBox(width: 4),
              Text('km/h', style: AppTypography.secondary),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Sound',
            accentColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Row(
              children: [
                Icon(
                  _isPlayingTest ? Icons.volume_up_rounded : Icons.music_note_outlined,
                  color: context.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alarm Sound', style: AppTypography.bodyBold),
                      Text(
                        settings.customAlarmSoundPath != null
                            ? 'Custom sound selected'
                            : 'Default · Set a custom sound in Settings',
                        style: AppTypography.caption.copyWith(color: context.textTertiary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isPlayingTest
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline_rounded,
                    color: context.primary,
                    size: 32,
                  ),
                  onPressed: settings.customAlarmSoundPath != null
                      ? () => _testAlarmSound(settings.customAlarmSoundPath)
                      : null,
                  tooltip: _isPlayingTest ? 'Stop' : 'Test Alarm Sound',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isSimulating) ...[
            _SimulationStatusCard(
              service: simulationService,
              activeTrip: activeTrip,
            ),
            if (settings.napModeEnabled) ...[
              const SizedBox(height: AppSpacing.md),
              _NapModeActiveBanner(),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Stop Simulation',
              isDestructive: true,
              onPressed: () {
                simulationService.stop();
                ref.read(simulationEnabledProvider.notifier).state = false;
                ref.read(activeTripProvider.notifier).cancelTrip();
                setState(() => _isSimulating = false);
              },
            ),
          ] else
            AppButton(
              label: 'Start Simulation',
              icon: Icons.play_arrow_rounded,
              onPressed: _selectedWaypoints.isNotEmpty
                  ? () {
                      _startSimulation(simulationService, settings);
                    }
                  : null,
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _startSimulation(SimulationService service, AppSettings settings) {
    if (_selectedWaypoints.isEmpty) return;

    final speedMps = _customSpeedKmh != null
        ? _customSpeedKmh! / 3.6
        : settings.simulationSpeedMps;

    final first = _selectedWaypoints.first;
    service.start(
      destinationLatitude: first.latitude,
      destinationLongitude: first.longitude,
      destinationName: first.name,
      startLatitude: first.latitude + 0.01,
      startLongitude: first.longitude,
      speedMps: speedMps,
    );

    ref.read(simulationEnabledProvider.notifier).state = true;

    final waypoints = _selectedWaypoints
        .asMap()
        .entries
        .map((e) => Waypoint(
              id: e.value.id,
              name: e.value.name,
              latitude: e.value.latitude,
              longitude: e.value.longitude,
              alertRadius: e.value.alertRadius,
              orderIndex: e.key,
            ))
        .toList();
    ref.read(activeTripProvider.notifier).startTripWithWaypoints(waypoints);

    setState(() => _isSimulating = true);

    _fetchRouteAndStart(service, settings);
  }

  Future<void> _fetchRouteAndStart(SimulationService service, AppSettings settings) async {
    if (_selectedWaypoints.isEmpty) return;

    final speedMps = _customSpeedKmh != null
        ? _customSpeedKmh! / 3.6
        : settings.simulationSpeedMps;

    final first = _selectedWaypoints.first;
    final from = LatLng(
      first.latitude + 0.01,
      first.longitude,
    );
    final to = LatLng(
      first.latitude,
      first.longitude,
    );

    final routingService = ref.read(routingServiceProvider);
    final route = await routingService.fetchRoute(from, to);
    if (route != null) {
      service.start(
        destinationLatitude: first.latitude,
        destinationLongitude: first.longitude,
        destinationName: first.name,
        startLatitude: first.latitude + 0.01,
        startLongitude: first.longitude,
        speedMps: speedMps,
        routeCoordinates: route.coordinates,
      );
      ref.read(activeTripProvider.notifier).setRouteResult(route);
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/active-trip');
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _SectionHeader({
    required this.title,
    this.accentColor = const Color(0xFF00A896),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DestinationList extends StatelessWidget {
  final List<Destination> destinations;
  final Set<String> selectedIds;
  final ValueChanged<Destination> onSelect;

  const _DestinationList({
    required this.destinations,
    required this.selectedIds,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: Text(
              'No saved destinations yet.\nCreate one first.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: destinations.asMap().entries.map((entry) {
        final dest = entry.value;
        final selected = selectedIds.contains(dest.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: AnimatedScale(
            scale: selected ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AppCard(
              onTap: () => onSelect(dest),
              color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dest.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dest.latitude.toStringAsFixed(4)}, ${dest.longitude.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 40 * entry.key), duration: 220.ms);
      }).toList(),
    );
  }
}

class _SpeedSelector extends StatelessWidget {
  final CommuteMode? currentMode;
  final ValueChanged<CommuteMode> onChanged;

  const _SpeedSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: CommuteMode.values.map((mode) {
          final selected = mode == currentMode;
          return ChoiceChip(
            label: Text(mode.label),
            selected: selected,
            onSelected: (_) => onChanged(mode),
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: selected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.tileRadius),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SimulationStatusCard extends StatelessWidget {
  final SimulationService service;
  final ActiveTrip? activeTrip;

  const _SimulationStatusCard({
    required this.service,
    required this.activeTrip,
  });

  @override
  Widget build(BuildContext context) {
    final position = service.currentPosition;
    final distance = activeTrip?.currentDistance ?? 0;

    return AppCard(
      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: context.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.error.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.4, duration: 800.ms),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'SIMULATION LIVE',
                style: AppTypography.caption.copyWith(
                  color: context.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  GpsUtils.formatDistance(distance),
                  style: AppTypography.distance.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 44,
                    height: 1.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'away',
                  style: AppTypography.caption.copyWith(
                    color: context.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.speed_rounded,
                size: 16,
                color: context.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${(service.speedMps * 3.6).toStringAsFixed(1)} km/h',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (position != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Icon(
                  Icons.my_location_rounded,
                  size: 14,
                  color: context.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NapModeActiveBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.secondary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.bedtime_rounded, color: context.secondary, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Nap Mode is ON — screen will dim on trip start',
            style: AppTypography.caption.copyWith(
              color: context.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedRoutesSection extends ConsumerWidget {
  final Set<String> selectedWaypointIds;
  final ValueChanged<SavedRoute> onSelectRoute;

  const _SavedRoutesSection({
    required this.selectedWaypointIds,
    required this.onSelectRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(savedRoutesProvider);
    return routesAsync.when(
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (routes) {
        if (routes.isEmpty) return const SizedBox.shrink();
        return Column(
          children: routes.take(5).map((route) {
            final waypoints = route.waypoints;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                onTap: () => onSelectRoute(route),
                child: Row(
                  children: [
                    Icon(
                      Icons.route_rounded,
                      color: context.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: AppTypography.bodyBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${waypoints.length} stop${waypoints.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: context.primary,
                      size: 28,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
