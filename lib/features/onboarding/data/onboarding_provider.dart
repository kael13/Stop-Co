import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingKey = 'onboarding_completed';
const _brandIntroKey = 'brand_intro_shown';

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingKey) ?? false;
});

final brandIntroShownProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_brandIntroKey) ?? false;
});

Future<void> completeOnboarding(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingKey, true);
  ref.invalidate(onboardingCompletedProvider);
}

Future<void> completeBrandIntro(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_brandIntroKey, true);
  ref.invalidate(brandIntroShownProvider);
}
