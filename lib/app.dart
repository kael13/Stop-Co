import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_colors.dart';
import 'core/theme/theme_providers.dart';
import 'features/auth/data/auth_providers.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/home/presentation/main_shell.dart';
import 'features/onboarding/data/onboarding_provider.dart';
import 'features/onboarding/presentation/brand_intro_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/trip/presentation/active_trip_screen.dart';
import 'features/trip/presentation/alarm_screen.dart';
import 'main.dart';

class StopCoApp extends ConsumerWidget {
  const StopCoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingCompletedProvider);
    final authAsync = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: onboardingAsync.when(
        loading: () => const _SplashScreen(),
        error: (_, _) => const AuthScreen(),
        data: (onboarded) {
          if (!onboarded) return const _OnboardingGate();
          return authAsync.when(
            loading: () => const _SplashScreen(),
            error: (_, _) => const AuthScreen(),
            data: (user) {
              if (user != null) return const MainShell();
              return const AuthScreen();
            },
          );
        },
      ),
      routes: {
        '/active-trip': (_) => const ActiveTripScreen(),
        '/alarm': (_) => const AlarmScreen(),
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primary,
              context.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
                    .scaleXY(
                      begin: 0.8,
                      end: 1.0,
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.1, end: 0, duration: 500.ms),
                const SizedBox(height: 8),
                Text(
                  "Don't miss your stop",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ).animate().fadeIn(delay: 360.ms, duration: 400.ms),
                const SizedBox(height: 32),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
