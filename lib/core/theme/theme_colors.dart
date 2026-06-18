import 'package:flutter/material.dart';

extension ThemeColors on BuildContext {
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get onPrimary => Theme.of(this).colorScheme.onPrimary;
  Color get secondary => Theme.of(this).colorScheme.secondary;
  Color get onSecondary => Theme.of(this).colorScheme.onSecondary;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
  Color get error => Theme.of(this).colorScheme.error;
  Color get onError => Theme.of(this).colorScheme.onError;
  Color get surfaceContainerLow => Theme.of(this).colorScheme.surfaceContainerLow;
  Color get surfaceContainerHigh => Theme.of(this).colorScheme.surfaceContainerHigh;
  Color get outlineVariant => Theme.of(this).colorScheme.outlineVariant;
  Color get scaffoldBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get textPrimary => onSurface;
  Color get textSecondary => onSurface.withValues(alpha: 0.6);
  Color get textTertiary => onSurface.withValues(alpha: 0.4);
  Color get textInverse => surface;

  Color get success => const Color(0xFF34C759);
  Color get warning => const Color(0xFFFFB340);

  Color get shimmerBase => surfaceContainerLow;
  Color get shimmerHighlight => surfaceContainerHigh;

  Brightness get brightness => Theme.of(this).brightness;
  bool get isDark => brightness == Brightness.dark;
}
