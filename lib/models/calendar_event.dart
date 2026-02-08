import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { practice, race, workout, meeting, organization, other }

// 1. Move the display logic here using an Extension
extension EventTypeExtension on EventType {
  String get typeDisplayName {
    switch (this) {
      case EventType.practice:
        return 'Practice';
      case EventType.race:
        return 'Race';
      case EventType.workout:
        return 'Workout';
      case EventType.meeting:
        return 'Meeting';
      case EventType.organization:
        return 'Organization';
      case EventType.other:
        return 'Other';
    }
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final String? location;
  final String organizationId;
  final String? teamId;
  final String createdByUserId;
  final List<String> linkedWorkoutSessionIds;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.location,
    required this.organizationId,
    this.teamId,
    required this.createdByUserId,
    this.linkedWorkoutSessionIds = const [],
  });

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      // Pro-tip: Store enums as strings (e.name) to be cleaner
      type: EventType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => EventType.other,
      ),
      location: data['location'],
      organizationId: data['organizationId'] ?? '',
      teamId: data['teamId'],
      createdByUserId: data['createdByUserId'] ?? '',
      linkedWorkoutSessionIds: List<String>.from(
        data['linkedWorkoutSessionIds'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'type': type.toString(),
      'location': location,
      'organizationId': organizationId,
      'teamId': teamId,
      'createdByUserId': createdByUserId,
      'linkedWorkoutSessionIds': linkedWorkoutSessionIds,
    };
  }

  // 2. You can keep this helper here if you want, or use the extension directly
  bool get canLinkWorkouts => type == EventType.practice;
}
