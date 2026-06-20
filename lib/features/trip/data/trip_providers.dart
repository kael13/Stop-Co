import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../destination/data/destination_model.dart';
import '../../settings/data/settings_providers.dart';
import '../domain/route_result.dart';
import 'alarm_notification_service.dart';
import 'trip_model.dart';
import 'trip_record.dart';
import 'trip_repository.dart';

const _uuid = Uuid();

final activeTripProvider = StateNotifierProvider<ActiveTripNotifier, ActiveTrip?>((ref) {
  return ActiveTripNotifier(ref);
});

class ActiveTripNotifier extends StateNotifier<ActiveTrip?> {
  final Ref _ref;

  ActiveTripNotifier(this._ref) : super(null);

  void startTrip(Destination destination) {
    state = ActiveTrip(
      destination: destination,
      startedAt: DateTime.now(),
    );
  }

  void updateDistance(double distance) {
    if (state == null) return;
    state = state!.copyWith(currentDistance: distance);
  }

  void setRouteResult(RouteResult route) {
    if (state == null) return;
    state = state!.copyWith(routeResult: route);
  }

  void triggerAlarm() {
    if (state == null) return;
    state = state!.copyWith(
      status: TripStatus.alarmTriggered,
      hasAlerted: true,
    );
    final alarmType = _ref.read(settingsProvider).alarmType;
    AlarmNotificationService.showAlarmNotification(
      destinationName: state!.destination.name,
      distance: state!.currentDistance ?? 0,
      alarmType: alarmType,
    );
  }

  void cancelTrip() {
    _persistTrip(TripStatus.cancelled);
    state = null;
    AlarmNotificationService.dismissAlarm();
  }

  void completeTrip() {
    _persistTrip(state?.status ?? TripStatus.completed);
    state = null;
    AlarmNotificationService.dismissAlarm();
  }

  void _persistTrip(TripStatus finalStatus) {
    final trip = state;
    if (trip == null) return;
    final repo = _ref.read(tripRepositoryProvider);
    repo.save(TripRecord(
      id: _uuid.v4(),
      destinationId: trip.destination.id,
      destinationName: trip.destination.name,
      status: finalStatus,
      startedAt: trip.startedAt,
      endedAt: DateTime.now(),
      totalDistance: trip.currentDistance ?? 0,
      plannedRouteDistance: trip.routeResult?.distanceMeters,
      plannedRouteDuration: trip.routeResult?.durationSeconds,
      routeCoordinatesJson:
          TripRecord.serializeCoordinates(trip.routeResult?.coordinates),
      createdAt: DateTime.now(),
    ));
  }
}

final recentTripsProvider = StreamProvider<List<TripRecord>>((ref) {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchRecent(limit: 10);
});
