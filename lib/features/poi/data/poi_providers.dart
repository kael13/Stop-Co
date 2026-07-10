import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'overpass_service.dart';
import 'poi.dart';

final overpassServiceProvider = Provider<OverpassService>((ref) {
  return OverpassService();
});

class PoiQueryArgs {
  final LatLng center;
  final int radius;

  const PoiQueryArgs({required this.center, this.radius = 500});

  @override
  bool operator ==(Object other) =>
      other is PoiQueryArgs &&
      other.center.latitude == center.latitude &&
      other.center.longitude == center.longitude &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(center.latitude, center.longitude, radius);
}

const _maxPois = 5;

final nearbyPoisProvider = FutureProvider.autoDispose.family<List<Poi>, PoiQueryArgs>((ref, args) async {
  final service = ref.watch(overpassServiceProvider);
  final pois = await service.fetchNearbyPois(args.center, radius: args.radius);
  pois.sort((a, b) => _poiPriority(a).compareTo(_poiPriority(b)));
  return pois.take(_maxPois).toList();
});

int _poiPriority(Poi poi) {
  switch (poi.category) {
    case 'mall':
    case 'department_store':
    case 'attraction':
    case 'museum':
    case 'historic':
    case 'monument':
    case 'castle':
    case 'park':
    case 'hotel':
    case 'motel':
    case 'hostel':
      return 1;
    case 'restaurant':
    case 'cafe':
    case 'fast_food':
    case 'pub':
    case 'bar':
    case 'supermarket':
    case 'convenience':
    case 'hospital':
    case 'clinic':
      return 2;
    default:
      return 3;
  }
}
