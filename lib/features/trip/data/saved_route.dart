import 'waypoint.dart';

class SavedRoute {
  final String id;
  final String name;
  final String waypointsJson;
  final bool isFavorite;
  final DateTime createdAt;

  const SavedRoute({
    required this.id,
    required this.name,
    required this.waypointsJson,
    this.isFavorite = false,
    required this.createdAt,
  });

  List<Waypoint> get waypoints => Waypoint.deserializeList(waypointsJson);

  SavedRoute copyWith({
    String? id,
    String? name,
    String? waypointsJson,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return SavedRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      waypointsJson: waypointsJson ?? this.waypointsJson,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'waypointsJson': waypointsJson,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedRoute.fromJson(Map<String, dynamic> json) => SavedRoute(
    id: json['id'] as String,
    name: json['name'] as String,
    waypointsJson: json['waypointsJson'] as String,
    isFavorite: json['isFavorite'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  static SavedRoute fromWaypoints({
    required List<Waypoint> waypoints,
    String? name,
    String? id,
  }) {
    final autoName = name ?? waypoints.map((w) => w.name).join(' → ');
    return SavedRoute(
      id: id ?? waypoints.first.id,
      name: autoName,
      waypointsJson: Waypoint.serializeList(waypoints) ?? '[]',
      createdAt: DateTime.now(),
    );
  }
}
