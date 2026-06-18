import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/app_drawer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/gps_utils.dart';
import '../../auth/data/auth_providers.dart';
import '../../destination/data/destination_model.dart';
import '../../destination/data/destination_providers.dart';
import '../../destination/data/destination_repository.dart';
import '../../destination/presentation/destination_setup_screen.dart';
import '../../trip/data/trip_model.dart';
import '../../trip/data/trip_providers.dart';
import '../../trip/data/location_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    final locationService = ref.read(locationServiceProvider);
    _positionStream = locationService.getPositionStream().listen((pos) {
      if (mounted) setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _deleteSelected() async {
    final repo = ref.read(destinationRepositoryProvider);
    for (final id in _selectedIds) {
      await repo.delete(id);
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final destinationsAsync = ref.watch(destinationListProvider);
    final activeTrip = ref.watch(activeTripProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          if (activeTrip != null)
            _currentPosition != null
                ? FlutterMap(
                    options: MapOptions(
                      initialCenter: _currentPosition!,
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.stopco.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.electricBlue,
                            ),
                          ),
                        ],
                      ),
                      SimpleAttributionWidget(
                        source: const Text('© OpenStreetMap contributors'),
                        alignment: Alignment.bottomRight,
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(authState: authState.valueOrNull),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      if (activeTrip != null)
                        _ActiveTripBanner(trip: activeTrip)
                      else
                        _StartTripSection(),
                      const SizedBox(height: AppSpacing.lg),
                      _RecentDestinations(
                        destinations: destinationsAsync.valueOrNull ?? [],
                        activeTripId: activeTrip?.destination.id,
                        isSelectionMode: _isSelectionMode,
                        selectedIds: _selectedIds,
                        onToggleSelection: _toggleSelection,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isSelectionMode)
            Positioned(
              bottom: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: AppButton(
                label: 'Delete Selected (${_selectedIds.length})',
                isDestructive: true,
                onPressed: _deleteSelected,
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final UserSignedIn? authState;

  const _Header({this.authState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = authState?.displayName != null
        ? 'Hi, ${authState!.displayName}'
        : 'Stop-Co';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTypography.largeTitle.copyWith(
                  color: AppColors.deepSlate,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                "Don't miss your stop",
                style: AppTypography.secondary.copyWith(
                  color: AppColors.grey400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartTripSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where are you heading?',
          style: AppTypography.sectionHeader.copyWith(
            color: AppColors.deepSlate,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Set Destination',
          icon: Icons.near_me_rounded,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DestinationSetupScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActiveTripBanner extends ConsumerWidget {
  final ActiveTrip trip;

  const _ActiveTripBanner({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = trip.currentDistance ?? 0;
    final distanceFormatted = GpsUtils.formatDistance(distance);
    final progress = distance > 0 && trip.destination.alertRadius > 0
        ? (distance / trip.destination.alertRadius).clamp(0.0, 1.0)
        : 1.0;

    return GestureDetector(
      onTap: () {
        final trip = ref.read(activeTripProvider);
        if (trip == null) return;
        if (trip.status == TripStatus.alarmTriggered) {
          Navigator.pushReplacementNamed(context, '/alarm');
        } else {
          Navigator.pushNamed(context, '/active-trip');
        }
      },
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Active Trip',
                  style: AppTypography.secondary.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              trip.destination.name,
              style: AppTypography.title.copyWith(
                color: AppColors.deepSlate,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$distanceFormatted away',
              style: AppTypography.distance.copyWith(
                color: AppColors.electricBlue,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.grey100,
                valueColor: const AlwaysStoppedAnimation(AppColors.electricBlue),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(activeTripProvider.notifier).cancelTrip();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Cancel Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _RecentDestinations extends ConsumerWidget {
  final List<Destination> destinations;
  final String? activeTripId;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final Function(String) onToggleSelection;

  const _RecentDestinations({
    required this.destinations,
    this.activeTripId,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (destinations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Destinations',
            style: AppTypography.sectionHeader.copyWith(
              color: AppColors.deepSlate,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'No saved destinations yet.\nSet one to get started.',
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary.copyWith(
                    color: AppColors.grey400,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Destinations',
          style: AppTypography.sectionHeader.copyWith(
            color: AppColors.deepSlate,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...destinations.map((dest) => _DestinationTile(
              destination: dest,
              isActive: dest.id == activeTripId,
              isSelected: selectedIds.contains(dest.id),
              onToggleSelection: () => onToggleSelection(dest.id),
            )),
      ],
    );
  }
}

class _DestinationTile extends ConsumerWidget {
  final Destination destination;
  final bool isActive;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const _DestinationTile({
    required this.destination,
    this.isActive = false,
    required this.isSelected,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        onTap: isActive ? null : onToggleSelection,
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelection(),
                activeColor: AppColors.electricBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: AppTypography.bodyBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          size: 14,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${destination.alertRadius.round()}m radius',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.grey400,
                          ),
                        ),
                        if (destination.isFavorite) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isActive)
                IconButton(
                  icon: Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.electricBlue,
                  ),
                  onPressed: () {
                    ref.read(activeTripProvider.notifier).startTrip(destination);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
