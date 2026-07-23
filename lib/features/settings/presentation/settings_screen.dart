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
import '../../../core/components/app_input.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/tile_cache_providers.dart';
import '../../profile/data/profile_providers.dart';
import '../../simulation/presentation/simulation_screen.dart';
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
          const _ProfileSection(),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Alert Preferences',
            accentColor: const Color(0xFF0066FF),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          const _AlertPreferencesGroup().animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Nap Mode',
            accentColor: const Color(0xFF8E8E93),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: SwitchListTile(
              secondary: Icon(Icons.bedtime_rounded, color: Theme.of(context).colorScheme.primary),
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
            title: 'Commute Mode',
            accentColor: const Color(0xFF00A896),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          _CommuteModeSection(
            currentMode: settings.commuteMode,
          ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Simulation',
            accentColor: const Color(0xFFE67E22),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: ListTile(
              leading: Icon(Icons.science_rounded, color: Theme.of(context).colorScheme.primary),
              title: const Text('Test Trip Simulation'),
              subtitle: const Text('Simulate a trip with mock GPS data'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SimulationScreen()),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Offline Maps',
            accentColor: const Color(0xFF00A896),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          const _TileCacheSection().animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Appearance',
            accentColor: const Color(0xFF3F51B5),
          ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
          const SizedBox(height: AppSpacing.sm),
          _ThemeModeSection().animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0, duration: 280.ms),
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
          const SizedBox(height: AppSpacing.lg),
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

class _AlertPreferencesGroup extends ConsumerWidget {
  const _AlertPreferencesGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        children: [
          _buildRadiusSection(context, settings, notifier, cs),
          const Divider(height: 1, indent: AppSpacing.sm, endIndent: AppSpacing.sm),
          _buildAlarmTypeSection(context, settings, notifier, cs),
          const Divider(height: 1, indent: AppSpacing.sm, endIndent: AppSpacing.sm),
          SwitchListTile(
            secondary: Icon(Icons.replay_rounded, color: cs.primary, size: 20),
            title: const Text('Repeated Alarm'),
            subtitle: const Text('Alarm loops until deactivated'),
            value: settings.repeatedAlarm,
            onChanged: (_) => notifier.toggleRepeatedAlarm(),
            activeThumbColor: cs.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 1, indent: AppSpacing.sm, endIndent: AppSpacing.sm),
          ListTile(
            leading: Icon(Icons.music_note_rounded, color: cs.primary, size: 20),
            title: const Text('Alarm Sound'),
            subtitle: Text(
              _soundDisplayName(settings.customAlarmSoundPath),
              style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            trailing: settings.customAlarmSoundPath != null
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: cs.error, size: 18),
                    onPressed: () => notifier.clearCustomAlarmSound(),
                    tooltip: 'Reset to default',
                  )
                : Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.4)),
            onTap: () => _pickAlarmSound(context, ref, notifier),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSection(BuildContext context, AppSettings settings, SettingsNotifier notifier, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten_rounded, size: 18, color: cs.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Default Alert Radius', style: AppTypography.bodyBold.copyWith(color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'The default radius for new destinations',
            style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: AppConstants.alertRadiusOptions.map((radius) {
              final selected = radius == settings.defaultAlertRadius;
              return ChoiceChip(
                label: Text('${radius.round()}m'),
                selected: selected,
                onSelected: (_) => notifier.setDefaultAlertRadius(radius),
                selectedColor: cs.primary,
                labelStyle: TextStyle(
                  color: selected ? cs.surface : cs.onSurface,
                ),
                backgroundColor: cs.surfaceContainerLow,
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

  Widget _buildAlarmTypeSection(BuildContext context, AppSettings settings, SettingsNotifier notifier, ColorScheme cs) {
    final colors = <AlarmType, Color>{
      AlarmType.soundAndVibration: const Color(0xFF0066FF),
      AlarmType.soundOnly: const Color(0xFFFF6B35),
      AlarmType.vibrationOnly: const Color(0xFF8E8E93),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded, size: 18, color: cs.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Alarm Type', style: AppTypography.bodyBold.copyWith(color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'How you want to be alerted',
            style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<AlarmType>(
            segments: AlarmType.values
                .map(
                  (type) => ButtonSegment<AlarmType>(
                    value: type,
                    label: Text(type.label),
                    icon: Icon(_alarmTypeIcon(type), size: 16),
                  ),
                )
                .toList(),
            selected: {settings.alarmType},
            onSelectionChanged: (selected) => notifier.setAlarmType(selected.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: colors[settings.alarmType],
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _alarmTypeDescription(settings.alarmType),
            style: AppTypography.caption.copyWith(
              color: colors[settings.alarmType],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _alarmTypeIcon(AlarmType type) {
    switch (type) {
      case AlarmType.soundAndVibration:
        return Icons.vibration_rounded;
      case AlarmType.soundOnly:
        return Icons.volume_up_rounded;
      case AlarmType.vibrationOnly:
        return Icons.vibration_rounded;
    }
  }

  String _alarmTypeDescription(AlarmType type) {
    switch (type) {
      case AlarmType.soundAndVibration:
        return 'Full alert with sound and vibration';
      case AlarmType.soundOnly:
        return 'Sound alert only';
      case AlarmType.vibrationOnly:
        return 'Vibration alert only (silent)';
    }
  }

  String _soundDisplayName(String? currentPath) {
    if (currentPath == null) return 'Default';
    if (currentPath.startsWith('content://') || currentPath.contains('/alarms/')) {
      return 'Custom sound';
    }
    final segments = currentPath.split('/');
    final fileName = segments.last;
    return fileName.length > 24 ? '${fileName.substring(0, 21)}...' : fileName;
  }

  Future<void> _pickAlarmSound(BuildContext context, WidgetRef ref, SettingsNotifier notifier) async {
    try {
      final nativePath = await FilePickerChannel.pickAudioFile();
      if (nativePath != null && nativePath.isNotEmpty) {
        notifier.setCustomAlarmSound(nativePath);
        return;
      }
      if (nativePath == '') return;
    } on MissingPluginException {
      // platform not supported, fall through to manual dialog
    }

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found')),
      );
      return;
    }

    notifier.setCustomAlarmSound(result);
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
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.notifications_active_rounded, color: cs.primary.withValues(alpha: 0.5), size: 32),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppConstants.appName,
          style: AppTypography.title.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Version 1.0.0',
          style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.35)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'For commuters, by commuters — a minimalist GPS destination alarm.',
          style: AppTypography.secondary.copyWith(color: cs.onSurface.withValues(alpha: 0.45)),
          textAlign: TextAlign.center,
        ),
      ],
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

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection();

  String _initials(String? nickname) {
    if (nickname == null || nickname.isEmpty) return '?';
    final parts = nickname.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return nickname[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nicknameAsync = ref.watch(nicknameProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        _SectionHeader(
          title: 'Profile',
          accentColor: cs.primary,
        ).animate().fadeIn().slideX(begin: -0.08, end: 0, duration: 280.ms),
        const SizedBox(height: AppSpacing.sm),
        nicknameAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (nickname) => AppCard(
            onTap: () => _showChangeDialog(context, ref, nickname ?? ''),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primary,
                  child: Text(
                    _initials(nickname),
                    style: AppTypography.sectionHeader.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname ?? 'Set a nickname',
                        style: AppTypography.bodyBold.copyWith(color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nickname == null ? 'Tap to set' : 'Tap to change',
                        style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showChangeDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change nickname'),
        content: AppInput(
          controller: controller,
          hint: 'New nickname',
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.length < 2 || text.length > 20) return;
              ref.read(updateNicknameActionProvider(text).future);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TileCacheSection extends ConsumerWidget {
  const _TileCacheSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(tileCacheStatsProvider);
    final cs = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.map_rounded, size: 18, color: cs.primary),
                const SizedBox(width: AppSpacing.xs),
                Text('Tile Cache', style: AppTypography.bodyBold.copyWith(color: cs.onSurface)),
              ],
            ),
          ),
          const Divider(height: 1, indent: AppSpacing.sm, endIndent: AppSpacing.sm),
          statsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Failed to load cache stats', style: AppTypography.caption.copyWith(color: cs.error)),
            ),
            data: (stats) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(Icons.storage_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${stats.count} tiles cached',
                        style: AppTypography.secondary.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                      ),
                      const Spacer(),
                      Text(
                        _formatBytes(stats.sizeBytes),
                        style: AppTypography.secondary.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: AppSpacing.sm, endIndent: AppSpacing.sm),
                ListTile(
                  leading: Icon(Icons.delete_sweep_rounded, color: cs.error, size: 20),
                  title: Text('Clear Cache', style: AppTypography.secondary.copyWith(color: cs.error)),
                  subtitle: Text(
                    'Removes all cached map tiles',
                    style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.4), size: 18),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Map Cache?'),
                        content: const Text('Cached map tiles will be removed. They will be re-downloaded when you view the map while online.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(tileCacheServiceProvider).clearCache();
                      ref.invalidate(tileCacheStatsProvider);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
