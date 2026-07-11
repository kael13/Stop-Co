import '../../../core/database/database.dart';
import 'scheduled_trip.dart';

class ScheduledTripRepository {
  final LocalDatabase _db;

  ScheduledTripRepository(this._db);

  Stream<List<ScheduledTrip>> watchAll() {
    return _db.watchAllScheduledTrips();
  }

  Future<List<ScheduledTrip>> getAll() async {
    return _db.getAllScheduledTrips();
  }

  Future<void> save(ScheduledTrip trip) {
    return _db.saveScheduledTrip(trip);
  }

  Future<void> updateStatus(String id, ScheduledTripStatus status) {
    return _db.updateScheduledTripStatus(id, status);
  }

  Future<void> delete(String id) {
    return _db.deleteScheduledTrip(id);
  }
}
