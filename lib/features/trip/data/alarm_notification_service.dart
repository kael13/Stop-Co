import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart' show notificationsPlugin;
import '../../settings/data/settings_providers.dart';

// ---------------------------------------------------------------------------
// Injectable abstraction — allows mocking in tests
// ---------------------------------------------------------------------------

abstract class AlarmNotifier {
  Future<void> showAlarmNotification({
    required String destinationName,
    required double distance,
    required AlarmType alarmType,
    bool fullScreenIntent = true,
  });

  Future<void> dismissAlarm();
}

final alarmNotifierProvider = Provider<AlarmNotifier>((ref) {
  return _AlarmNotifierImpl();
});

class _AlarmNotifierImpl implements AlarmNotifier {
  @override
  Future<void> showAlarmNotification({
    required String destinationName,
    required double distance,
    required AlarmType alarmType,
    bool fullScreenIntent = true,
  }) {
    return AlarmNotificationService.showAlarmNotification(
      destinationName: destinationName,
      distance: distance,
      alarmType: alarmType,
      fullScreenIntent: fullScreenIntent,
    );
  }

  @override
  Future<void> dismissAlarm() {
    return AlarmNotificationService.dismissAlarm();
  }
}

// ---------------------------------------------------------------------------
// Real implementation (also usable as static helpers)
// ---------------------------------------------------------------------------

class AlarmNotificationService {
  static Future<void> showAlarmNotification({
    required String destinationName,
    required double distance,
    AlarmType alarmType = AlarmType.soundAndVibration,
    bool fullScreenIntent = true,
  }) async {
    final enableVibration = alarmType != AlarmType.soundOnly;

    final androidDetails = AndroidNotificationDetails(
      AppConstants.alarmChannelId,
      AppConstants.alarmChannelName,
      channelDescription: AppConstants.alarmChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: enableVibration,
      fullScreenIntent: fullScreenIntent,
      visibility: NotificationVisibility.public,
      usesChronometer: true,
      ongoing: false,
      autoCancel: false,
      showWhen: true,
      colorized: true,
      ticker: '${AppConstants.appName} Alarm',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notificationsPlugin.show(
      0,
      'ALARM: Approaching $destinationName',
      '${distance.round()}m away. Get ready to get off!',
      details,
      payload: 'alarm',
    );
  }

  static Future<void> dismissAlarm() async {
    await notificationsPlugin.cancel(0);
  }
}
