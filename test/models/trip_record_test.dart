import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:stop_co/features/trip/data/trip_record.dart';
import 'package:stop_co/features/trip/data/trip_model.dart';

void main() {
  group('TripRecord', () {
    final base = TripRecord(
      id: 'trip-1',
      destinationId: 'dest-1',
      destinationName: 'Home',
      status: TripStatus.completed,
      startedAt: DateTime(2026, 7, 22, 10, 0),
      endedAt: DateTime(2026, 7, 22, 10, 30),
      totalDistance: 5000,
      createdAt: DateTime(2026, 7, 22, 10, 30),
    );

    group('serializeCoordinates', () {
      test('returns null for null input', () {
        expect(TripRecord.serializeCoordinates(null), isNull);
      });

      test('returns null for empty list', () {
        expect(TripRecord.serializeCoordinates([]), isNull);
      });

      test('serializes single coordinate', () {
        final result = TripRecord.serializeCoordinates([
          LatLng(40.7128, -74.0060),
        ]);
        expect(result, '[[40.7128,-74.006]]');
      });

      test('serializes multiple coordinates', () {
        final result = TripRecord.serializeCoordinates([
          LatLng(40.7128, -74.0060),
          LatLng(40.7580, -73.9855),
        ]);
        expect(result, '[[40.7128,-74.006],[40.758,-73.9855]]');
      });
    });

    group('routeCoordinates getter', () {
      test('returns empty list when null', () {
        expect(base.routeCoordinates, isEmpty);
      });

      test('returns empty list when empty string', () {
        final record = base.copyWith(
          routeCoordinatesJson: '',
        );
        expect(record.routeCoordinates, isEmpty);
      });

      test('deserializes coordinates', () {
        final record = base.copyWith(
          routeCoordinatesJson: '[[40.7128,-74.006],[40.758,-73.9855]]',
        );
        final coords = record.routeCoordinates;
        expect(coords.length, 2);
        expect(coords[0].latitude, 40.7128);
        expect(coords[0].longitude, -74.006);
        expect(coords[1].latitude, 40.758);
        expect(coords[1].longitude, -73.9855);
      });
    });

    group('gpsBreadcrumbs getter', () {
      test('returns empty list when null', () {
        expect(base.gpsBreadcrumbs, isEmpty);
      });

      test('deserializes breadcrumbs', () {
        final record = base.copyWith(
          gpsBreadcrumbsJson: '[[51.5074,-0.1278],[48.8566,2.3522]]',
        );
        final crumbs = record.gpsBreadcrumbs;
        expect(crumbs.length, 2);
        expect(crumbs[0].latitude, 51.5074);
        expect(crumbs[0].longitude, -0.1278);
      });
    });

    group('waypoints getter', () {
      test('returns empty list when null', () {
        expect(base.waypoints, isEmpty);
      });

      test('deserializes waypoints from JSON', () {
        final record = base.copyWith(
          waypointsJson:
              '[{"id":"wp-1","name":"A","latitude":40.0,"longitude":-74.0,"alertRadius":300,"orderIndex":0}]',
        );
        expect(record.waypoints.length, 1);
        expect(record.waypoints[0].name, 'A');
        expect(record.waypoints[0].latitude, 40.0);
      });
    });

    group('duration', () {
      test('calculates positive duration', () {
        expect(base.duration.inMinutes, 30);
      });

      test('calculates zero duration', () {
        final now = DateTime.now();
        final record = base.copyWith(
          startedAt: now,
          endedAt: now,
        );
        expect(record.duration.inSeconds, 0);
      });
    });
  });
}

extension TripRecordCopyWith on TripRecord {
  TripRecord copyWith({
    String? id,
    String? destinationId,
    String? destinationName,
    TripStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    double? totalDistance,
    double? plannedRouteDistance,
    double? plannedRouteDuration,
    String? routeCoordinatesJson,
    String? gpsBreadcrumbsJson,
    String? waypointsJson,
    DateTime? createdAt,
  }) {
    return TripRecord(
      id: id ?? this.id,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      totalDistance: totalDistance ?? this.totalDistance,
      plannedRouteDistance: plannedRouteDistance ?? this.plannedRouteDistance,
      plannedRouteDuration: plannedRouteDuration ?? this.plannedRouteDuration,
      routeCoordinatesJson: routeCoordinatesJson ?? this.routeCoordinatesJson,
      gpsBreadcrumbsJson: gpsBreadcrumbsJson ?? this.gpsBreadcrumbsJson,
      waypointsJson: waypointsJson ?? this.waypointsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
