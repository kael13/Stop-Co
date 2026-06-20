import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import 'trip_record.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final db = ref.read(localDatabaseProvider);
  return TripRepository(db);
});

class TripRepository {
  final LocalDatabase _db;

  TripRepository(this._db);

  Future<void> save(TripRecord trip) => _db.saveTrip(trip);

  Future<void> delete(String id) => _db.deleteTrip(id);

  Future<void> deleteAll() => _db.deleteAllTrips();

  Stream<List<TripRecord>> watchRecent({int limit = 10}) =>
      _db.watchRecentTrips(limit: limit);

  Future<List<TripRecord>> getRecent({int limit = 10}) =>
      _db.getRecentTrips(limit: limit);
}
