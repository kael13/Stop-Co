import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart' show notificationsPlugin;
import '../../settings/data/settings_providers.dart';

class AlarmNotificationService {
  static Future<void> showAlarmNotification({
    required String destinationName,
    required double distance,
    AlarmType alarmType = AlarmType.soundAndVibration,
  }) async {
    final playSound = alarmType != AlarmType.vibrationOnly;
    final enableVibration = alarmType != AlarmType.soundOnly;

    final androidDetails = AndroidNotificationDetails(
      AppConstants.alarmChannelId,
      AppConstants.alarmChannelName,
      channelDescription: AppConstants.alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: playSound,
      enableVibration: enableVibration,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
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
