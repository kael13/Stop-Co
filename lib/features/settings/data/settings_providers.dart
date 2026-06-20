import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

enum AlarmType { soundAndVibration, soundOnly, vibrationOnly }

extension AlarmTypeExtension on AlarmType {
  String get label {
    switch (this) {
      case AlarmType.soundAndVibration:
        return 'Sound & Vibration';
      case AlarmType.soundOnly:
        return 'Sound Only';
      case AlarmType.vibrationOnly:
        return 'Vibration Only';
    }
  }
}

enum CommuteMode { walking, bus, train, car }

extension CommuteModeExtension on CommuteMode {
  String get label {
    switch (this) {
      case CommuteMode.walking:
        return 'Walking';
      case CommuteMode.bus:
        return 'Bus';
      case CommuteMode.train:
        return 'Train';
      case CommuteMode.car:
        return 'Car';
    }
  }

  double get simulationSpeedMps {
    switch (this) {
      case CommuteMode.walking:
        return 1.4;
      case CommuteMode.bus:
        return 8.3;
      case CommuteMode.train:
        return 22.2;
      case CommuteMode.car:
        return 13.9;
    }
  }
}

class AppSettings {
  final double defaultAlertRadius;
  final AlarmType alarmType;
  final CommuteMode commuteMode;
  final bool repeatedAlarm;
  final bool napModeEnabled;
  final String? customAlarmSoundPath;

  const AppSettings({
    this.defaultAlertRadius = 300,
    this.alarmType = AlarmType.soundAndVibration,
    this.commuteMode = CommuteMode.walking,
    this.repeatedAlarm = false,
    this.napModeEnabled = false,
    this.customAlarmSoundPath,
  });

  AppSettings copyWith({
    double? defaultAlertRadius,
    AlarmType? alarmType,
    CommuteMode? commuteMode,
    bool? repeatedAlarm,
    bool? napModeEnabled,
    String? customAlarmSoundPath,
  }) {
    return AppSettings(
      defaultAlertRadius: defaultAlertRadius ?? this.defaultAlertRadius,
      alarmType: alarmType ?? this.alarmType,
      commuteMode: commuteMode ?? this.commuteMode,
      repeatedAlarm: repeatedAlarm ?? this.repeatedAlarm,
      napModeEnabled: napModeEnabled ?? this.napModeEnabled,
      customAlarmSoundPath:
          customAlarmSoundPath ?? this.customAlarmSoundPath,
    );
  }

  double get simulationSpeedMps => commuteMode.simulationSpeedMps;
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final db = ref.read(localDatabaseProvider);
  return SettingsNotifier(db);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final LocalDatabase _db;

  SettingsNotifier(this._db) : super(const AppSettings()) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final saved = await _db.getAppSettings();
    if (saved != null) {
      state = saved;
    }
  }

  void setDefaultAlertRadius(double radius) {
    state = state.copyWith(defaultAlertRadius: radius);
    _db.saveAppSettings(state);
  }

  void setAlarmType(AlarmType type) {
    state = state.copyWith(alarmType: type);
    _db.saveAppSettings(state);
  }

  void setCommuteMode(CommuteMode mode) {
    state = state.copyWith(commuteMode: mode);
    _db.saveAppSettings(state);
  }

  void toggleRepeatedAlarm() {
    state = state.copyWith(repeatedAlarm: !state.repeatedAlarm);
    _db.saveAppSettings(state);
  }

  void toggleNapMode() {
    state = state.copyWith(napModeEnabled: !state.napModeEnabled);
    _db.saveAppSettings(state);
  }

  void setCustomAlarmSound(String path) {
    state = state.copyWith(customAlarmSoundPath: path);
    _db.saveAppSettings(state);
  }

  void clearCustomAlarmSound() {
    state = state.copyWith(customAlarmSoundPath: null);
    _db.saveAppSettings(state);
  }

  void reset() {
    state = const AppSettings();
    _db.saveAppSettings(state);
  }
}
