import 'package:flutter_test/flutter_test.dart';
import 'package:stop_co/features/trip/data/waypoint.dart';
import 'package:stop_co/features/destination/data/destination_model.dart';

void main() {
  group('Waypoint', () {
    final now = DateTime(2026, 7, 22);

    final dest = Destination(
      id: 'dest-1',
      name: 'Home',
      latitude: 40.7128,
      longitude: -74.0060,
      alertRadius: 300,
      createdAt: now,
    );

    test('fromDestination creates Waypoint with correct fields', () {
      final wp = Waypoint.fromDestination(dest, 0);

      expect(wp.id, 'dest-1');
      expect(wp.name, 'Home');
      expect(wp.latitude, 40.7128);
      expect(wp.longitude, -74.0060);
      expect(wp.alertRadius, 300);
      expect(wp.orderIndex, 0);
    });

    test('fromDestination copies alertRadius', () {
      final custom = dest.copyWith(alertRadius: 500);
      final wp = Waypoint.fromDestination(custom, 0);
      expect(wp.alertRadius, 500);
    });

    test('copyWith preserves unchanged fields', () {
      final wp = Waypoint.fromDestination(dest, 0);
      final modified = wp.copyWith(name: 'Work');
      expect(modified.name, 'Work');
      expect(modified.id, 'dest-1');
      expect(modified.latitude, 40.7128);
    });

    test('copyWith replaces all fields', () {
      final wp = Waypoint.fromDestination(dest, 0);
      final modified = wp.copyWith(
        id: 'new-id',
        name: 'New',
        latitude: 10.0,
        longitude: 20.0,
        alertRadius: 100,
        orderIndex: 5,
      );
      expect(modified.id, 'new-id');
      expect(modified.name, 'New');
      expect(modified.latitude, 10.0);
      expect(modified.longitude, 20.0);
      expect(modified.alertRadius, 100);
      expect(modified.orderIndex, 5);
    });

    test('toJson produces correct map', () {
      final wp = Waypoint.fromDestination(dest, 1);
      final json = wp.toJson();

      expect(json['id'], 'dest-1');
      expect(json['name'], 'Home');
      expect(json['latitude'], 40.7128);
      expect(json['longitude'], -74.0060);
      expect(json['alertRadius'], 300);
      expect(json['orderIndex'], 1);
    });

    test('fromJson reconstructs Waypoint', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Point',
        'latitude': 51.5074,
        'longitude': -0.1278,
        'alertRadius': 500.0,
        'orderIndex': 2,
      };
      final wp = Waypoint.fromJson(json);

      expect(wp.id, 'test-id');
      expect(wp.name, 'Test Point');
      expect(wp.latitude, 51.5074);
      expect(wp.longitude, -0.1278);
      expect(wp.alertRadius, 500);
      expect(wp.orderIndex, 2);
    });

    test('JSON roundtrip preserves all fields', () {
      final original = Waypoint.fromDestination(dest, 3);
      final json = original.toJson();
      final restored = Waypoint.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.alertRadius, original.alertRadius);
      expect(restored.orderIndex, original.orderIndex);
    });

    test('fromJson handles integer values in numeric fields', () {
      final json = {
        'id': 'int-test',
        'name': 'Int Coords',
        'latitude': 40,
        'longitude': -74,
        'alertRadius': 300,
        'orderIndex': 0,
      };
      final wp = Waypoint.fromJson(json);
      expect(wp.latitude, 40.0);
      expect(wp.longitude, -74.0);
      expect(wp.alertRadius, 300.0);
    });

    test('serializeList returns null for null input', () {
      expect(Waypoint.serializeList(null), isNull);
    });

    test('serializeList returns null for empty list', () {
      expect(Waypoint.serializeList([]), isNull);
    });

    test('deserializeList returns empty list for null', () {
      expect(Waypoint.deserializeList(null), isEmpty);
    });

    test('deserializeList returns empty list for empty string', () {
      expect(Waypoint.deserializeList(''), isEmpty);
    });

    test('serializeList / deserializeList roundtrip', () {
      final wps = [
        Waypoint.fromDestination(dest, 0),
        Waypoint(
          id: 'wp-2',
          name: 'Work',
          latitude: 40.7580,
          longitude: -73.9855,
          alertRadius: 200,
          orderIndex: 1,
        ),
      ];

      final json = Waypoint.serializeList(wps);
      expect(json, isNotNull);

      final restored = Waypoint.deserializeList(json);
      expect(restored.length, 2);
      expect(restored[0].name, 'Home');
      expect(restored[1].name, 'Work');
      expect(restored[1].latitude, 40.7580);
    });
  });
}
