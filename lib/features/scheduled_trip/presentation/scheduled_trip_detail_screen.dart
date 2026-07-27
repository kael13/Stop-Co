import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'schedule_trip_form_screen.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../data/scheduled_trip.dart';
import '../data/scheduled_trip_providers.dart';

class ScheduledTripDetailScreen extends ConsumerWidget {
  final ScheduledTrip trip;

  const ScheduledTripDetailScreen({super.key, required this.trip});

  Color _statusColor(ColorScheme cs) {
    switch (trip.status) {
      case ScheduledTripStatus.pending:
        return cs.primary;
      case ScheduledTripStatus.completed:
        return const Color(0xFF34C759);
      case ScheduledTripStatus.cancelled:
        return cs.onSurface.withValues(alpha: 0.4);
    }
  }

  String _formattedDateTime() {
    final d = DateFormat('EEEE, MMMM d, yyyy').format(trip.scheduledStartTime);
    final t = DateFormat('h:mm a').format(trip.scheduledStartTime);
    return '$d at $t';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(cs);
    final waypoints = trip.waypoints;

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
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
                    Icon(Icons.calendar_month_rounded, color: cs.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _formattedDateTime(),
                        style: AppTypography.bodyBold.copyWith(color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
                if (trip.description != null && trip.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    trip.description!,
                    style: AppTypography.body.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: cs.primary, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Reminder: ${trip.remindBefore.label}',
                      style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            ),
            child: Text(
              trip.status.label,
              style: AppTypography.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Stops (${waypoints.length})',
            style: AppTypography.sectionHeader.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...waypoints.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: AppTypography.bodyBold.copyWith(color: cs.onPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value.name,
                        style: AppTypography.bodyBold.copyWith(color: cs.onSurface),
                      ),
                      Text(
                        '${entry.value.alertRadius.round()}m radius',
                        style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          if (trip.status == ScheduledTripStatus.pending) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Start Trip Now',
              icon: Icons.near_me_rounded,
              onPressed: () {
                ref.read(scheduledTripNotificationServiceProvider)
                    .cancelReminder(trip.id);
                ref.read(startScheduledTripAction(trip).future);
                Navigator.pushNamed(context, '/active-trip');
              },
              width: double.infinity,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Mark as Completed',
              icon: Icons.check_circle_outline,
              onPressed: () async {
                ref.read(scheduledTripNotificationServiceProvider)
                    .cancelReminder(trip.id);
                await ref.read(completeScheduledTripAction(trip.id).future);
                if (context.mounted) Navigator.pop(context);
              },
              width: double.infinity,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancel Schedule',
              icon: Icons.cancel_outlined,
              isDestructive: true,
              onPressed: () async {
                ref.read(scheduledTripNotificationServiceProvider)
                    .cancelReminder(trip.id);
                await ref.read(cancelScheduledTripAction(trip.id).future);
                if (context.mounted) Navigator.pop(context);
              },
              width: double.infinity,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleTripFormScreen(
                      waypoints: waypoints,
                      existingTrip: trip,
                    ),
                  ),
                );
              },
              child: const Text('Edit Schedule'),
            ),
          ],
          if (trip.status != ScheduledTripStatus.pending) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Schedule'),
                    content: Text('Delete "${trip.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: cs.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(scheduledTripNotificationServiceProvider)
                      .cancelReminder(trip.id);
                  await ref.read(deleteScheduledTripAction(trip.id).future);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(
                'Delete Schedule',
                style: TextStyle(color: cs.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
