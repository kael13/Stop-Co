import 'dart:math';
import '../constants/app_constants.dart';

class GpsUtils {
  GpsUtils._();

  static bool isAccuracyAcceptable(double accuracy) {
    return accuracy <= AppConstants.maxAccuracyThreshold;
  }

  static bool isSpeedPlausible(double speedMps) {
    return speedMps <= AppConstants.maxSpeedMps;
  }

  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371000;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static bool isMovementSpike(
    double lat1, double lon1,
    double lat2, double lon2,
    double timeDeltaSeconds,
  ) {
    final distance = calculateDistance(lat1, lon1, lat2, lon2);
    if (timeDeltaSeconds <= 0) return false;
    final speed = distance / timeDeltaSeconds;
    return speed > AppConstants.maxSpeedMps;
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  static double toRadians(double degrees) {
    return degrees * pi / 180;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
