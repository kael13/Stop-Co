import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/app_card.dart';
import '../../../core/platform/file_picker_channel.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart' show recreateAlarmChannel;
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
          _SectionHeader(
            title: 'Alert Preferences',
            accentColor: const Color(0xFF0066FF),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          _DefaultRadiusSection(
            currentRadius: settings.defaultAlertRadius,
            onChanged: (radius) {
              ref.read(settingsProvider.notifier).setDefaultAlertRadius(radius);
            },
          ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.md),
          _AlarmTypeSection(
            currentType: settings.alarmType,
            onChanged: (type) {
              ref.read(settingsProvider.notifier).setAlarmType(type);
            },
          ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
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
          ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.md),
          _CustomAlarmSoundTile(
            currentPath: settings.customAlarmSoundPath,
            onSelected: (path) {
              ref.read(settingsProvider.notifier).setCustomAlarmSound(path);
              recreateAlarmChannel(path);
            },
            onClear: () {
              ref.read(settingsProvider.notifier).clearCustomAlarmSound();
              recreateAlarmChannel(null);
            },
          ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Nap Mode',
            accentColor: const Color(0xFF8E8E93),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: SwitchListTile(
              title: const Text('Enable Nap Mode'),
              subtitle: const Text('Dims screen and extends vibration when active'),
              value: settings.napModeEnabled,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleNapMode();
              },
              activeThumbColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Appearance',
            accentColor: const Color(0xFF3F51B5),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          _ThemeModeSection().animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Commute Mode',
            accentColor: const Color(0xFF00A896),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          _CommuteModeSection(
            currentMode: settings.commuteMode,
          ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'About',
            accentColor: const Color(0xFF8E8E93),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          _AboutSection().animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
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
  final Color accentColor;

  const _SectionHeader({
    required this.title,
    this.accentColor = const Color(0xFF0066FF),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    final colors = <AlarmType, Color>{
      AlarmType.soundAndVibration: const Color(0xFF0066FF),
      AlarmType.soundOnly: const Color(0xFFFF6B35),
      AlarmType.vibrationOnly: const Color(0xFF8E8E93),
    };

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
          SegmentedButton<AlarmType>(
            segments: AlarmType.values
                .map(
                  (type) => ButtonSegment<AlarmType>(
                    value: type,
                    label: Text(type.label),
                    icon: Icon(_getAlarmIcon(type), size: 16),
                  ),
                )
                .toList(),
            selected: {currentType},
            onSelectionChanged: (selected) => onChanged(selected.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: colors[currentType],
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _getAlarmDescription(currentType),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors[currentType],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAlarmIcon(AlarmType type) {
    switch (type) {
      case AlarmType.soundAndVibration:
        return Icons.vibration_rounded;
      case AlarmType.soundOnly:
        return Icons.volume_up_rounded;
      case AlarmType.vibrationOnly:
        return Icons.vibration_rounded;
    }
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

class _CustomAlarmSoundTile extends ConsumerWidget {
  final String? currentPath;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  const _CustomAlarmSoundTile({
    required this.currentPath,
    required this.onSelected,
    required this.onClear,
  });

  String get _displayName {
    if (currentPath == null) return 'Default';
    if (currentPath!.startsWith('content://')) {
      return 'Custom sound';
    }
    final segments = currentPath!.split('/');
    final fileName = segments.last;
    return fileName.length > 24
        ? '${fileName.substring(0, 21)}...'
        : fileName;
  }

  Future<void> _pickFile(BuildContext ctx) async {
    try {
      final nativePath = await FilePickerChannel.pickAudioFile();
      if (nativePath != null && nativePath.isNotEmpty) {
        onSelected(nativePath);
        return;
      }
      if (nativePath == '') return; // user cancelled native picker
    } on MissingPluginException {
      // platform not supported, fall through to manual dialog
    }

    // Fallback: manual path input
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: const Text('Alarm Sound Path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '/storage/emulated/0/Music/alert.mp3',
            labelText: 'File path',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;

    final sourceFile = File(result);
    if (!await sourceFile.exists()) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('File not found')),
      );
      return;
    }

    onSelected(result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: ListTile(
        title: const Text('Alarm Sound'),
        subtitle: Text(
          _displayName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        leading: Icon(
          Icons.music_note_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        trailing: currentPath != null
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: onClear,
                tooltip: 'Reset to default',
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: () => _pickFile(context),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
