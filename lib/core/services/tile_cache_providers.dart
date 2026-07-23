import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tile_cache_service.dart';

final tileCacheServiceProvider = Provider<TileCacheService>((ref) {
  final service = TileCacheService();
  ref.onDispose(() => service.tileProvider.dispose());
  return service;
});

final tileCacheInitializedProvider = FutureProvider<void>((ref) async {
  final service = ref.read(tileCacheServiceProvider);
  await service.init();
});

final tileCacheStatsProvider = FutureProvider<({int count, int sizeBytes})>((ref) async {
  final service = ref.read(tileCacheServiceProvider);
  if (!service.isInitialized) {
    await ref.watch(tileCacheInitializedProvider.future);
  }
  final count = await service.cachedTileCount;
  final sizeBytes = await service.cacheSizeBytes;
  return (count: count, sizeBytes: sizeBytes);
});
