import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../main.dart' show notificationsPlugin;
import '../../trip/data/trip_providers.dart';
import 'scheduled_trip.dart';
import 'scheduled_trip_notification_service.dart';
import 'scheduled_trip_repository.dart';

final scheduledTripRepositoryProvider = Provider<ScheduledTripRepository>((ref) {
  final db = ref.read(localDatabaseProvider);
  return ScheduledTripRepository(db);
});

final scheduledTripsProvider = StreamProvider<List<ScheduledTrip>>((ref) {
  final repo = ref.watch(scheduledTripRepositoryProvider);
  return repo.watchAll();
});

final createScheduledTripAction = FutureProvider.family<void, ScheduledTrip>((ref, trip) async {
  final repo = ref.read(scheduledTripRepositoryProvider);
  await repo.save(trip);
});

final cancelScheduledTripAction = FutureProvider.family<void, String>((ref, id) async {
  final repo = ref.read(scheduledTripRepositoryProvider);
  await repo.updateStatus(id, ScheduledTripStatus.cancelled);
});

final deleteScheduledTripAction = FutureProvider.family<void, String>((ref, id) async {
  final repo = ref.read(scheduledTripRepositoryProvider);
  await repo.delete(id);
});

final startScheduledTripAction = FutureProvider.family<void, ScheduledTrip>((ref, trip) async {
  final notifier = ref.read(activeTripProvider.notifier);
  notifier.startTripWithWaypoints(trip.waypoints);
});

final completeScheduledTripAction = FutureProvider.family<void, String>((ref, id) async {
  final repo = ref.read(scheduledTripRepositoryProvider);
  await repo.updateStatus(id, ScheduledTripStatus.completed);
});

final markAlarmTriggeredAction = FutureProvider.family<void, String>((ref, id) async {
  final repo = ref.read(scheduledTripRepositoryProvider);
  await repo.markAlarmTriggered(id, DateTime.now());
  ref.invalidate(scheduledTripsProvider);
});

final scheduledTripNotificationServiceProvider = Provider<ScheduledTripNotificationService>((ref) {
  return ScheduledTripNotificationService(notificationsPlugin);
});
