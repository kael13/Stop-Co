import 'package:cloud_functions/cloud_functions.dart';

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

Map<String, dynamic> _castMap(dynamic value) {
  return (value as Map).map<String, dynamic>((k, v) => MapEntry('$k', v));
}

class GeocodingService {
  String? _cachedCountryCode;

  Future<String?> _resolveCountryCode(double lat, double lon) async {
    if (_cachedCountryCode != null) return _cachedCountryCode;
    try {
      final fn = FirebaseFunctions.instance.httpsCallable('tomtomReverseGeocode');
      final result = await fn.call({'lat': lat, 'lon': lon});
      final body = _castMap(result.data);
      final addresses = (body['addresses'] as List<dynamic>?) ?? [];
      if (addresses.isEmpty) return null;
      final addr = _castMap(addresses[0]['address']);
      _cachedCountryCode = addr['countryCode'] as String?;
      return _cachedCountryCode;
    } catch (_) {
      return null;
    }
  }

  Future<List<GeocodingResult>> search(String query, {double? nearLat, double? nearLon}) async {
    try {
      final fn = FirebaseFunctions.instance.httpsCallable('tomtomSearch');
      final Map<String, dynamic> params = {'query': query, 'limit': 5};
      if (nearLat != null && nearLon != null) {
        params['nearLat'] = nearLat;
        params['nearLon'] = nearLon;
        final country = await _resolveCountryCode(nearLat, nearLon);
        if (country != null) params['countrySet'] = country;
      }
      final result = await fn.call(params);
      final body = _castMap(result.data);
      final results = (body['results'] as List<dynamic>?) ?? [];
      return results.map((item) {
        final mapItem = _castMap(item);
        final pos = _castMap(mapItem['position']);
        final addr = mapItem['address'] != null ? _castMap(mapItem['address']) : null;
        final poi = mapItem['poi'] != null ? _castMap(mapItem['poi']) : null;
        final displayName = poi != null
            ? [
                poi['name'] as String,
                if ((addr?['streetName'] as String?) case final s? when s.isNotEmpty) s,
                if ((addr?['municipality'] as String?) case final m? when m.isNotEmpty) m,
              ].join(', ')
            : (addr?['freeformAddress'] as String?) ?? 'Unknown';
        return GeocodingResult(
          displayName: displayName,
          latitude: (pos['lat'] as num).toDouble(),
          longitude: (pos['lon'] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final fn = FirebaseFunctions.instance.httpsCallable('tomtomReverseGeocode');
      final result = await fn.call({'lat': lat, 'lon': lon});
      final body = _castMap(result.data);
      final addresses = (body['addresses'] as List<dynamic>?) ?? [];
      if (addresses.isEmpty) return null;
      final addr = _castMap(addresses[0]['address']);
      return addr['freeformAddress'] as String?;
    } catch (_) {
      return null;
    }
  }
}
