import 'package:flutter/services.dart';

class SettingsChannel {
  static const _channel = MethodChannel('com.stopco.app/settings');

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on MissingPluginException {
      // no-op on unsupported platforms
    }
  }
}
