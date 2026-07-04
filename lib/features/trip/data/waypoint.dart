import 'dart:convert';
import '../../destination/data/destination_model.dart';

class Waypoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double alertRadius;
  final int orderIndex;

  const Waypoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.alertRadius = 300,
    this.orderIndex = 0,
  });

  factory Waypoint.fromDestination(Destination d, int index) {
    return Waypoint(
      id: d.id,
      name: d.name,
      latitude: d.latitude,
      longitude: d.longitude,
      alertRadius: d.alertRadius,
      orderIndex: index,
    );
  }

  Waypoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? alertRadius,
    int? orderIndex,
  }) {
    return Waypoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      alertRadius: alertRadius ?? this.alertRadius,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'alertRadius': alertRadius,
    'orderIndex': orderIndex,
  };

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
    id: json['id'] as String,
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    alertRadius: (json['alertRadius'] as num).toDouble(),
    orderIndex: (json['orderIndex'] as num).toInt(),
  );

  static String? serializeList(List<Waypoint>? waypoints) {
    if (waypoints == null || waypoints.isEmpty) return null;
    return jsonEncode(waypoints.map((w) => w.toJson()).toList());
  }

  static List<Waypoint> deserializeList(String? json) {
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((item) => Waypoint.fromJson(item as Map<String, dynamic>)).toList();
  }
}
