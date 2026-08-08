import '../../trip/data/waypoint.dart';

enum ScheduledTripStatus { pending, completed, cancelled }

enum RemindBefore { hourBefore }

extension RemindBeforeExt on RemindBefore {
  String get label {
    switch (this) {
      case RemindBefore.hourBefore:
        return 'An hour before';
    }
  }
}

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

extension DisplayStatus on ScheduledTrip {
  String get displayStatusLabel {
    if (alarmTriggered) return 'Notified';
    return status.label;
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
  final RemindBefore remindBefore;
  final int? alarmTriggeredAtEpochMs;

  const ScheduledTrip({
    required this.id,
    required this.name,
    this.description,
    required this.waypointsJson,
    required this.scheduledStartTime,
    this.status = ScheduledTripStatus.pending,
    required this.createdAt,
    this.remindBefore = RemindBefore.hourBefore,
    this.alarmTriggeredAtEpochMs,
  });

  DateTime? get alarmTriggeredAt => alarmTriggeredAtEpochMs != null
      ? DateTime.fromMillisecondsSinceEpoch(alarmTriggeredAtEpochMs!)
      : null;

  bool get alarmTriggered => alarmTriggeredAtEpochMs != null;

  List<Waypoint> get waypoints => Waypoint.deserializeList(waypointsJson);

  ScheduledTrip copyWith({
    String? id,
    String? name,
    String? description,
    String? waypointsJson,
    DateTime? scheduledStartTime,
    ScheduledTripStatus? status,
    DateTime? createdAt,
    RemindBefore? remindBefore,
    int? alarmTriggeredAtEpochMs,
  }) {
    return ScheduledTrip(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      waypointsJson: waypointsJson ?? this.waypointsJson,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      remindBefore: remindBefore ?? this.remindBefore,
      alarmTriggeredAtEpochMs: alarmTriggeredAtEpochMs ?? this.alarmTriggeredAtEpochMs,
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
    'remindBefore': remindBefore.name,
    'alarmTriggeredAtEpochMs': alarmTriggeredAtEpochMs,
  };

  factory ScheduledTrip.fromJson(Map<String, dynamic> json) => ScheduledTrip(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    waypointsJson: json['waypointsJson'] as String,
    scheduledStartTime: DateTime.parse(json['scheduledStartTime'] as String),
    status: ScheduledTripStatus.values.firstWhere((e) => e.name == json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    remindBefore: json['remindBefore'] != null
        ? RemindBefore.values.firstWhere(
            (e) => e.name == json['remindBefore'] as String,
            orElse: () => RemindBefore.hourBefore,
          )
        : RemindBefore.hourBefore,
    alarmTriggeredAtEpochMs: json['alarmTriggeredAtEpochMs'] as int?,
  );
}
