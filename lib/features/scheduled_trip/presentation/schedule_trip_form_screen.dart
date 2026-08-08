import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/app_input.dart';
import '../../../core/utils/permission_helper.dart';
import '../../trip/data/waypoint.dart';
import '../data/scheduled_trip.dart';
import '../data/scheduled_trip_providers.dart';

class ScheduleTripFormScreen extends ConsumerStatefulWidget {
  final List<Waypoint> waypoints;
  final ScheduledTrip? existingTrip;

  const ScheduleTripFormScreen({
    super.key,
    required this.waypoints,
    this.existingTrip,
  });

  @override
  ConsumerState<ScheduleTripFormScreen> createState() => _ScheduleTripFormScreenState();
}

class _ScheduleTripFormScreenState extends ConsumerState<ScheduleTripFormScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _uuid = const Uuid();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTrip != null) {
      final t = widget.existingTrip!;
      _nameController.text = t.name;
      _descController.text = t.description ?? '';
      _selectedDate = t.scheduledStartTime;
      _selectedTime = TimeOfDay.fromDateTime(t.scheduledStartTime);
    } else if (widget.waypoints.isNotEmpty) {
      _nameController.text = widget.waypoints.first.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final scheduledStart = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final trip = ScheduledTrip(
        id: widget.existingTrip?.id ?? _uuid.v4(),
        name: name,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        waypointsJson: Waypoint.serializeList(widget.waypoints) ?? '[]',
        scheduledStartTime: scheduledStart,
        status: widget.existingTrip?.status ?? ScheduledTripStatus.pending,
        createdAt: widget.existingTrip?.createdAt ?? DateTime.now(),
      );

      await ref.read(createScheduledTripAction(trip).future);
      if (!mounted) return;

      final granted = await PermissionHelper.requestNotificationPermission();
      if (granted) {
        final notif = ref.read(scheduledTripNotificationServiceProvider);
        await notif.scheduleReminder(trip);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied — reminder will not fire')),
        );
      }

      if (!mounted) return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save schedule: $e')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('Trip Scheduled', style: AppTypography.title),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop('scheduled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTrip != null ? 'Edit Schedule' : 'Schedule Trip'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Date', style: AppTypography.sectionHeader.copyWith(color: cs.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 1)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              onDaySelected: (selected, _) => setState(() => _selectedDate = selected),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                titleTextStyle: AppTypography.bodyBold.copyWith(color: cs.onSurface),
                formatButtonTextStyle: AppTypography.caption.copyWith(color: cs.primary),
                formatButtonDecoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                leftChevronIcon: Icon(Icons.chevron_left_rounded, color: cs.primary),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, color: cs.primary),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary, width: 2),
                ),
                todayTextStyle: AppTypography.body.copyWith(color: cs.primary),
                defaultTextStyle: AppTypography.body.copyWith(color: cs.onSurface),
                weekendTextStyle: AppTypography.body.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                outsideTextStyle: AppTypography.body.copyWith(color: cs.onSurface.withValues(alpha: 0.3)),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                weekendStyle: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Time', style: AppTypography.sectionHeader.copyWith(color: cs.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: _pickTime,
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, color: cs.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _selectedTime.format(context),
                  style: AppTypography.bodyBold.copyWith(color: cs.onSurface),
                ),
                const Spacer(),
                Icon(Icons.edit_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Remind me', style: AppTypography.sectionHeader.copyWith(color: cs.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Row(
              children: [
                Icon(Icons.notifications_rounded, color: cs.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'An hour before',
                    style: AppTypography.bodyBold.copyWith(color: cs.onSurface),
                  ),
                ),
                Tooltip(
                  message: 'A reminder will be sent 1 hour before your scheduled departure.',
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Trip Name', style: AppTypography.sectionHeader.copyWith(color: cs.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          AppInput(
            controller: _nameController,
            hint: 'e.g. Work commute',
            prefixIcon: Icons.edit_location_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Description (optional)', style: AppTypography.sectionHeader.copyWith(color: cs.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              hintText: 'Notes for this trip...',
              prefixIcon: Icon(Icons.notes_rounded, color: cs.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: cs.primary),
              ),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${widget.waypoints.length} stop${widget.waypoints.length == 1 ? '' : 's'}',
            style: AppTypography.secondary.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...widget.waypoints.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: AppTypography.caption.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.value.name,
                    style: AppTypography.body.copyWith(color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${entry.value.alertRadius.round()}m',
                  style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          )),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: widget.existingTrip != null ? 'Update Schedule' : 'Save Schedule',
            icon: Icons.calendar_month_rounded,
            isLoading: _isSaving,
            onPressed: _save,
            width: double.infinity,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
