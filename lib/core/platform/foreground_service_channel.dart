import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class ForegroundServiceChannel {
  static const _channel = MethodChannel(AppConstants.foregroundChannel);

  static Future<bool> startTracking({
    required double latitude,
    required double longitude,
    required double radius,
    required String destinationName,
    required String destinationId,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('startTracking', {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'destinationName': destinationName,
        'destinationId': destinationId,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> stopTracking() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopTracking');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> updateTrackingNotification({
    required String destinationName,
    required String remainingDistance,
  }) async {
    try {
      await _channel.invokeMethod('updateTrackingNotification', {
        'destinationName': destinationName,
        'remainingDistance': remainingDistance,
      });
    } on MissingPluginException {
      // no-op on unsupported platforms
    }
  }

  static Future<bool> isTracking() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTracking');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<double?> getCurrentLatitude() async {
    try {
      return await _channel.invokeMethod<double>('getCurrentLatitude');
    } on MissingPluginException {
      return null;
    }
  }

  static Future<double?> getCurrentLongitude() async {
    try {
      return await _channel.invokeMethod<double>('getCurrentLongitude');
    } on MissingPluginException {
      return null;
    }
  }

  static void setAlarmCallback(Function() callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAlarmTriggered') {
        callback();
      }
    });
  }
}
