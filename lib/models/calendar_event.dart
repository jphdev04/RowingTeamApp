import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { practice, race, workout, meeting, organization, other }

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final String? location;

  // To filter by visibility
  final String organizationId;
  final String? teamId;
  final String createdByUserId;

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
  });

  // Factory to create from Firestore
  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      type: EventType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => EventType.other,
      ),
      location: data['location'],
      organizationId: data['organizationId'] ?? '',
      teamId: data['teamId'],
      createdByUserId: data['createdByUserId'] ?? '',
    );
  }
}
