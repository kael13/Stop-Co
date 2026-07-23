import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TileCacheService {
  TileCacheService({this.maxCacheBytes = _defaultMaxBytes});

  static const _defaultMaxBytes = 200 * 1024 * 1024; // 200 MB
  static const _tilesSubDir = 'tiles';

  final int maxCacheBytes;

  Directory? _cacheDir;
  CachedTileProvider? _tileProvider;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    final appCache = await getApplicationCacheDirectory();
    _cacheDir = Directory(p.join(appCache.path, _tilesSubDir));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    _tileProvider = CachedTileProvider(cacheDir: _cacheDir!, httpClient: http.Client());
    _initialized = true;
  }

  CachedTileProvider get tileProvider {
    if (!_initialized || _tileProvider == null) {
      throw StateError('TileCacheService not initialized. Call init() first.');
    }
    return _tileProvider!;
  }

  Future<int> get cachedTileCount async {
    if (!_initialized || _cacheDir == null) return 0;
    int count = 0;
    await for (final _ in _walkTiles()) {
      count++;
    }
    return count;
  }

  Future<int> get cacheSizeBytes async {
    if (!_initialized || _cacheDir == null) return 0;
    int total = 0;
    await for (final file in _walkTiles()) {
      total += await file.length();
    }
    return total;
  }

  Future<void> clearCache() async {
    if (!_initialized || _cacheDir == null) return;
    if (await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
    }
  }

  Future<void> evictIfNeeded() async {
    if (!_initialized || _cacheDir == null) return;
    int total = 0;
    final entries = <File>[];
    await for (final entity in _walkTiles()) {
      total += await entity.length();
      entries.add(entity);
    }
    if (total <= maxCacheBytes) return;

    entries.sort((a, b) {
      final aMod = a.statSync().changed;
      final bMod = b.statSync().changed;
      return aMod.compareTo(bMod);
    });

    for (final entry in entries) {
      if (total <= maxCacheBytes) break;
      total -= await entry.length();
      await entry.delete();
    }
  }

  Stream<File> _walkTiles() async* {
    if (_cacheDir == null || !await _cacheDir!.exists()) return;
    await for (final entity in _cacheDir!.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.png')) {
        yield entity;
      }
    }
  }
}

class CachedTileProvider extends TileProvider {
  CachedTileProvider({
    required this.cacheDir,
    required http.Client httpClient,
    super.headers,
  }) : _httpClient = httpClient;

  final Directory cacheDir;
  final http.Client _httpClient;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    final file = _tileFile(coordinates);

    if (file.existsSync()) {
      return FileImage(file);
    }

    _cacheTileAsync(url, file);

    return NetworkImage(url, headers: headers.isEmpty ? null : headers);
  }

  File _tileFile(TileCoordinates coords) {
    return File(p.join(cacheDir.path, '${coords.z}', '${coords.x}', '${coords.y}.png'));
  }

  Future<void> _cacheTileAsync(String url, File file) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    _httpClient.close();
    super.dispose();
  }
}
