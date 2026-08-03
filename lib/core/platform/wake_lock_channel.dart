import 'package:flutter/services.dart';

class WakeLockChannel {
  static const _channel = MethodChannel('com.stopco.app/wake_lock');

  static Future<void> acquire() async {
    try {
      await _channel.invokeMethod('startTestReminder');
    } on MissingPluginException {
      // no-op on unsupported platforms
    }
  }

  static Future<void> release() async {
    try {
      await _channel.invokeMethod('stopTestReminder');
    } on MissingPluginException {
      // no-op on unsupported platforms
    }
  }
}
