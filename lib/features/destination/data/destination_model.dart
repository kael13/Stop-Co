class Destination {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double alertRadius;
  final bool isFavorite;
  final DateTime createdAt;

  const Destination({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.alertRadius = 300,
    this.isFavorite = false,
    required this.createdAt,
  });

  Destination copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? alertRadius,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      alertRadius: alertRadius ?? this.alertRadius,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }


}
