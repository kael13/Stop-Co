import 'package:flutter/services.dart';

class AlarmChannel {
  static const _channel = MethodChannel('com.stopco.app/alarm');

  static Future<String> getDefaultAlarmPath() async {
    return await _channel.invokeMethod('getDefaultAlarmPath');
  }
}
