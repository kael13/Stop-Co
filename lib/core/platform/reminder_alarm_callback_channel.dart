import 'package:flutter/services.dart';

class ReminderAlarmCallbackChannel {
  static const _channel = MethodChannel('com.stopco.app/reminder_callback');

  static Future<Map<String, int>> drainPendingTriggers() async {
    try {
      final result = await _channel.invokeMethod('drainPendingTriggers');
      if (result == null) return {};
      return (result as Map<Object?, Object?>).map(
        (k, v) => MapEntry(k as String, (v as int)),
      );
    } on MissingPluginException {
      return {};
    } catch (e) {
      return {};
    }
  }
}
