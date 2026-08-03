import 'package:flutter/services.dart';

class ReminderAlarmChannel {
  static const _channel = MethodChannel('com.stopco.app/reminder');

  static Future<bool> schedule({
    required String tripId,
    required int triggerTimeMs,
    String title = 'Trip Reminder',
    String body = '',
    int? notificationId,
  }) async {
    try {
      final args = <String, dynamic>{
        'tripId': tripId,
        'triggerTimeMs': triggerTimeMs,
        'title': title,
        'body': body,
      };
      if (notificationId != null) args['notificationId'] = notificationId;
      await _channel.invokeMethod('schedule', args);
      return true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> cancel(String tripId) async {
    try {
      await _channel.invokeMethod('cancel', {'tripId': tripId});
      return true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return false;
    }
  }
}
