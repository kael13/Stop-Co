import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/reminder_monitor_channel.dart';
import '../../../core/platform/wake_lock_channel.dart';
import 'scheduled_trip.dart';

class ScheduledTripNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  ScheduledTripNotificationService(this._plugin);

  static const _simTestId = 9000;

  Future<void> _schedule(
    int id,
    String tripId,
    String title,
    String body,
    tz.TZDateTime fireTime, {
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle,
  }) async {
    // flutter_local_notifications path (always try)
    final androidDetails = AndroidNotificationDetails(
      AppConstants.tripReminderChannelId,
      AppConstants.tripReminderChannelName,
      channelDescription: AppConstants.tripReminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        fireTime,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: null,
        payload: 'scheduled_trip:$tripId',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          fireTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: null,
          payload: 'scheduled_trip:$tripId',
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } on PlatformException {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          fireTime,
          details,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: null,
          payload: 'scheduled_trip:$tripId',
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> scheduleReminder(ScheduledTrip trip) async {
    if (trip.remindBefore == RemindBefore.dayBefore) {
      await _scheduleDayBefore(trip);
    }
    await _startMonitorForTrip(trip);
  }

  Future<void> _startMonitorForTrip(ScheduledTrip trip) async {
    final timeFormatted = DateFormat('h:mm a').format(trip.scheduledStartTime);
    final stops = trip.waypoints.length;
    final body =
        'Departure at $timeFormatted — $stops stop${stops == 1 ? '' : 's'}';

    await ReminderMonitorChannel.start([
      {
        'tripId': trip.id,
        'title': 'Upcoming Trip: ${trip.name}',
        'body': body,
        'triggerTimeMs': _hourBeforeFireTime(trip).millisecondsSinceEpoch,
      },
    ]);
  }

  tz.TZDateTime _hourBeforeFireTime(ScheduledTrip trip) {
    final fireLocal = tz.local;
    final startInLocal = tz.TZDateTime.from(trip.scheduledStartTime, fireLocal);
    final fireTime = startInLocal.subtract(const Duration(hours: 1));
    return fireTime.isBefore(tz.TZDateTime.now(fireLocal))
        ? tz.TZDateTime.now(fireLocal).add(const Duration(seconds: 5))
        : fireTime;
  }

  Future<void> scheduleTestReminder(Duration fromNow) async {
    try {
      await WakeLockChannel.acquire();
      await Future.delayed(fromNow);
      await fireGenericTestNotification();
    } finally {
      await WakeLockChannel.release();
    }
  }

  Future<void> cancelTestReminder() async {
    await _plugin.cancel(_simTestId);
  }

  Future<void> _scheduleDayBefore(ScheduledTrip trip) async {
    final fireLocal = tz.local;
    final startInLocal = tz.TZDateTime.from(trip.scheduledStartTime, fireLocal);

    final fireTime = tz.TZDateTime(
      fireLocal,
      startInLocal.year,
      startInLocal.month,
      startInLocal.day - 1,
      20, 0,
    );

    final actualFireTime = fireTime.isBefore(tz.TZDateTime.now(fireLocal))
        ? tz.TZDateTime.now(fireLocal).add(const Duration(seconds: 5))
        : fireTime;

    final timeFormatted = DateFormat('h:mm a').format(trip.scheduledStartTime);
    final body =
        'Departure at $timeFormatted — ${trip.waypoints.length} stop${trip.waypoints.length == 1 ? '' : 's'}';

    await _schedule(
      _dayBeforeId(trip.id),
      trip.id,
      'Trip Tomorrow: ${trip.name}',
      body,
      actualFireTime,
    );
  }

  Future<void> cancelReminder(String tripId) async {
    await _plugin.cancel(_dayBeforeId(tripId));
    await ReminderMonitorChannel.stop();
  }

  Future<void> fireGenericTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.tripReminderChannelId,
      AppConstants.tripReminderChannelName,
      channelDescription: AppConstants.tripReminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      _testId,
      '[TEST] Reminder Notification',
      'This is a test notification — your reminder channel is working.',
      details,
      payload: 'scheduled_trip:test',
    );
  }

  int _dayBeforeId(String tripId) => 2000 + tripId.hashCode;
  int get _testId => 4000;
}
