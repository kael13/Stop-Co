import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../destination/data/destination_model.dart';
import '../../settings/data/settings_providers.dart';
import '../domain/route_result.dart';
import 'alarm_notification_service.dart';
import 'trip_model.dart';

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
    state = null;
    AlarmNotificationService.dismissAlarm();
  }

  void completeTrip() {
    state = null;
    AlarmNotificationService.dismissAlarm();
  }
}
