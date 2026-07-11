import 'package:flutter/services.dart';

class BatteryOptChannel {
  static const _channel = MethodChannel('com.stopco.app/battery');

  static Future<void> requestExemption() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimizationExemption');
    } on MissingPluginException {
      // no-op on unsupported platforms
    }
  }

  static Future<bool> isIgnoring() async {
    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? true;
    } on MissingPluginException {
      return true;
    }
  }
}
