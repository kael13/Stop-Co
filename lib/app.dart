import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/platform/reminder_alarm_callback_channel.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/theme_colors.dart';
import 'core/theme/theme_providers.dart';
import 'features/home/presentation/main_shell.dart';
import 'features/onboarding/data/onboarding_provider.dart';
import 'features/onboarding/presentation/brand_intro_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/profile/data/profile_providers.dart';
import 'features/profile/presentation/nickname_setup_screen.dart';
import 'features/scheduled_trip/data/scheduled_trip.dart';
import 'features/scheduled_trip/data/scheduled_trip_providers.dart';
import 'features/scheduled_trip/presentation/scheduled_trip_detail_screen.dart';
import 'features/trip/presentation/active_trip_screen.dart';
import 'features/trip/presentation/alarm_screen.dart';
import 'features/trip/presentation/trip_complete_screen.dart';
import 'main.dart';

class StopCoApp extends StatelessWidget {
  const StopCoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      return MaterialApp(
        title: AppConstants.appName,
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ref.watch(themeModeProvider),
        home: const _AppShell(),
        routes: {
          '/active-trip': (_) => const ActiveTripScreen(),
          '/alarm': (_) => const AlarmScreen(),
          '/trip-complete': (_) => const TripCompleteScreen(),
          '/scheduled-trip-detail': (_) => const _ScheduledTripDetailWrapper(),
        },
      );
    });
  }
}

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _drainAlarmTriggers();
    }
  }

  Future<void> _drainAlarmTriggers() async {
    final triggers = await ReminderAlarmCallbackChannel.drainPendingTriggers();
    for (final entry in triggers.entries) {
      ref.read(markAlarmTriggeredAction(entry.key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = ref.watch(onboardingCompletedProvider);
    final nicknameAsync = ref.watch(nicknameProvider);

    return onboardingAsync.when(
      loading: () => const _SplashScreen(),
      error: (_, _) => const _SplashScreen(),
      data: (onboarded) {
        if (!onboarded) return const _OnboardingGate();
        return nicknameAsync.when(
          loading: () => const _SplashScreen(),
          error: (_, _) => const MainShell(),
          data: (nickname) {
            if (nickname != null) return const MainShell();
            return const NicknameSetupScreen();
          },
        );
      },
    );
  }
}

class _OnboardingGate extends ConsumerWidget {
  const _OnboardingGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandIntroAsync = ref.watch(brandIntroShownProvider);
    return brandIntroAsync.when(
      loading: () => const _SplashScreen(),
      error: (_, _) => const OnboardingScreen(),
      data: (brandShown) {
        if (!brandShown) {
          return BrandIntroScreen(
            onComplete: () {
              ref.invalidate(brandIntroShownProvider);
            },
          );
        }
        return const OnboardingScreen();
      },
    );
  }
}

class _ScheduledTripDetailWrapper extends ConsumerStatefulWidget {
  const _ScheduledTripDetailWrapper();

  @override
  ConsumerState<_ScheduledTripDetailWrapper> createState() => _ScheduledTripDetailWrapperState();
}

class _ScheduledTripDetailWrapperState extends ConsumerState<_ScheduledTripDetailWrapper> {
  bool _didMark = false;

  @override
  Widget build(BuildContext context) {
    final tripId = ModalRoute.of(context)!.settings.arguments as String;
    final tripsAsync = ref.watch(scheduledTripsProvider);

    return tripsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (trips) {
        final matches = trips.where((t) => t.id == tripId);
        if (matches.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
          return const Scaffold(
            body: Center(child: Text('Trip not found')),
          );
        }
        final trip = matches.first;
        if (!_didMark && !trip.alarmTriggered && trip.status == ScheduledTripStatus.pending) {
          _didMark = true;
          ref.read(markAlarmTriggeredAction(tripId).future);
        }
        return ScheduledTripDetailScreen(trip: trip);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: context.primary,
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: AppTypography.title.copyWith(color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                "Don't miss your stop",
                style: AppTypography.body.copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
