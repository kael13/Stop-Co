import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stop_co/features/scheduled_trip/data/scheduled_trip.dart';
import 'package:stop_co/features/scheduled_trip/data/scheduled_trip_notification_service.dart';
import 'package:stop_co/features/scheduled_trip/data/scheduled_trip_repository.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class _MockRepo extends Mock implements ScheduledTripRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannel monitorChannel;
  late List<MethodCall> monitorCalls;
  late ScheduledTripNotificationService service;
  late _MockRepo repo;

  final sampleTrip = ScheduledTrip(
    id: 'trip-1',
    name: 'Work',
    waypointsJson:
        '[{"id":"wp-1","name":"Office","latitude":40.0,"longitude":-74.0,"alertRadius":300,"orderIndex":0}]',
    scheduledStartTime: DateTime(2027, 1, 15, 14, 30),
    createdAt: DateTime(2027, 1, 8),
  );

  final multiStopTrip = sampleTrip.copyWith(
    id: 'trip-2',
    name: 'Gym',
    waypointsJson:
        '[{"id":"wp-1","name":"A","latitude":40.0,"longitude":-74.0,"alertRadius":300,"orderIndex":0},{"id":"wp-2","name":"B","latitude":41.0,"longitude":-75.0,"alertRadius":500,"orderIndex":1}]',
  );

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  setUp(() {
    monitorChannel = const MethodChannel('com.stopco.app/reminder_monitor');
    monitorCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(monitorChannel, (call) async {
      monitorCalls.add(call);
      return null;
    });
    repo = _MockRepo();
    service = ScheduledTripNotificationService(
      FlutterLocalNotificationsPlugin(),
      repo,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(monitorChannel, null);
  });

  List<Map<String, dynamic>> startedReminders() {
    final startCall = monitorCalls.where((c) => c.method == 'start').first;
    final args = startCall.arguments as Map<Object?, Object?>;
    final raw = args['reminders'] as String;
    return (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  int expectedHourBeforeMs(ScheduledTrip trip) {
    final startLocal = tz.TZDateTime.from(trip.scheduledStartTime, tz.local);
    return startLocal.subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
  }

  group('syncReminders', () {
    test('registers a single hour-before entry for one pending trip', () async {
      when(() => repo.getAll()).thenAnswer((_) async => [sampleTrip]);

      await service.syncReminders();

      expect(monitorCalls.map((c) => c.method), contains('start'));
      final reminders = startedReminders();
      expect(reminders.length, 1);

      final hourBefore = reminders[0];
      expect(hourBefore['tripId'], 'trip-1');
      expect(hourBefore['title'], 'Upcoming Trip: Work');
      expect(hourBefore['body'], 'Departure at 2:30 PM — 1 stop');
      expect(hourBefore['triggerTimeMs'], expectedHourBeforeMs(sampleTrip));
    });

    test('registers all pending trips in one start call', () async {
      when(() => repo.getAll())
          .thenAnswer((_) async => [sampleTrip, multiStopTrip]);

      await service.syncReminders();

      final reminders = startedReminders();
      expect(reminders.length, 2);
      expect(reminders.map((r) => r['tripId']), containsAll(['trip-1', 'trip-2']));
    });

    test('shows plural stops text for multi-stop trip', () async {
      when(() => repo.getAll()).thenAnswer((_) async => [multiStopTrip]);

      await service.syncReminders();

      final reminders = startedReminders();
      expect(reminders.length, 1);
      expect(reminders[0]['body'], 'Departure at 2:30 PM — 2 stops');
    });

    test('filters out completed trips', () async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [
          sampleTrip,
          multiStopTrip.copyWith(status: ScheduledTripStatus.completed),
        ],
      );

      await service.syncReminders();

      final reminders = startedReminders();
      expect(reminders.map((r) => r['tripId']), ['trip-1']);
    });

    test('filters out cancelled trips', () async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [
          sampleTrip,
          multiStopTrip.copyWith(status: ScheduledTripStatus.cancelled),
        ],
      );

      await service.syncReminders();

      final reminders = startedReminders();
      expect(reminders.map((r) => r['tripId']), ['trip-1']);
    });

    test('filters out alarm-triggered trips', () async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [
          sampleTrip,
          multiStopTrip.copyWith(alarmTriggeredAtEpochMs: 1234567890),
        ],
      );

      await service.syncReminders();

      final reminders = startedReminders();
      expect(reminders.map((r) => r['tripId']), ['trip-1']);
    });

    test('honors excludeId', () async {
      when(() => repo.getAll())
          .thenAnswer((_) async => [sampleTrip, multiStopTrip]);

      await service.syncReminders(excludeId: 'trip-1');

      final reminders = startedReminders();
      expect(reminders.map((r) => r['tripId']), ['trip-2']);
    });

    test('stops the monitor when no pending trips remain', () async {
      when(() => repo.getAll()).thenAnswer((_) async => [
            sampleTrip.copyWith(status: ScheduledTripStatus.completed),
          ]);

      await service.syncReminders();

      expect(monitorCalls.map((c) => c.method), contains('stop'));
      expect(monitorCalls.where((c) => c.method == 'start'), isEmpty);
    });
  });

  group('cancelReminder', () {
    test('rebuilds the set minus the cancelled trip instead of stopping all',
        () async {
      when(() => repo.getAll())
          .thenAnswer((_) async => [sampleTrip, multiStopTrip]);

      await service.cancelReminder('trip-1');

      expect(monitorCalls.map((c) => c.method), contains('start'));
      expect(monitorCalls.map((c) => c.method), isNot(contains('stop')));
      final reminders = startedReminders();
      expect(reminders.map((r) => r['tripId']), ['trip-2']);
    });
  });
}
