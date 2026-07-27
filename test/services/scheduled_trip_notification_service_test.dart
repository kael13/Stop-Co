import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:stop_co/features/scheduled_trip/data/scheduled_trip.dart';
import 'package:stop_co/features/scheduled_trip/data/scheduled_trip_notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late ScheduledTripNotificationService service;

  final sampleTrip = ScheduledTrip(
    id: 'trip-1',
    name: 'Work',
    waypointsJson:
        '[{"id":"wp-1","name":"Office","latitude":40.0,"longitude":-74.0,"alertRadius":300,"orderIndex":0}]',
    scheduledStartTime: DateTime(2026, 7, 27, 14, 30),
    createdAt: DateTime(2026, 7, 20),
    remindBefore: RemindBefore.dayBefore,
  );

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(
      const AndroidNotificationDetails('', '', importance: Importance.defaultImportance),
    );
    registerFallbackValue(const DarwinNotificationDetails());
    registerFallbackValue(NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(tz.TZDateTime(tz.local, 2024, 1, 1));
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = ScheduledTripNotificationService(mockPlugin);

    when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});
    when(() => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        )).thenAnswer((_) async {});
  });

  group('scheduleReminder', () {
    test('schedules at 8 PM the day before departure', () async {
      await service.scheduleReminder(sampleTrip);

      final captured =
          verify(() => mockPlugin.zonedSchedule(
                any(),
                any(),
                any(),
                captureAny(),
                any(),
                androidScheduleMode: any(named: 'androidScheduleMode'),
                matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
                payload: any(named: 'payload'),
                uiLocalNotificationDateInterpretation:
                    any(named: 'uiLocalNotificationDateInterpretation'),
              )).captured.first;
      final tzDateTime = captured as dynamic;
      expect(tzDateTime.year, 2026);
      expect(tzDateTime.month, 7);
      expect(tzDateTime.day, 26);
      expect(tzDateTime.hour, 20);
      expect(tzDateTime.minute, 0);
    });

    test('uses correct notification ID', () async {
      await service.scheduleReminder(sampleTrip);

      verify(() => mockPlugin.zonedSchedule(
            2000 + 'trip-1'.hashCode,
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: any(named: 'payload'),
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
          )).called(1);
    });

    test('uses correct title and body', () async {
      await service.scheduleReminder(sampleTrip);

      verify(() => mockPlugin.zonedSchedule(
            any(),
            'Trip Tomorrow: Work',
            'Departure at 2:30 PM — 1 stop',
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: any(named: 'payload'),
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
          )).called(1);
    });

    test('uses correct payload', () async {
      await service.scheduleReminder(sampleTrip);

      verify(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: 'scheduled_trip:trip-1',
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
          )).called(1);
    });

    test('sets androidScheduleMode to inexactAllowWhileIdle', () async {
      await service.scheduleReminder(sampleTrip);

      verify(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: any(named: 'payload'),
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
          )).called(1);
    });

    test('sets matchDateTimeComponents to null', () async {
      await service.scheduleReminder(sampleTrip);

      verify(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: null,
            payload: any(named: 'payload'),
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
          )).called(1);
    });

    test('shows plural stops text for multi-stop trip', () async {
      final multiStopTrip = sampleTrip.copyWith(
        waypointsJson:
            '[{"id":"wp-1","name":"A","latitude":40.0,"longitude":-74.0,"alertRadius":300,"orderIndex":0},{"id":"wp-2","name":"B","latitude":41.0,"longitude":-75.0,"alertRadius":500,"orderIndex":1}]',
      );

      await service.scheduleReminder(multiStopTrip);

      verify(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            'Departure at 2:30 PM — 2 stops',
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: any(named: 'payload'),
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
          )).called(1);
    });
  });

  group('cancelReminder', () {
    test('cancels correct notification ID', () async {
      await service.cancelReminder('trip-1');

      verify(() => mockPlugin.cancel(2000 + 'trip-1'.hashCode)).called(1);
    });
  });
}
