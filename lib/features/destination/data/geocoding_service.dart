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
  Future<List<GeocodingResult>> search(String query) async {
    final uri = Uri.parse(
      '${AppConstants.nominatimBaseUrl}/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&limit=5'
      '&addressdetails=0',
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': AppConstants.userAgent},
    );

    if (response.statusCode != 200) return [];

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) {
      return GeocodingResult(
        displayName: item['display_name'] as String? ?? 'Unknown',
        latitude: double.parse(item['lat'] as String),
        longitude: double.parse(item['lon'] as String),
      );
    }).toList();
  }

  Future<String?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse(
      '${AppConstants.nominatimBaseUrl}/reverse'
      '?lat=$lat&lon=$lon'
      '&format=json',
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': AppConstants.userAgent},
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['display_name'] as String?;
  }
}
