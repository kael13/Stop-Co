import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../platform/settings_channel.dart';

class PermissionHelper {
  static Future<bool> requestLocationWithRationale(BuildContext context) async {
    final perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      return true;
    }

    if (perm == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      await _showDeniedForeverDialog(context, 'location');
      return false;
    }

    // Permission.denied — first time asking
    final result = await Geolocator.requestPermission();

    if (result == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      await _showDeniedForeverDialog(context, 'location');
      return false;
    }

    return result == LocationPermission.always ||
        result == LocationPermission.whileInUse;
  }

  static Future<bool> requestBackgroundLocation(BuildContext context) async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.always) return true;
    if (perm != LocationPermission.whileInUse) return false;

    // User has foreground but not background — request again
    // On Android 10+, this triggers a separate background permission dialog
    final result = await Geolocator.requestPermission();

    if (result == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      await _showDeniedForeverDialog(context, 'background location');
      return false;
    }

    return result == LocationPermission.always;
  }

  static Future<bool> requestNotificationPermission() async {
    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return true; // non-Android, skip

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  static Future<void> _showDeniedForeverDialog(
      BuildContext context, String permissionName) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName Permission'),
        content: Text(
          'Stop-Co needs $permissionName access to function properly. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SettingsChannel.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
