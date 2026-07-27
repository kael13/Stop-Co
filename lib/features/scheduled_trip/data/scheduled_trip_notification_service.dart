import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/constants/app_constants.dart';
import 'scheduled_trip.dart';

class ScheduledTripNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  ScheduledTripNotificationService(this._plugin);

  Future<void> _schedule(
    int id,
    String tripId,
    String title,
    String body,
    tz.TZDateTime fireTime,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.tripReminderChannelId,
      AppConstants.tripReminderChannelName,
      channelDescription: AppConstants.tripReminderChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      fireTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: 'scheduled_trip:$tripId',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleReminder(ScheduledTrip trip) async {
    switch (trip.remindBefore) {
      case RemindBefore.dayBefore:
        await _scheduleDayBefore(trip);
      case RemindBefore.hourBefore:
        await _scheduleHourBefore(trip);
    }
  }

  Future<void> _scheduleDayBefore(ScheduledTrip trip) async {
    final fireLocal = tz.local;

    final fireTime = tz.TZDateTime(
      fireLocal,
      trip.scheduledStartTime.year,
      trip.scheduledStartTime.month,
      trip.scheduledStartTime.day - 1,
      20, 0, 0, 0,
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

  Future<void> _scheduleHourBefore(ScheduledTrip trip) async {
    final fireLocal = tz.local;

    final fireTime = tz.TZDateTime(
      fireLocal,
      trip.scheduledStartTime.year,
      trip.scheduledStartTime.month,
      trip.scheduledStartTime.day,
      trip.scheduledStartTime.hour - 1,
      trip.scheduledStartTime.minute,
      trip.scheduledStartTime.second,
      trip.scheduledStartTime.millisecond,
    );

    final actualFireTime = fireTime.isBefore(tz.TZDateTime.now(fireLocal))
        ? tz.TZDateTime.now(fireLocal).add(const Duration(seconds: 5))
        : fireTime;

    final timeFormatted = DateFormat('h:mm a').format(trip.scheduledStartTime);
    final body =
        'Departure at $timeFormatted — ${trip.waypoints.length} stop${trip.waypoints.length == 1 ? '' : 's'}';

    await _schedule(
      _hourBeforeId(trip.id),
      trip.id,
      'Upcoming Trip: ${trip.name}',
      body,
      actualFireTime,
    );
  }

  Future<void> cancelReminder(String tripId) async {
    await _plugin.cancel(_dayBeforeId(tripId));
    await _plugin.cancel(_hourBeforeId(tripId));
  }

  Future<void> fireGenericTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.tripReminderChannelId,
      AppConstants.tripReminderChannelName,
      channelDescription: AppConstants.tripReminderChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
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
  int _hourBeforeId(String tripId) => 3000 + tripId.hashCode;
  int get _testId => 4000;
}
