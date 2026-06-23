import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/gps_utils.dart';
import '../../destination/data/destination_model.dart';
import '../../destination/data/destination_providers.dart';
import '../../settings/data/settings_providers.dart';
import '../../trip/data/trip_model.dart';
import '../../trip/data/trip_providers.dart';
import '../../trip/data/routing_service.dart';
import '../data/simulation_service.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  Destination? _selectedDestination;
  bool _isSimulating = false;

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
              title: 'Select Destination',
              accentColor: const Color(0xFF0066FF),
            ),
          const SizedBox(height: AppSpacing.sm),
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
              selectedId: _selectedDestination?.id,
              onSelect: (dest) {
                setState(() => _selectedDestination = dest);
              },
            ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
              title: 'Speed',
              accentColor: const Color(0xFFFF6B35),
            ),
          const SizedBox(height: AppSpacing.sm),
          _SpeedSelector(
            currentMode: settings.commuteMode,
            onChanged: (mode) {
              ref.read(settingsProvider.notifier).setCommuteMode(mode);
            },
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
              onPressed: _selectedDestination != null
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
    if (_selectedDestination == null) return;

    service.start(
      destination: _selectedDestination!,
      startLatitude: _selectedDestination!.latitude + 0.01,
      startLongitude: _selectedDestination!.longitude,
      speedMps: settings.simulationSpeedMps,
    );

    ref.read(simulationEnabledProvider.notifier).state = true;
    ref.read(activeTripProvider.notifier).startTrip(_selectedDestination!);

    setState(() => _isSimulating = true);

    _fetchRouteAndStart(service, settings);
  }

  Future<void> _fetchRouteAndStart(SimulationService service, AppSettings settings) async {
    if (_selectedDestination == null) return;

    final from = LatLng(
      _selectedDestination!.latitude + 0.01,
      _selectedDestination!.longitude,
    );
    final to = LatLng(
      _selectedDestination!.latitude,
      _selectedDestination!.longitude,
    );

    final routingService = ref.read(routingServiceProvider);
    final route = await routingService.fetchRoute(from, to);
    if (route != null) {
      service.start(
        destination: _selectedDestination!,
        startLatitude: _selectedDestination!.latitude + 0.01,
        startLongitude: _selectedDestination!.longitude,
        speedMps: settings.simulationSpeedMps,
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
  final String? selectedId;
  final ValueChanged<Destination> onSelect;

  const _DestinationList({
    required this.destinations,
    required this.selectedId,
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
        final selected = dest.id == selectedId;
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
  final CommuteMode currentMode;
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
