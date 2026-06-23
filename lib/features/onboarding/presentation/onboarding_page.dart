import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_spacing.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget visual;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 280,
            width: 280,
            child: visual,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
              .slideY(
                begin: 0.06,
                end: 0,
                duration: 380.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 140.ms, duration: 380.ms)
              .slideY(
                begin: 0.06,
                end: 0,
                duration: 380.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }
}