import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  throw UnimplementedError(
    'Override this provider in ProviderScope with the database instance.',
  );
});
