import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database.dart';
import 'core/database/database_provider.dart';
import 'core/platform/reminder_alarm_callback_channel.dart';
import 'core/services/tile_cache_service.dart';
import 'core/services/tile_cache_providers.dart';
import 'features/scheduled_trip/data/scheduled_trip_repository.dart';
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool _pluginInitialized = false;

Future<void> _initPluginOnce(LocalDatabase db) async {
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
    onDidReceiveNotificationResponse: (response) async {
      final payload = response.payload;
      if (payload == 'alarm') {
        navigatorKey.currentState?.pushReplacementNamed('/alarm');
      } else if (payload != null && payload.startsWith('scheduled_trip:')) {
        final tripId = payload.substring('scheduled_trip:'.length);
        if (tripId == 'test') return;
        // Mark alarm as triggered when user taps the notification
        await ScheduledTripRepository(db).markAlarmTriggered(tripId, DateTime.now());
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
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  final androidPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.deleteNotificationChannel(AppConstants.tripReminderChannelId);
  await androidPlugin?.createNotificationChannel(androidChannel);
}

Future<void> _initNotifications(LocalDatabase db) async {
  tz_data.initializeTimeZones();
  await _initPluginOnce(db);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  final db = LocalDatabase();

  final tileCache = TileCacheService();
  await tileCache.init();

  await _initNotifications(db);
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

  // Drain native alarm triggers that may have fired while app was killed
  await _drainPendingAlarmTriggers(db);

  // Listen for notification taps from the native ReminderMonitorService
  _setupNotificationTapHandler();

  // Check for a pending trip from cold-start notification tap
  _checkPendingNotificationTap();
}

void _setupNotificationTapHandler() {
  final channel = MethodChannel('com.stopco.app/notification_tap');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'scheduledTrip') {
      final tripId = call.arguments as String;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed(
          '/scheduled-trip-detail',
          arguments: tripId,
        );
      });
    }
  });
}

Future<void> _checkPendingNotificationTap() async {
  try {
    final channel = MethodChannel('com.stopco.app/notification_tap');
    final tripId = await channel.invokeMethod<String>('getPendingScheduledTrip');
    if (tripId != null && tripId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed(
          '/scheduled-trip-detail',
          arguments: tripId,
        );
      });
    }
  } catch (_) {}
}

Future<void> _drainPendingAlarmTriggers(LocalDatabase db) async {
  final triggers = await ReminderAlarmCallbackChannel.drainPendingTriggers();
  if (triggers.isEmpty) return;
  final repo = ScheduledTripRepository(db);
  for (final entry in triggers.entries) {
    await repo.markAlarmTriggered(
      entry.key,
      DateTime.fromMillisecondsSinceEpoch(entry.value),
    );
  }
}
