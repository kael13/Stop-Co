import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database.dart';
import 'core/database/database_provider.dart';
import 'core/services/tile_cache_service.dart';
import 'core/services/tile_cache_providers.dart';
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
      final payload = response.payload;
      if (payload == 'alarm') {
        navigatorKey.currentState?.pushReplacementNamed('/alarm');
      } else if (payload != null && payload.startsWith('scheduled_trip:')) {
        final tripId = payload.substring('scheduled_trip:'.length);
        navigatorKey.currentState?.pushNamed(
          '/scheduled-trip-detail',
          arguments: tripId,
        );
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
    playSound: false,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  final androidPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.deleteNotificationChannel(AppConstants.alarmChannelId);
  await androidPlugin?.createNotificationChannel(androidChannel);
}

Future<void> _createTripReminderChannel() async {
  final androidChannel = AndroidNotificationChannel(
    AppConstants.tripReminderChannelId,
    AppConstants.tripReminderChannelName,
    description: AppConstants.tripReminderChannelDesc,
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: true,
  );

  final androidPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(androidChannel);
}

Future<void> _initNotifications() async {
  tz_data.initializeTimeZones();
  await _initPluginOnce();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  final db = LocalDatabase();

  final tileCache = TileCacheService();
  await tileCache.init();

  await _initNotifications();
  await _createAlarmChannel();
  await _createTripReminderChannel();

  runApp(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
        tileCacheServiceProvider.overrideWithValue(tileCache),
      ],
      child: const StopCoApp(),
    ),
  );
}
