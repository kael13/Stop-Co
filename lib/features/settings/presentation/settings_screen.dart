import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/app_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../data/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionHeader(title: 'Alert Preferences'),
          const SizedBox(height: AppSpacing.sm),
          _DefaultRadiusSection(
            currentRadius: settings.defaultAlertRadius,
            onChanged: (radius) {
              ref.read(settingsProvider.notifier).setDefaultAlertRadius(radius);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _AlarmTypeSection(
            currentType: settings.alarmType,
            onChanged: (type) {
              ref.read(settingsProvider.notifier).setAlarmType(type);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: SwitchListTile(
              title: const Text('Repeated Alarm'),
              subtitle: const Text('Alarm loops until deactivated'),
              value: settings.repeatedAlarm,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleRepeatedAlarm();
              },
              activeThumbColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: 'Appearance'),
          const SizedBox(height: AppSpacing.sm),
          _ThemeModeSection(),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: 'Commute Mode'),
          const SizedBox(height: AppSpacing.sm),
          _CommuteModeSection(
            currentMode: settings.commuteMode,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: 'About'),
          const SizedBox(height: AppSpacing.sm),
          _AboutSection(),
          const SizedBox(height: AppSpacing.lg),
          _ResetButton(
            onReset: () {
              ref.read(settingsProvider.notifier).reset();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _DefaultRadiusSection extends StatelessWidget {
  final double currentRadius;
  final ValueChanged<double> onChanged;

  const _DefaultRadiusSection({
    required this.currentRadius,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Alert Radius',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'The default radius for new destinations',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: AppConstants.alertRadiusOptions.map((radius) {
              final selected = radius == currentRadius;
              return ChoiceChip(
                label: Text('${radius.round()}m'),
                selected: selected,
                onSelected: (_) => onChanged(radius),
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: selected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
                ),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AlarmTypeSection extends StatelessWidget {
  final AlarmType currentType;
  final ValueChanged<AlarmType> onChanged;

  const _AlarmTypeSection({
    required this.currentType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alarm Type',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'How you want to be alerted',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...AlarmType.values.map((type) {
            return RadioListTile<AlarmType>(
              title: Text(type.label),
              subtitle: Text(
                _getAlarmDescription(type),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              value: type,
              groupValue: currentType,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              activeColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  String _getAlarmDescription(AlarmType type) {
    switch (type) {
      case AlarmType.soundAndVibration:
        return 'Full alert with sound and vibration';
      case AlarmType.soundOnly:
        return 'Sound alert only';
      case AlarmType.vibrationOnly:
        return 'Vibration alert only (silent)';
    }
  }
}

class _CommuteModeSection extends StatelessWidget {
  final CommuteMode currentMode;

  const _CommuteModeSection({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    final speeds = <CommuteMode, double>{
      CommuteMode.walking: 0.0,
      CommuteMode.bus: 7.0,
      CommuteMode.car: 40.0,
      CommuteMode.train: 80.0,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Commute Mode',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Auto',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Automatically detected from your GPS speed while tracking.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: CommuteMode.values.map((mode) {
                final isActive = mode == currentMode;
                final thresholdKmh = speeds[mode]!;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: mode == CommuteMode.values.last ? 0 : AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mode == CommuteMode.walking
                            ? Icons.directions_walk_rounded
                            : mode == CommuteMode.bus
                                ? Icons.directions_bus_rounded
                                : mode == CommuteMode.train
                                    ? Icons.directions_train_rounded
                                    : Icons.directions_car_rounded,
                        size: 18,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mode.label,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            Text(
                              mode == CommuteMode.walking
                                  ? '< 7 km/h'
                                  : '${thresholdKmh.toStringAsFixed(0)}+ km/h',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppConstants.appName,
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
                   color: Theme.of(context).colorScheme.onSurface,
                 ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A minimalist GPS-based destination alarm app for commuters.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.settings_suggest_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined, size: 18),
              ),
            ],
            selected: {current},
            onSelectionChanged: (selected) {
              ref.read(themeModeProvider.notifier).setThemeMode(selected.first);
            },
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onReset;

  const _ResetButton({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onReset,
      child: Text(
        'Reset to Defaults',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
