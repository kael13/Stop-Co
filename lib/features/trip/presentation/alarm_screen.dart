import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/components/app_button.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/gps_utils.dart';
import '../../settings/data/settings_providers.dart';
import '../../simulation/data/simulation_service.dart';
import '../../../core/platform/foreground_service_channel.dart';
import '../data/alarm_notification_service.dart';
import '../data/trip_providers.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _repeatTimer;

  @override
  void initState() {
    super.initState();
    _fireInitialVibration();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startRepeatingAlarm();
  }

  void _startRepeatingAlarm() {
    _repeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final settings = ref.read(settingsProvider);
      if (!settings.repeatedAlarm) return;

      final alarmType = settings.alarmType;
      final currentTrip = ref.read(activeTripProvider);
      if (currentTrip == null) return;

      if (alarmType != AlarmType.vibrationOnly) {
        AlarmNotificationService.showAlarmNotification(
          destinationName: currentTrip.currentWaypoint.name,
          distance: currentTrip.currentDistance ?? 0,
          alarmType: alarmType,
          customSoundPath: settings.customAlarmSoundPath,
          fullScreenIntent: false,
        );
      }
      if (alarmType != AlarmType.soundOnly) {
        _fireNapAwareVibration();
      }
    });
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _repeatTimer?.cancel();
    AlarmNotificationService.dismissAlarm();
    ScreenBrightness().resetApplicationScreenBrightness();
    WakelockPlus.disable();

    final trip = ref.read(activeTripProvider);
    if (trip == null) return;

    final isLastStop = trip.currentWaypointIndex >= trip.waypoints.length - 1;

    final simulationEnabled = ref.read(simulationEnabledProvider);

    if (isLastStop) {
      ForegroundServiceChannel.stopTracking();
      if (simulationEnabled) {
        ref.read(simulationServiceProvider).stop();
        ref.read(simulationEnabledProvider.notifier).state = false;
      }
      ref.read(activeTripProvider.notifier).completeTrip();
      Navigator.pushReplacementNamed(context, '/trip-complete');
    } else {
      if (simulationEnabled) {
        final simService = ref.read(simulationServiceProvider);
        final pos = simService.currentPosition;
        final nextWp = trip.waypoints[trip.currentWaypointIndex + 1];
        if (pos != null) {
          simService.start(
            destinationLatitude: nextWp.latitude,
            destinationLongitude: nextWp.longitude,
            destinationName: nextWp.name,
            startLatitude: pos.latitude,
            startLongitude: pos.longitude,
            speedMps: ref.read(settingsProvider).simulationSpeedMps,
          );
        }
      }
      ref.read(activeTripProvider.notifier).advanceToNextWaypoint();
      Navigator.pushReplacementNamed(context, '/active-trip');
    }
  }

  void _fireInitialVibration() {
    final settings = ref.read(settingsProvider);
    if (settings.napModeEnabled) {
      _fireNapAwareVibration();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _fireNapAwareVibration() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 600), () {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 400), () {
        HapticFeedback.heavyImpact();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider);

    if (trip == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _dismiss());
      return const SizedBox();
    }

    final distance = trip.currentDistance ?? 0;
    final distanceFormatted = GpsUtils.formatDistance(distance);
    final wp = trip.currentWaypoint;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'You are approaching',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                wp.name,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (trip.hasMultipleStops)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: context.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'Stop ${trip.currentWaypointIndex + 1} of ${trip.totalStops}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                distanceFormatted,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                trip.hasMultipleStops
                    ? 'Next stop ahead'
                    : 'Get ready to get off soon',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(flex: 3),
              AppButton(
                label: 'Dismiss Alarm',
                onPressed: _dismiss,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
