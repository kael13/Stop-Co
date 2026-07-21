import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import 'saved_route.dart';

final savedRouteRepositoryProvider =
    Provider<SavedRouteRepository>((ref) {
  final db = ref.read(localDatabaseProvider);
  return SavedRouteRepository(db);
});

final savedRoutesProvider =
    StreamProvider<List<SavedRoute>>((ref) {
  final repo = ref.watch(savedRouteRepositoryProvider);
  return repo.watchAll();
});

class SavedRouteRepository {
  final LocalDatabase _db;

  SavedRouteRepository(this._db);

  Future<void> save(SavedRoute route) => _db.saveSavedRoute(route);

  Future<void> update(SavedRoute route) => _db.updateSavedRoute(route);

  Future<void> delete(String id) => _db.deleteSavedRoute(id);

  Stream<List<SavedRoute>> watchAll() => _db.watchAllSavedRoutes();

  Future<List<SavedRoute>> getAll() => _db.getAllSavedRoutes();
}
