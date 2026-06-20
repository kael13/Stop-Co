import 'package:flutter/material.dart';
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
    final routeCoords = trip.routeCoordinates;
    final destinationPoint =
        routeCoords.isNotEmpty ? routeCoords.last : null;
    final hasRoute = routeCoords.isNotEmpty;

    final mapCenter = hasRoute
        ? LatLng(
            (routeCoords.first.latitude + routeCoords.last.latitude) / 2,
            (routeCoords.first.longitude + routeCoords.last.longitude) / 2,
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
            child: FlutterMap(
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: hasRoute ? 13 : 2,
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.tileUrlTemplate,
                  userAgentPackageName: 'com.stopco.app',
                ),
                if (hasRoute)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routeCoords,
                        color: _statusColor(context).withValues(alpha: 0.6),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (destinationPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: destinationPoint,
                        child: Icon(
                          Icons.location_on_rounded,
                          color: context.error,
                          size: 36,
                        ),
                      ),
                      if (routeCoords.length > 1)
                        Marker(
                          point: routeCoords.first,
                          child: Icon(
                            Icons.trip_origin_rounded,
                            color: context.primary,
                            size: 28,
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
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(
                  children: [
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
                ),
                const SizedBox(height: AppSpacing.lg),
                _DetailRow(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: distanceFormatted,
                ),
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(
                  icon: Icons.timer_rounded,
                  label: 'Duration',
                  value: duration,
                ),
                if (trip.plannedRouteDistance != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.route_rounded,
                    label: 'Planned route',
                    value: GpsUtils.formatDistance(
                        trip.plannedRouteDistance!),
                  ),
                ],
                if (trip.plannedRouteDuration != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'ETA',
                    value: _formatDuration(
                      Duration(seconds: trip.plannedRouteDuration!.round()),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Started',
                  value: _formatDate(trip.startedAt),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(
                  icon: Icons.flag_rounded,
                  label: 'Ended',
                  value: _formatDate(trip.endedAt),
                ),
              ],
            ),
          ),
        ],
      ),
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
