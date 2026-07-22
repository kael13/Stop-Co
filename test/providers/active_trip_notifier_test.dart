import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:latlong2/latlong.dart';

import 'package:stop_co/features/trip/data/trip_providers.dart';
import 'package:stop_co/features/trip/data/trip_model.dart';
import 'package:stop_co/features/trip/data/trip_record.dart';
import 'package:stop_co/features/trip/data/trip_repository.dart';
import 'package:stop_co/features/trip/data/waypoint.dart';
import 'package:stop_co/features/trip/data/alarm_notification_service.dart';
import 'package:stop_co/features/trip/domain/route_result.dart';
import 'package:stop_co/features/destination/data/destination_model.dart';
import 'package:stop_co/features/settings/data/settings_providers.dart';

class MockTripRepository extends Mock implements TripRepository {}
class MockAlarmNotifier extends Mock implements AlarmNotifier {}

// A fake Ref that returns pre-configured values for specific providers.
// Avoids mocktail's generic matcher issues with ProviderListenable.
class FakeRef extends Fake implements Ref {
  final _stubs = <Object, dynamic>{};

  void when(Object provider, dynamic value) {
    _stubs[provider] = value;
  }

  @override
  T read<T>(covariant ProviderListenable<T> provider) {
    final value = _stubs[provider];
    if (value == null && provider == (settingsProvider as ProviderListenable<AppSettings>)) {
      return AppSettings() as T;
    }
    return value as T;
  }

  void addListener(
    covariant ProviderListenable<Object?> provider,
    void Function(Object?) listener, {
    bool fireImmediately = false,
  }) {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(AlarmType.soundAndVibration);
    registerFallbackValue(TripRecord(
      id: '', destinationId: '', destinationName: '',
      status: TripStatus.completed,
      startedAt: DateTime(2000), endedAt: DateTime(2000),
      totalDistance: 0, createdAt: DateTime(2000),
    ));
  });

  late FakeRef fakeRef;
  late MockTripRepository mockTripRepo;
  late MockAlarmNotifier mockAlarmNotifier;
  late ActiveTripNotifier notifier;

  final testDest = Destination(
    id: 'dest-1',
    name: 'Home',
    latitude: 40.7128,
    longitude: -74.0060,
    alertRadius: 300,
    createdAt: DateTime(2026, 7, 22),
  );

  final testWaypoints = [
    Waypoint(
      id: 'wp-1', name: 'Stop A', latitude: 40.0, longitude: -74.0,
      alertRadius: 300, orderIndex: 0,
    ),
    Waypoint(
      id: 'wp-2', name: 'Stop B', latitude: 40.1, longitude: -74.1,
      alertRadius: 500, orderIndex: 1,
    ),
  ];

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockAlarmNotifier = MockAlarmNotifier();
    fakeRef = FakeRef();

    fakeRef.when(tripRepositoryProvider, mockTripRepo);
    fakeRef.when(alarmNotifierProvider, mockAlarmNotifier);
    fakeRef.when(settingsProvider, const AppSettings());

    when(() => mockAlarmNotifier.showAlarmNotification(
      destinationName: any(named: 'destinationName'),
      distance: any(named: 'distance'),
      alarmType: any(named: 'alarmType'),
      fullScreenIntent: any(named: 'fullScreenIntent'),
    )).thenAnswer((_) async {});
    when(() => mockAlarmNotifier.dismissAlarm()).thenAnswer((_) async {});
    when(() => mockTripRepo.save(any())).thenAnswer((_) async {});

    notifier = ActiveTripNotifier(fakeRef);
  });

  group('initial state', () {
    test('starts with null state', () {
      expect(notifier.state, isNull);
    });
  });

  group('startTrip', () {
    test('creates single-waypoint active trip', () {
      notifier.startTrip(testDest);

      expect(notifier.state, isNotNull);
      expect(notifier.state!.waypoints.length, 1);
      expect(notifier.state!.currentWaypoint.name, 'Home');
      expect(notifier.state!.status, TripStatus.monitoring);
      expect(notifier.state!.hasAlerted, false);
      expect(notifier.state!.hasMultipleStops, false);
    });

    test('sets startedAt approximately now', () {
      final before = DateTime.now();
      notifier.startTrip(testDest);
      final after = DateTime.now();

      final started = notifier.state!.startedAt;
      expect(started.isAfter(before) || started == before, isTrue);
      expect(started.isBefore(after) || started == after, isTrue);
    });

    test('uses destination alertRadius', () {
      final custom = testDest.copyWith(alertRadius: 500);
      notifier.startTrip(custom);
      expect(notifier.state!.currentWaypoint.alertRadius, 500);
    });
  });

  group('startTripWithWaypoints', () {
    test('creates multi-waypoint active trip', () {
      notifier.startTripWithWaypoints(testWaypoints);

      expect(notifier.state, isNotNull);
      expect(notifier.state!.waypoints.length, 2);
      expect(notifier.state!.currentWaypoint.name, 'Stop A');
      expect(notifier.state!.hasMultipleStops, isTrue);
    });

    test('sets currentWaypointIndex to 0', () {
      notifier.startTripWithWaypoints(testWaypoints);
      expect(notifier.state!.currentWaypointIndex, 0);
    });
  });

  group('updateDistance', () {
    test('updates currentDistance', () {
      notifier.startTrip(testDest);
      notifier.updateDistance(150.0);
      expect(notifier.state!.currentDistance, 150.0);
    });

    test('does nothing when no active trip', () {
      notifier.updateDistance(150.0);
      expect(notifier.state, isNull);
    });

    test('replaces previous distance', () {
      notifier.startTrip(testDest);
      notifier.updateDistance(100.0);
      notifier.updateDistance(50.0);
      expect(notifier.state!.currentDistance, 50.0);
    });
  });

  group('setRouteResult', () {
    test('stores route result', () {
      notifier.startTrip(testDest);
      final route = RouteResult(
        distanceMeters: 5000,
        durationSeconds: 300,
        coordinates: [LatLng(40.0, -74.0)],
      );
      notifier.setRouteResult(route);

      expect(notifier.state!.routeResult?.distanceMeters, 5000);
      expect(notifier.state!.routeResult?.coordinates.length, 1);
    });

    test('does nothing when no active trip', () {
      final route = RouteResult(
        distanceMeters: 1000, durationSeconds: 100, coordinates: [],
      );
      notifier.setRouteResult(route);
      expect(notifier.state, isNull);
    });
  });

  group('addBreadcrumb', () {
    test('appends to gpsBreadcrumbs list', () {
      notifier.startTrip(testDest);
      notifier.addBreadcrumb(LatLng(40.0, -74.0));
      notifier.addBreadcrumb(LatLng(40.01, -74.01));

      expect(notifier.state!.gpsBreadcrumbs.length, 2);
    });

    test('does nothing when no active trip', () {
      notifier.addBreadcrumb(LatLng(40.0, -74.0));
      expect(notifier.state, isNull);
    });
  });

  group('triggerAlarm', () {
    test('sets hasAlerted and status alarmTriggered', () {
      notifier.startTrip(testDest);
      notifier.triggerAlarm();

      expect(notifier.state!.hasAlerted, isTrue);
      expect(notifier.state!.status, TripStatus.alarmTriggered);
    });

    test('calls alarm notification', () {
      notifier.startTrip(testDest);
      notifier.triggerAlarm();

      verify(() => mockAlarmNotifier.showAlarmNotification(
        destinationName: 'Home',
        distance: 0.0,
        alarmType: any(named: 'alarmType'),
      )).called(1);
    });

    test('is idempotent - only calls notification once', () {
      notifier.startTrip(testDest);
      notifier.triggerAlarm();
      notifier.triggerAlarm();

      verify(() => mockAlarmNotifier.showAlarmNotification(
        destinationName: any(named: 'destinationName'),
        distance: any(named: 'distance'),
        alarmType: any(named: 'alarmType'),
      )).called(1);
    });

    test('does nothing when no active trip', () {
      notifier.triggerAlarm();
      expect(notifier.state, isNull);
      verifyNever(() => mockAlarmNotifier.showAlarmNotification(
        destinationName: any(named: 'destinationName'),
        distance: any(named: 'distance'),
        alarmType: any(named: 'alarmType'),
      ));
    });

    test('includes current distance in notification', () {
      notifier.startTrip(testDest);
      notifier.updateDistance(200.0);
      notifier.triggerAlarm();

      verify(() => mockAlarmNotifier.showAlarmNotification(
        destinationName: 'Home',
        distance: 200.0,
        alarmType: any(named: 'alarmType'),
      )).called(1);
    });
  });

  group('advanceToNextWaypoint', () {
    test('advances index for multi-stop trip', () {
      notifier.startTripWithWaypoints(testWaypoints);
      notifier.advanceToNextWaypoint();

      expect(notifier.state!.currentWaypointIndex, 1);
      expect(notifier.state!.currentWaypoint.name, 'Stop B');
    });

    test('resets hasAlerted and status after advance', () {
      notifier.startTripWithWaypoints(testWaypoints);
      notifier.triggerAlarm();
      notifier.advanceToNextWaypoint();

      expect(notifier.state!.hasAlerted, isFalse);
      expect(notifier.state!.status, TripStatus.monitoring);
    });

    test('clears routeResult and distance on advance', () {
      notifier.startTripWithWaypoints(testWaypoints);
      notifier.setRouteResult(RouteResult(
        distanceMeters: 5000, durationSeconds: 300,
        coordinates: [LatLng(40.0, -74.0)],
      ));
      notifier.updateDistance(100.0);
      notifier.advanceToNextWaypoint();

      expect(notifier.state!.routeResult, isNull);
      expect(notifier.state!.currentDistance, isNull);
    });

    test('completes trip on last stop advance', () {
      notifier.startTripWithWaypoints([testWaypoints.first]);
      notifier.advanceToNextWaypoint();

      verify(() => mockTripRepo.save(any())).called(1);
      verify(() => mockAlarmNotifier.dismissAlarm()).called(1);
    });

    test('does nothing when no active trip', () {
      notifier.advanceToNextWaypoint();
      expect(notifier.state, isNull);
    });
  });

  group('cancelTrip', () {
    test('clears state', () {
      notifier.startTrip(testDest);
      notifier.cancelTrip();
      expect(notifier.state, isNull);
    });

    test('persists trip record', () {
      notifier.startTrip(testDest);
      notifier.cancelTrip();
      verify(() => mockTripRepo.save(any())).called(1);
    });

    test('dismisses alarm', () {
      notifier.startTrip(testDest);
      notifier.cancelTrip();
      verify(() => mockAlarmNotifier.dismissAlarm()).called(1);
    });

    test('persists with cancelled status', () {
      notifier.startTrip(testDest);
      notifier.cancelTrip();

      final captured = verify(() => mockTripRepo.save(captureAny()))
          .captured.first as TripRecord;
      expect(captured.status, TripStatus.cancelled);
    });
  });

  group('completeTrip', () {
    test('persists trip record', () {
      notifier.startTrip(testDest);
      notifier.completeTrip();
      verify(() => mockTripRepo.save(any())).called(1);
    });

    test('dismisses alarm', () {
      notifier.startTrip(testDest);
      notifier.completeTrip();
      verify(() => mockAlarmNotifier.dismissAlarm()).called(1);
    });

    test('persists with completed status', () {
      notifier.startTrip(testDest);
      notifier.completeTrip();

      final captured = verify(() => mockTripRepo.save(captureAny()))
          .captured.first as TripRecord;
      expect(captured.status, TripStatus.completed);
    });
  });

  group('clearTrip', () {
    test('clears state without persisting', () {
      notifier.startTrip(testDest);
      notifier.clearTrip();
      expect(notifier.state, isNull);
      verifyNever(() => mockTripRepo.save(any()));
    });

    test('does not dismiss alarm', () {
      notifier.startTrip(testDest);
      notifier.clearTrip();
      verifyNever(() => mockAlarmNotifier.dismissAlarm());
    });
  });

  group('_persistTrip', () {
    test('saves TripRecord with correct fields', () {
      notifier.startTripWithWaypoints(testWaypoints);
      notifier.updateDistance(200.0);
      notifier.setRouteResult(const RouteResult(
        distanceMeters: 5000,
        durationSeconds: 300,
        coordinates: [],
      ));
      notifier.cancelTrip();

      final captured = verify(() => mockTripRepo.save(captureAny()))
          .captured.first as TripRecord;

      expect(captured.destinationId, 'wp-1');
      expect(captured.destinationName, 'Stop A');
      expect(captured.totalDistance, 200.0);
      expect(captured.plannedRouteDistance, 5000);
      expect(captured.plannedRouteDuration, 300);
      expect(captured.waypointsJson, isNotNull);
    });

    test('saves waypointsJson as null for single stop', () {
      notifier.startTrip(testDest);
      notifier.cancelTrip();

      final captured = verify(() => mockTripRepo.save(captureAny()))
          .captured.first as TripRecord;
      expect(captured.waypointsJson, isNull);
    });

    test('serializes breadcrumbs', () {
      notifier.startTrip(testDest);
      notifier.addBreadcrumb(LatLng(40.0, -74.0));
      notifier.addBreadcrumb(LatLng(40.1, -74.1));
      notifier.cancelTrip();

      final captured = verify(() => mockTripRepo.save(captureAny()))
          .captured.first as TripRecord;
      expect(captured.gpsBreadcrumbs.length, 2);
    });

    test('does nothing when state is null', () {
      notifier.cancelTrip();
      verifyNever(() => mockTripRepo.save(any()));
    });
  });
}
