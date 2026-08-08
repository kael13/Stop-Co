import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stop_co/features/scheduled_trip/data/scheduled_trip.dart';
import 'package:stop_co/features/scheduled_trip/data/scheduled_trip_notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannel monitorChannel;
  late List<MethodCall> monitorCalls;
  late ScheduledTripNotificationService service;

  final sampleTrip = ScheduledTrip(
    id: 'trip-1',
    name: 'Work',
    waypointsJson:
        '[{"id":"wp-1","name":"Office","latitude":40.0,"longitude":-74.0,"alertRadius":300,"orderIndex":0}]',
    scheduledStartTime: DateTime(2027, 1, 15, 14, 30),
    createdAt: DateTime(2027, 1, 8),
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
    service = ScheduledTripNotificationService(FlutterLocalNotificationsPlugin());
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

  group('scheduleReminder', () {
    int expectedHourBeforeMs() {
      final startLocal = tz.TZDateTime.from(sampleTrip.scheduledStartTime, tz.local);
      return startLocal.subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
    }

    test('registers the single hour-before entry', () async {
      await service.scheduleReminder(sampleTrip);

      expect(monitorCalls.map((c) => c.method), contains('start'));
      final reminders = startedReminders();
      expect(reminders.length, 1);

      final hourBefore = reminders[0];
      expect(hourBefore['tripId'], 'trip-1');
      expect(hourBefore['title'], 'Upcoming Trip: Work');
      expect(hourBefore['body'], 'Departure at 2:30 PM — 1 stop');
      expect(hourBefore['triggerTimeMs'], expectedHourBeforeMs());
    });

    test('shows plural stops text for multi-stop trip', () async {
      final multiStopTrip = sampleTrip.copyWith(
        waypointsJson:
            '[{"id":"wp-1","name":"A","latitude":40.0,"longitude":-74.0,"alertRadius":300,"orderIndex":0},{"id":"wp-2","name":"B","latitude":41.0,"longitude":-75.0,"alertRadius":500,"orderIndex":1}]',
      );

      await service.scheduleReminder(multiStopTrip);

      final reminders = startedReminders();
      expect(reminders.length, 1);
      expect(reminders[0]['body'], 'Departure at 2:30 PM — 2 stops');
    });
  });

  group('cancelReminder', () {
    test('stops the reminder monitor', () async {
      await service.cancelReminder('trip-1');

      expect(monitorCalls.map((c) => c.method), contains('stop'));
    });
  });
}
