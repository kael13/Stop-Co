import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../features/destination/presentation/destination_setup_screen.dart';
import 'scheduled_trip_detail_screen.dart';
import '../data/scheduled_trip.dart';
import '../data/scheduled_trip_providers.dart';

class SchedulesListView extends ConsumerWidget {
  const SchedulesListView({super.key});

  Color _statusColor(ScheduledTripStatus status, ColorScheme cs) {
    switch (status) {
      case ScheduledTripStatus.pending:
        return cs.primary;
      case ScheduledTripStatus.completed:
        return const Color(0xFF34C759);
      case ScheduledTripStatus.cancelled:
        return cs.onSurface.withValues(alpha: 0.4);
    }
  }

  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Today';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(scheduledTripsProvider);
    final cs = Theme.of(context).colorScheme;

    return tripsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (trips) {
        if (trips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.25)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No scheduled trips',
                    style: AppTypography.body.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Plan your trip and set a reminder.',
                    style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Schedule a New Trip',
                    icon: Icons.calendar_month_rounded,
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
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            final statusColor = _statusColor(trip.status, cs);
            final waypoints = trip.waypoints;
            final dateLabel = _formatDate(trip.scheduledStartTime);
            final timeLabel = _formatTime(trip.scheduledStartTime);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduledTripDetailScreen(trip: trip),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('d').format(trip.scheduledStartTime),
                            style: AppTypography.bodyBold.copyWith(
                              color: statusColor,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(trip.scheduledStartTime),
                            style: AppTypography.caption.copyWith(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.name,
                            style: AppTypography.bodyBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dateLabel · $timeLabel · ${waypoints.length} stop${waypoints.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            trip.status.label,
                            style: AppTypography.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: cs.onSurface.withValues(alpha: 0.25),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
