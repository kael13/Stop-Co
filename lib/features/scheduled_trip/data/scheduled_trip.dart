import '../../trip/data/waypoint.dart';

enum ScheduledTripStatus { pending, completed, cancelled }

extension ScheduledTripStatusExt on ScheduledTripStatus {
  String get label {
    switch (this) {
      case ScheduledTripStatus.pending:
        return 'Pending';
      case ScheduledTripStatus.completed:
        return 'Completed';
      case ScheduledTripStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class ScheduledTrip {
  final String id;
  final String name;
  final String? description;
  final String waypointsJson;
  final DateTime scheduledStartTime;
  final ScheduledTripStatus status;
  final DateTime createdAt;

  const ScheduledTrip({
    required this.id,
    required this.name,
    this.description,
    required this.waypointsJson,
    required this.scheduledStartTime,
    this.status = ScheduledTripStatus.pending,
    required this.createdAt,
  });

  List<Waypoint> get waypoints => Waypoint.deserializeList(waypointsJson);

  ScheduledTrip copyWith({
    String? id,
    String? name,
    String? description,
    String? waypointsJson,
    DateTime? scheduledStartTime,
    ScheduledTripStatus? status,
    DateTime? createdAt,
  }) {
    return ScheduledTrip(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      waypointsJson: waypointsJson ?? this.waypointsJson,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'waypointsJson': waypointsJson,
    'scheduledStartTime': scheduledStartTime.toIso8601String(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ScheduledTrip.fromJson(Map<String, dynamic> json) => ScheduledTrip(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    waypointsJson: json['waypointsJson'] as String,
    scheduledStartTime: DateTime.parse(json['scheduledStartTime'] as String),
    status: ScheduledTripStatus.values.firstWhere((e) => e.name == json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
