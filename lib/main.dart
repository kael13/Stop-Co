import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database.dart';
import 'core/database/database_provider.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool _pluginInitialized = false;

Future<void> _initPluginOnce() async {
  if (_pluginInitialized) return;
  _pluginInitialized = true;

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
}

Future<void> _createAlarmChannel() async {
  final androidChannel = AndroidNotificationChannel(
    AppConstants.alarmChannelId,
    AppConstants.alarmChannelName,
    description: AppConstants.alarmChannelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
  );

  final androidPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.deleteNotificationChannel(AppConstants.alarmChannelId);
  await androidPlugin?.createNotificationChannel(androidChannel);
}

Future<void> _initNotifications() async {
  await _initPluginOnce();
  await _createAlarmChannel();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  final db = LocalDatabase();

  await _initNotifications();

  runApp(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
      ],
      child: const StopCoApp(),
    ),
  );
}
