import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app.dart';
import 'core/database/database.dart';
import 'core/database/database_provider.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const String alarmChannelId = 'stop_co_alarm';
const String alarmChannelName = 'Destination Alarm';
const String alarmChannelDesc = 'Alerts when approaching your destination';

Future<void> _initNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const iosSettings = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await notificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      if (response.payload == 'alarm') {
        navigatorKey.currentState?.pushNamed('/alarm');
      }
    },
  );

  final androidChannel = AndroidNotificationChannel(
    alarmChannelId,
    alarmChannelName,
    description: alarmChannelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initNotifications();

  final db = LocalDatabase();

  runApp(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
      ],
      child: const StopCoApp(),
    ),
  );
}
