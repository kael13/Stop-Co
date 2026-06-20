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

UriAndroidNotificationSound _alarmUri(String path) {
  return UriAndroidNotificationSound(
    path.startsWith('content://') ? path : 'file://$path',
  );
}

Future<void> _initNotifications({String? customSoundPath}) async {
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
    AppConstants.alarmChannelId,
    AppConstants.alarmChannelName,
    description: AppConstants.alarmChannelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    sound: customSoundPath != null
        ? _alarmUri(customSoundPath)
        : null,
    vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
  );

  final androidPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.deleteNotificationChannel(AppConstants.alarmChannelId);
  await androidPlugin?.createNotificationChannel(androidChannel);
}

Future<void> recreateAlarmChannel(String? customSoundPath) async {
  await _initNotifications(customSoundPath: customSoundPath);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  final db = LocalDatabase();
  final storedSettings = await db.getAppSettings();

  await _initNotifications(
    customSoundPath: storedSettings?.customAlarmSoundPath,
  );

  runApp(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
      ],
      child: const StopCoApp(),
    ),
  );
}
