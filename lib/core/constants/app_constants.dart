class AppConstants {
  AppConstants._();

  static const String appName = 'Stop-Co';

  static const double defaultAlertRadius = 300;
  static const List<double> alertRadiusOptions = [100, 300, 500, 1000];

  static const double maxAccuracyThreshold = 50;
  static const double maxSpeedMps = 100;
  static const int routeReFetchIntervalSec = 60;
  static const double routeReFetchMinDistance = 50; // meters
  static const int locationPollIntervalMs = 10000;
  static const int geofenceCheckIntervalMs = 15000;

  static const String destinationCollection = 'destinations';

  static const String foregroundChannel = 'com.stopco.app/foreground_service';
  static const String alarmChannel = 'com.stopco.app/alarm';

  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String osrmBaseUrl = 'https://router.project-osrm.org';
  static const String userAgent = 'StopCo/1.0';
}
