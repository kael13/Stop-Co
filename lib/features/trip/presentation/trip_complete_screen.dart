import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/components/app_button.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/gps_utils.dart';
import '../data/trip_providers.dart';
import '../data/waypoint.dart';

class TripCompleteScreen extends ConsumerWidget {
  const TripCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = ref.watch(activeTripProvider);

    if (activeTrip == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pushReplacementNamed(context, '/');
      });
      return const SizedBox();
    }

    final wp = activeTrip.currentWaypoint;
    final distance = activeTrip.currentDistance ?? 0;
    final distanceFormatted = GpsUtils.formatDistance(distance);
    final waypoints = activeTrip.waypoints;
    final totalStops = waypoints.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.check_circle_rounded,
                color: context.success,
                size: 80,
              ).animate().scale(
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Trip Complete!',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: AppSpacing.xs),
              Text(
                totalStops > 1
                    ? '$totalStops stops visited'
                    : 'Arrived at ${wp.name}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.textTertiary,
                ),
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: AppSpacing.xl),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: context.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.straighten_rounded,
                          label: 'Distance',
                          value: distanceFormatted,
                          color: context.primary,
                        ),
                        _StatItem(
                          icon: Icons.flag_rounded,
                          label: 'Stops',
                          value: '$totalStops',
                          color: context.success,
                        ),
                      ],
                    ),
                    if (totalStops > 1) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      ...waypoints.asMap().entries.map((entry) {
                        final i = entry.key;
                        final w = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: context.success.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: context.success,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  w.name,
                                  style: AppTypography.bodyBold.copyWith(
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: context.success,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: AppSpacing.xs),

              if (waypoints.length >= 2)
                SizedBox(
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _MiniRouteMap(waypoints: waypoints),
                  ).animate().fadeIn(delay: 750.ms),

                ),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'New Trip',
                        icon: Icons.near_me_rounded,
                        onPressed: () {
                          ref.read(activeTripProvider.notifier).clearTrip();
                          Navigator.pushReplacementNamed(context, '/');
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () {
                        ref.read(activeTripProvider.notifier).clearTrip();
                        Navigator.pushNamed(context, '/');
                      },
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.title.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _MiniRouteMap extends StatelessWidget {
  final List<Waypoint> waypoints;

  const _MiniRouteMap({required this.waypoints});

  @override
  Widget build(BuildContext context) {
    if (waypoints.isEmpty) return const SizedBox();
    final lats = waypoints.map((w) => w.latitude).toList();
    final lngs = waypoints.map((w) => w.longitude).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
            urlTemplate: AppConstants.tileUrlTemplate,
            userAgentPackageName: 'com.stopco.app',
          ),
          MarkerLayer(
            markers: waypoints.asMap().entries.map((entry) {
              final i = entry.key;
              final wp = entry.value;
              return Marker(
                point: LatLng(wp.latitude, wp.longitude),
                width: 24,
                height: 24,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
              );
            }).toList(),
          ),
          if (waypoints.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: waypoints
                      .map((w) => LatLng(w.latitude, w.longitude))
                      .toList(),
                  color: context.primary.withValues(alpha: 0.4),
                  strokeWidth: 2,
                  pattern: const StrokePattern.dotted(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
