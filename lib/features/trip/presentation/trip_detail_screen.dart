import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/gps_utils.dart';
import '../data/trip_record.dart';
import '../data/trip_model.dart';

class TripDetailScreen extends ConsumerWidget {
  final TripRecord trip;

  const TripDetailScreen({super.key, required this.trip});

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(BuildContext context) {
    switch (trip.status) {
      case TripStatus.completed:
        return context.success;
      case TripStatus.alarmTriggered:
        return context.warning;
      case TripStatus.cancelled:
        return context.textTertiary;
      case TripStatus.monitoring:
        return context.primary;
    }
  }

  IconData _statusIcon() {
    switch (trip.status) {
      case TripStatus.completed:
        return Icons.check_circle_rounded;
      case TripStatus.alarmTriggered:
        return Icons.notifications_active_rounded;
      case TripStatus.cancelled:
        return Icons.cancel_rounded;
      case TripStatus.monitoring:
        return Icons.timelapse_rounded;
    }
  }

  String _statusLabel() {
    switch (trip.status) {
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.alarmTriggered:
        return 'Alarm Triggered';
      case TripStatus.cancelled:
        return 'Cancelled';
      case TripStatus.monitoring:
        return 'In Progress';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traveledPath = trip.gpsBreadcrumbs;
    final plannedRoute = trip.routeCoordinates;
    final destinationPoint = traveledPath.isNotEmpty
        ? traveledPath.last
        : plannedRoute.isNotEmpty
            ? plannedRoute.last
            : null;
    final hasPath = traveledPath.isNotEmpty || plannedRoute.isNotEmpty;

    final mapCenter = traveledPath.isNotEmpty
        ? LatLng(
            (traveledPath.first.latitude + traveledPath.last.latitude) / 2,
            (traveledPath.first.longitude + traveledPath.last.longitude) / 2,
          )
        : plannedRoute.isNotEmpty
            ? LatLng(
                (plannedRoute.first.latitude + plannedRoute.last.latitude) / 2,
                (plannedRoute.first.longitude + plannedRoute.last.longitude) / 2,
              )
            : const LatLng(0, 0);

    final distanceFormatted = GpsUtils.formatDistance(trip.totalDistance);
    final duration = _formatDuration(trip.duration);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _AnimatedTripMap(
              traveledPath: traveledPath,
              plannedRoute: plannedRoute,
              mapCenter: mapCenter,
              hasPath: hasPath,
              destinationPoint: destinationPoint,
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'trip-${trip.id}',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _statusColor(context).withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(
                          _statusIcon(),
                          color: _statusColor(context),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        trip.destinationName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: context.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(context).withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        _statusLabel(),
                        style: AppTypography.caption.copyWith(
                          color: _statusColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 280.ms,
                    ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.straighten_rounded,
                        label: 'Distance',
                        value: distanceFormatted,
                        color: context.primary,
                        heroTag: 'trip-${trip.id}-distance',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.timer_rounded,
                        label: 'Duration',
                        value: duration,
                        color: context.secondary,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 280.ms,
                    ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.route_rounded,
                        label: 'Planned route',
                        value: trip.plannedRouteDistance != null
                            ? GpsUtils.formatDistance(
                                trip.plannedRouteDistance!)
                            : '—',
                        color: context.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.schedule_rounded,
                        label: 'ETA',
                        value: trip.plannedRouteDuration != null
                            ? _formatDuration(
                                Duration(
                                    seconds:
                                        trip.plannedRouteDuration!.round()),
                              )
                            : '—',
                        color: context.warning,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 280.ms).slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 280.ms,
                    ),
                const SizedBox(height: AppSpacing.lg),
                _DetailRow(
                  icon: Icons.play_arrow_rounded,
                  label: 'Started',
                  value: _formatDate(trip.startedAt),
                ).animate().fadeIn(delay: 360.ms),
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(
                  icon: Icons.flag_rounded,
                  label: 'Ended',
                  value: _formatDate(trip.endedAt),
                ).animate().fadeIn(delay: 420.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? heroTag;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: context.textTertiary),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: AppTypography.title.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: tile);
    }
    return tile;
  }
}

class _AnimatedTripMap extends StatefulWidget {
  final List<LatLng> traveledPath;
  final List<LatLng> plannedRoute;
  final LatLng mapCenter;
  final bool hasPath;
  final LatLng? destinationPoint;

  const _AnimatedTripMap({
    required this.traveledPath,
    required this.plannedRoute,
    required this.mapCenter,
    required this.hasPath,
    required this.destinationPoint,
  });

  @override
  State<_AnimatedTripMap> createState() => _AnimatedTripMapState();
}

class _AnimatedTripMapState extends State<_AnimatedTripMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.hasPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<LatLng> _visibleTraveled() {
    if (widget.traveledPath.isEmpty) return const [];
    final count = (widget.traveledPath.length * _progress.value).ceil();
    if (count < 2) return const [];
    return widget.traveledPath.sublist(0, count.clamp(0, widget.traveledPath.length));
  }

  List<LatLng> _visiblePlanned() {
    if (widget.plannedRoute.isEmpty) return const [];
    final count = (widget.plannedRoute.length * _progress.value).ceil();
    if (count < 2) return const [];
    return widget.plannedRoute.sublist(0, count.clamp(0, widget.plannedRoute.length));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final visibleTraveled = _visibleTraveled();
        final visiblePlanned = _visiblePlanned();
        return FlutterMap(
          options: MapOptions(
            initialCenter: widget.mapCenter,
            initialZoom: widget.hasPath ? 13 : 2,
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.tileUrlTemplate,
              userAgentPackageName: 'com.stopco.app',
            ),
            if (visibleTraveled.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: visibleTraveled,
                    color: context.success,
                    strokeWidth: 5,
                  ),
                ],
              ),
            if (visiblePlanned.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: visiblePlanned,
                    color: context.textTertiary.withValues(alpha: 0.5),
                    strokeWidth: 2,
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),
            if (widget.destinationPoint != null && _progress.value > 0.9)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.destinationPoint!,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: context.error,
                        size: 30,
                      ),
                    ),
                  ),
                  if (widget.traveledPath.length > 1)
                    Marker(
                      point: widget.traveledPath.first,
                      child: Icon(
                        Icons.trip_origin_rounded,
                        color: context.success,
                        size: 26,
                      ),
                    )
                  else if (widget.plannedRoute.length > 1)
                    Marker(
                      point: widget.plannedRoute.first,
                      child: Icon(
                        Icons.trip_origin_rounded,
                        color: context.primary,
                        size: 26,
                      ),
                    ),
                ],
              ),
            SimpleAttributionWidget(
              source:
                  const Text('© OSM contributors · Routing by OSRM'),
              alignment: Alignment.bottomRight,
            ),
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.textTertiary),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyBold.copyWith(color: context.textPrimary),
        ),
      ],
    );
  }
}