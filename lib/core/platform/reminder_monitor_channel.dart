import 'dart:convert';
import 'package:flutter/services.dart';

class ReminderMonitorChannel {
  static const _channel = MethodChannel('com.stopco.app/reminder_monitor');

  static Future<bool> start(List<Map<String, dynamic>> reminders) async {
    try {
      await _channel.invokeMethod('start', {
        'reminders': jsonEncode(reminders),
      });
      return true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      await _channel.invokeMethod('stop');
      return true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return false;
    }
  }
}
