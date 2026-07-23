import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';

class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class GeocodingService {
  String? _cachedCountryCode;

  Future<String?> _resolveCountryCode(double lat, double lon) async {
    if (_cachedCountryCode != null) return _cachedCountryCode;
    try {
      final uri = Uri.parse(
        '${AppConstants.tomtomBaseUrl}/search/2/reverseGeocode/$lat,$lon.json'
        '?key=${AppConstants.tomtomApiKey}',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> addresses = body['addresses'] as List<dynamic>? ?? [];
      if (addresses.isEmpty) return null;
      final addr = addresses[0]['address'] as Map<String, dynamic>?;
      _cachedCountryCode = addr?['countryCode'] as String?;
      return _cachedCountryCode;
    } catch (_) {
      return null;
    }
  }

  Future<List<GeocodingResult>> search(String query, {double? nearLat, double? nearLon}) async {
    var url = '${AppConstants.tomtomBaseUrl}/search/2/search/'
        '${Uri.encodeComponent(query)}.json'
        '?key=${AppConstants.tomtomApiKey}'
        '&limit=5';
    if (nearLat != null && nearLon != null) {
      url += '&lat=$nearLat&lon=$nearLon';
      final country = await _resolveCountryCode(nearLat, nearLon);
      if (country != null) url += '&countrySet=$country';
    }
    final uri = Uri.parse(url);

    final response = await http.get(uri);

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> results = body['results'] as List<dynamic>? ?? [];
    return results.map((item) {
      final pos = item['position'] as Map<String, dynamic>;
      final addr = item['address'] as Map<String, dynamic>?;
      final poi = item['poi'] as Map<String, dynamic>?;
      final displayName = poi?['name'] != null
          ? [
              poi!['name'] as String,
              if (addr?['streetName'] case final s? when (s as String).isNotEmpty) s,
              if (addr?['municipality'] case final m? when (m as String).isNotEmpty) m,
            ].join(', ')
          : addr?['freeformAddress'] as String? ?? 'Unknown';
      return GeocodingResult(
        displayName: displayName,
        latitude: (pos['lat'] as num).toDouble(),
        longitude: (pos['lon'] as num).toDouble(),
      );
    }).toList();
  }

  Future<String?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse(
      '${AppConstants.tomtomBaseUrl}/search/2/reverseGeocode/$lat,$lon.json'
      '?key=${AppConstants.tomtomApiKey}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> addresses = body['addresses'] as List<dynamic>? ?? [];
    if (addresses.isEmpty) return null;
    final addr = addresses[0]['address'] as Map<String, dynamic>?;
    return addr?['freeformAddress'] as String?;
  }
}
