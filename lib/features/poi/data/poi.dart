class Poi {
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final Map<String, String> tags;

  const Poi({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.tags = const {},
  });

  String get emoji {
    switch (category) {
      case 'restaurant':
      case 'cafe':
      case 'fast_food':
        return '\u{1F37D}\u{FE0F}';
      case 'pub':
      case 'bar':
        return '\u{1F37A}';
      case 'fuel':
        return '\u{26FD}\u{FE0F}';
      case 'parking':
      case 'parking_entrance':
        return '\u{1F17F}\u{FE0F}';
      case 'atm':
      case 'bank':
        return '\u{1F3E6}';
      case 'pharmacy':
        return '\u{1F48A}';
      case 'hospital':
      case 'clinic':
        return '\u{1F3E5}';
      case 'police':
        return '\u{1F6A8}';
      case 'fire_station':
        return '\u{1F692}';
      case 'supermarket':
      case 'convenience':
        return '\u{1F6EA}';
      case 'mall':
      case 'department_store':
        return '\u{1F3EC}';
      case 'attraction':
      case 'viewpoint':
      case 'museum':
      case 'historic':
      case 'castle':
      case 'monument':
        return '\u{1F3DB}\u{FE0F}';
      case 'hotel':
      case 'motel':
      case 'hostel':
        return '\u{1F3E8}';
      case 'park':
      case 'playground':
      case 'garden':
        return '\u{1F331}';
      case 'public_transport':
      case 'bus_station':
      case 'ferry_terminal':
        return '\u{1F68C}';
      default:
        return '\u{1F4CD}';
    }
  }

  bool hasTag(String key) => tags.containsKey(key) && (tags[key] ?? '').isNotEmpty;

  String get categoryLabel {
    switch (category) {
      case 'restaurant':
        return 'Restaurant';
      case 'cafe':
        return 'Cafe';
      case 'fast_food':
        return 'Fast Food';
      case 'pub':
        return 'Pub';
      case 'bar':
        return 'Bar';
      case 'fuel':
        return 'Gas Station';
      case 'parking':
        return 'Parking';
      case 'atm':
        return 'ATM';
      case 'bank':
        return 'Bank';
      case 'pharmacy':
        return 'Pharmacy';
      case 'hospital':
        return 'Hospital';
      case 'clinic':
        return 'Clinic';
      case 'police':
        return 'Police';
      case 'fire_station':
        return 'Fire Station';
      case 'supermarket':
        return 'Supermarket';
      case 'convenience':
        return 'Convenience Store';
      case 'mall':
        return 'Mall';
      case 'department_store':
        return 'Department Store';
      case 'attraction':
      case 'viewpoint':
      case 'museum':
        return 'Attraction';
      case 'historic':
      case 'castle':
      case 'monument':
        return 'Historic Site';
      case 'hotel':
      case 'motel':
        return 'Hotel';
      case 'park':
      case 'playground':
      case 'garden':
        return 'Park';
      case 'public_transport':
        return 'Public Transport';
      default:
        return 'POI';
    }
  }
}
