import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:stop_co/features/trip/data/trip_model.dart';
import 'package:stop_co/features/trip/data/waypoint.dart';

void main() {
  final wp1 = Waypoint(
    id: 'wp-1', name: 'Stop A', latitude: 40.0, longitude: -74.0,
    alertRadius: 300, orderIndex: 0,
  );
  final wp2 = Waypoint(
    id: 'wp-2', name: 'Stop B', latitude: 40.1, longitude: -74.1,
    alertRadius: 500, orderIndex: 1,
  );
  final wp3 = Waypoint(
    id: 'wp-3', name: 'Stop C', latitude: 40.2, longitude: -74.2,
    alertRadius: 200, orderIndex: 2,
  );

  final now = DateTime(2026, 7, 22, 10, 0);

  group('ActiveTrip', () {
    test('currentWaypoint returns first waypoint at index 0', () {
      final trip = ActiveTrip(waypoints: [wp1, wp2], startedAt: now);
      expect(trip.currentWaypoint.name, 'Stop A');
      expect(trip.currentWaypoint.id, 'wp-1');
    });

    test('currentWaypoint respects currentWaypointIndex', () {
      final trip = ActiveTrip(
        waypoints: [wp1, wp2],
        currentWaypointIndex: 1,
        startedAt: now,
      );
      expect(trip.currentWaypoint.name, 'Stop B');
    });

    test('isActive is true by default', () {
      final trip = ActiveTrip(waypoints: [wp1], startedAt: now);
      expect(trip.isActive, isTrue);
    });

    test('isActive is false when alarmTriggered', () {
      final trip = ActiveTrip(
        waypoints: [wp1], startedAt: now,
        status: TripStatus.alarmTriggered,
      );
      expect(trip.isActive, isFalse);
    });

    test('isActive is false when cancelled', () {
      final trip = ActiveTrip(
        waypoints: [wp1], startedAt: now,
        status: TripStatus.cancelled,
      );
      expect(trip.isActive, isFalse);
    });

    test('isActive is false when completed', () {
      final trip = ActiveTrip(
        waypoints: [wp1], startedAt: now,
        status: TripStatus.completed,
      );
      expect(trip.isActive, isFalse);
    });

    test('isActive is false when hasAlerted is true', () {
      final trip = ActiveTrip(
        waypoints: [wp1], startedAt: now,
        hasAlerted: true,
      );
      expect(trip.isActive, isFalse);
    });

    test('hasMultipleStops is false for single waypoint', () {
      final trip = ActiveTrip(waypoints: [wp1], startedAt: now);
      expect(trip.hasMultipleStops, isFalse);
    });

    test('hasMultipleStops is true for multiple waypoints', () {
      final trip = ActiveTrip(waypoints: [wp1, wp2], startedAt: now);
      expect(trip.hasMultipleStops, isTrue);
    });

    test('totalStops returns waypoints length', () {
      final trip = ActiveTrip(waypoints: [wp1, wp2, wp3], startedAt: now);
      expect(trip.totalStops, 3);
    });

    test('copyWith preserves unchanged fields', () {
      final trip = ActiveTrip(waypoints: [wp1], startedAt: now);
      final copy = trip.copyWith(currentDistance: 150.0);

      expect(copy.currentDistance, 150.0);
      expect(copy.waypoints.length, 1);
      expect(copy.startedAt, now);
      expect(copy.status, TripStatus.monitoring);
    });

    test('copyWith replaces all fields', () {
      final trip = ActiveTrip(waypoints: [wp1], startedAt: now);
      final copy = trip.copyWith(
        waypoints: [wp1, wp2],
        currentWaypointIndex: 1,
        status: TripStatus.alarmTriggered,
        currentDistance: 50.0,
        hasAlerted: true,
        gpsBreadcrumbs: [LatLng(40.0, -74.0)],
      );

      expect(copy.waypoints.length, 2);
      expect(copy.currentWaypointIndex, 1);
      expect(copy.status, TripStatus.alarmTriggered);
      expect(copy.currentDistance, 50.0);
      expect(copy.hasAlerted, isTrue);
      expect(copy.gpsBreadcrumbs.length, 1);
    });

    test('default startedAt is required', () {
      final trip = ActiveTrip(waypoints: [wp1], startedAt: now);
      expect(trip.startedAt, now);
    });

    test('empty gpsBreadcrumbs by default', () {
      final trip = ActiveTrip(waypoints: [wp1], startedAt: now);
      expect(trip.gpsBreadcrumbs, isEmpty);
    });

    test('null routeResult by default', () {
      final trip = ActiveTrip(waypoints: [wp1], startedAt: now);
      expect(trip.routeResult, isNull);
    });

    test('null currentDistance by default', () {
      final trip = ActiveTrip(waypoints: [wp1], startedAt: now);
      expect(trip.currentDistance, isNull);
    });
  });
}
