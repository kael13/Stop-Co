import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'destination_model.dart';
import 'destination_repository.dart';

final destinationListProvider = StreamProvider<List<Destination>>((ref) {
  final repo = ref.watch(destinationRepositoryProvider);
  return repo.watchAll();
});

final recommendedDestinationsProvider = StreamProvider<List<Destination>>((ref) {
  final repo = ref.watch(destinationRepositoryProvider);
  return repo.watchAll().map((destinations) {
    final sorted = [...destinations]..sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  });
});
