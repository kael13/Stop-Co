import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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
                      color: AppColors.teal,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'GPS Movement Simulation',
                      style: AppTypography.sectionHeader.copyWith(
                        color: AppColors.deepSlate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Simulate GPS movement toward a destination for testing. '
                  'This bypasses real GPS and moves a virtual position at the selected speed.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: 'Select Destination'),
          const SizedBox(height: AppSpacing.sm),
          if (destinationsAsync.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (destinationsAsync.hasError)
            AppCard(
              child: Text(
                'Error loading destinations',
                style: AppTypography.body.copyWith(
                  color: AppColors.error,
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
          _SectionHeader(title: 'Speed'),
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
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Stop Simulation',
              isDestructive: true,
              onPressed: () {
                simulationService.stop();
                ref.read(simulationEnabledProvider.notifier).state = false;
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

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.sectionHeader.copyWith(
        color: AppColors.deepSlate,
      ),
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
              style: AppTypography.secondary.copyWith(
                color: AppColors.grey400,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: destinations.map((dest) {
        final selected = dest.id == selectedId;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: AppCard(
            onTap: () => onSelect(dest),
            color: selected ? AppColors.electricBlue.withValues(alpha: 0.1) : null,
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: selected ? AppColors.electricBlue : AppColors.grey400,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dest.name,
                        style: AppTypography.bodyBold.copyWith(
                          color: selected ? AppColors.electricBlue : AppColors.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dest.latitude.toStringAsFixed(4)}, ${dest.longitude.toStringAsFixed(4)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.electricBlue,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
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
            selectedColor: AppColors.electricBlue,
            labelStyle: TextStyle(
              color: selected ? AppColors.white : AppColors.deepSlate,
            ),
            backgroundColor: AppColors.grey100,
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
      color: AppColors.teal.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Simulation Active',
                style: AppTypography.bodyBold.copyWith(
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (position != null) ...[
            Text(
              'Position: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
          Text(
            'Speed: ${(service.speedMps * 3.6).toStringAsFixed(1)} km/h',
            style: AppTypography.caption.copyWith(
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Distance: ${GpsUtils.formatDistance(distance)}',
            style: AppTypography.caption.copyWith(
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
