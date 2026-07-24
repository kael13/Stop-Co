import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/constants/app_constants.dart';
import 'scheduled_trip.dart';

class ScheduledTripNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  ScheduledTripNotificationService(this._plugin);

  Future<void> scheduleDayBeforeReminder(ScheduledTrip trip) async {
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

    final androidDetails = AndroidNotificationDetails(
      AppConstants.tripReminderChannelId,
      AppConstants.tripReminderChannelName,
      channelDescription: AppConstants.tripReminderChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final timeFormatted = DateFormat('h:mm a').format(trip.scheduledStartTime);

    await _plugin.zonedSchedule(
      _notificationId(trip.id),
      'Trip Tomorrow: ${trip.name}',
      'Departure at $timeFormatted — ${trip.waypoints.length} stop${trip.waypoints.length == 1 ? '' : 's'}',
      actualFireTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: 'scheduled_trip:${trip.id}',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String tripId) async {
    await _plugin.cancel(_notificationId(tripId));
  }

  int _notificationId(String tripId) => 2000 + tripId.hashCode;
}
