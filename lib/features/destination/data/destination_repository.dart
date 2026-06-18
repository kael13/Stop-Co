import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import 'destination_model.dart';

final destinationRepositoryProvider =
    Provider<DestinationRepository>((ref) {
  final db = ref.read(localDatabaseProvider);
  return DestinationRepository(db);
});

class DestinationRepository {
  final LocalDatabase _db;

  DestinationRepository(this._db);

  Future<void> save(Destination destination) =>
      _db.saveDestination(destination);

  Future<void> deleteAll() => _db.deleteAllDestinations();

  Future<void> delete(String destinationId) =>
      _db.deleteDestination(destinationId);

  Future<void> update(Destination destination) =>
      _db.updateDestination(destination);

  Stream<List<Destination>> watchAll() => _db.watchAllDestinations();

  Future<List<Destination>> getAll() => _db.getAllDestinations();
}
