import 'package:flutter_test/flutter_test.dart';
import 'package:stop_co/core/utils/gps_utils.dart';

void main() {
  group('GpsUtils', () {
    group('formatDistance', () {
      test('shows meters below 1000', () {
        expect(GpsUtils.formatDistance(0), '0 m');
        expect(GpsUtils.formatDistance(1), '1 m');
        expect(GpsUtils.formatDistance(500), '500 m');
        expect(GpsUtils.formatDistance(999), '999 m');
      });

      test('shows km at 1000 and above', () {
        expect(GpsUtils.formatDistance(1000), '1.0 km');
        expect(GpsUtils.formatDistance(1500), '1.5 km');
        expect(GpsUtils.formatDistance(10000), '10.0 km');
        expect(GpsUtils.formatDistance(12345), '12.3 km');
      });

      test('rounds meters correctly', () {
        expect(GpsUtils.formatDistance(0.4), '0 m');
        expect(GpsUtils.formatDistance(0.5), '1 m');
        expect(GpsUtils.formatDistance(99.9), '100 m');
      });
    });

    group('calculateDistance - haversine', () {
      test('zero distance for same point', () {
        final d = GpsUtils.calculateDistance(40.0, -74.0, 40.0, -74.0);
        expect(d, closeTo(0, 0.001));
      });

      test('NY to LA ~3944 km', () {
        final d = GpsUtils.calculateDistance(
          40.7128, -74.0060, 34.0522, -118.2437,
        );
        expect(d, closeTo(3_944_000, 50_000));
      });

      test('London to Paris ~344 km', () {
        final d = GpsUtils.calculateDistance(
          51.5074, -0.1278, 48.8566, 2.3522,
        );
        expect(d, closeTo(344_000, 10_000));
      });

      test('short distance ~100m', () {
        final d = GpsUtils.calculateDistance(
          40.0, -74.0, 40.001, -74.0,
        );
        expect(d, closeTo(111, 20));
      });

      test('is commutative', () {
        final d1 = GpsUtils.calculateDistance(40.0, -74.0, 41.0, -73.0);
        final d2 = GpsUtils.calculateDistance(41.0, -73.0, 40.0, -74.0);
        expect(d1, closeTo(d2, 1));
      });
    });

    group('isAccuracyAcceptable', () {
      test('true for values within threshold', () {
        expect(GpsUtils.isAccuracyAcceptable(50), isTrue);
        expect(GpsUtils.isAccuracyAcceptable(0), isTrue);
        expect(GpsUtils.isAccuracyAcceptable(25), isTrue);
      });

      test('false for values above threshold', () {
        expect(GpsUtils.isAccuracyAcceptable(51), isFalse);
        expect(GpsUtils.isAccuracyAcceptable(100), isFalse);
      });
    });

    group('isSpeedPlausible', () {
      test('true for speeds within limit', () {
        expect(GpsUtils.isSpeedPlausible(100), isTrue);
        expect(GpsUtils.isSpeedPlausible(0), isTrue);
        expect(GpsUtils.isSpeedPlausible(50), isTrue);
      });

      test('false for speeds above limit', () {
        expect(GpsUtils.isSpeedPlausible(101), isFalse);
        expect(GpsUtils.isSpeedPlausible(200), isFalse);
      });
    });

    group('isMovementSpike', () {
      test('false for zero time delta', () {
        expect(GpsUtils.isMovementSpike(40.0, -74.0, 41.0, -73.0, 0), isFalse);
      });

      test('false for normal speed', () {
        final d = GpsUtils.isMovementSpike(
          40.0, -74.0, 40.001, -74.0, 10,
        );
        expect(d, isFalse);
      });

      test('true for impossible speed (1000 km in 1 second)', () {
        final d = GpsUtils.isMovementSpike(
          40.0, -74.0, 50.0, -74.0, 1,
        );
        expect(d, isTrue);
      });
    });

    test('toRadians converts degrees', () {
      expect(GpsUtils.toRadians(180), closeTo(3.14159, 0.0001));
      expect(GpsUtils.toRadians(90), closeTo(1.5708, 0.0001));
      expect(GpsUtils.toRadians(0), closeTo(0, 0.0001));
    });
  });
}
