import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import 'poi.dart';

class OverpassService {
  static const _primaryUrl = 'https://overpass-api.de/api/interpreter';
  static const _fallbackUrls = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass-api.bplaced.net/api/interpreter',
  ];
  static const _defaultRadius = 1000;
  static const _maxResults = 40;

  Future<List<Poi>> fetchNearbyPois(LatLng center, {int radius = _defaultRadius, int limit = _maxResults}) async {
    if (radius <= 0) return [];
    final query = _buildQuery(center.latitude, center.longitude, radius, limit);

    final urls = [_primaryUrl, ..._fallbackUrls];
    for (final url in urls) {
      final result = await _tryUrl(url, query);
      if (result != null) return result;
    }

    debugPrint('[Overpass] all servers failed');
    return [];
  }

  Future<List<Poi>?> _tryUrl(String url, String query) async {
    for (final method in ['POST', 'GET']) {
      try {
        http.Response response;
        final uri = method == 'POST'
            ? Uri.parse(url)
            : Uri.parse('$url?data=${Uri.encodeQueryComponent(query)}');

        if (method == 'POST') {
          response = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
              'User-Agent': AppConstants.userAgent,
            },
            body: 'data=${Uri.encodeQueryComponent(query)}',
          ).timeout(const Duration(seconds: 12));
        } else {
          response = await http.get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': AppConstants.userAgent,
            },
          ).timeout(const Duration(seconds: 12));
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final elements = data['elements'] as List<dynamic>? ?? [];
          final pois = _parseElements(elements);
          debugPrint('[Overpass] $method $url → 200, ${pois.length} POIs');
          return pois;
        } else {
          debugPrint('[Overpass] $method $url → ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('[Overpass] $method $url → error: $e');
      }
    }
    return null;
  }

  String _buildQuery(double lat, double lon, int radius, int limit) {
    return '''
[out:json][timeout:10];
(
  node(around:$radius,$lat,$lon)["amenity"];
  node(around:$radius,$lat,$lon)["shop"];
  node(around:$radius,$lat,$lon)["tourism"];
  node(around:$radius,$lat,$lon)["leisure"];
  node(around:$radius,$lat,$lon)["historic"];
);
out center $limit;
''';
  }

  List<Poi> _parseElements(List<dynamic> elements) {
    final pois = <Poi>[];
    final seen = <String>{};

    for (final el in elements) {
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      var lat = _getCoord(el, 'lat');
      var lon = _getCoord(el, 'lon');
      if (lat == null || lon == null) {
        final center = el['center'] as Map<String, dynamic>?;
        lat = center != null ? _getCoord(center, 'lat') : null;
        lon = center != null ? _getCoord(center, 'lon') : null;
        if (lat == null || lon == null) continue;
      }

      final key = '$name-$lat-$lon';
      if (seen.contains(key)) continue;
      seen.add(key);

      final category = _resolveCategory(tags);

      pois.add(Poi(
        name: name,
        latitude: lat,
        longitude: lon,
        category: category,
        tags: tags.map((k, v) => MapEntry(k.toString(), v.toString())),
      ));
    }

    return pois;
  }

  String _resolveCategory(Map<String, dynamic> tags) {
    for (final key in ['amenity', 'shop', 'tourism', 'leisure', 'historic']) {
      final val = tags[key] as String?;
      if (val != null && val.isNotEmpty) return val;
    }
    return 'other';
  }

  double? _getCoord(Map<String, dynamic> el, String key) {
    final val = el[key];
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}
