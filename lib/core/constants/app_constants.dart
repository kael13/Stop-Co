import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static String get appName => dotenv.env['APP_NAME'] ?? 'Stop-Co';

  static const double defaultAlertRadius = 300;
  static const List<double> alertRadiusOptions = [100, 300, 500, 1000];

  static const double maxAccuracyThreshold = 50;
  static const double maxSpeedMps = 100;
  static const int routeReFetchIntervalSec = 60;
  static const double routeReFetchMinDistance = 50;
  static const int locationPollIntervalMs = 10000;
  static const int geofenceCheckIntervalMs = 15000;

  static const String destinationCollection = 'destinations';

  static String get foregroundChannel =>
      dotenv.env['FOREGROUND_CHANNEL'] ?? 'com.stopco.app/foreground_service';

  static String get alarmChannel =>
      dotenv.env['ALARM_CHANNEL'] ?? 'com.stopco.app/alarm';

  static String get nominatimBaseUrl =>
      dotenv.env['NOMINATIM_BASE_URL'] ?? 'https://nominatim.openstreetmap.org';

  static String get osrmBaseUrl =>
      dotenv.env['OSRM_BASE_URL'] ?? 'https://router.project-osrm.org';

  static String get tileUrlTemplate =>
      dotenv.env['TILE_URL_TEMPLATE'] ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static String get userAgent => dotenv.env['USER_AGENT'] ?? 'StopCo/1.0';

  static String get alarmChannelId =>
      dotenv.env['ALARM_CHANNEL_ID'] ?? 'stop_co_alarm';

  static String get alarmChannelName =>
      dotenv.env['ALARM_CHANNEL_NAME'] ?? 'Destination Alarm';

  static String get alarmChannelDesc =>
      dotenv.env['ALARM_CHANNEL_DESC'] ?? 'Alerts when approaching your destination';
}
