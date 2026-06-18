import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_active_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
