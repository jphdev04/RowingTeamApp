import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _eventsRef => _firestore.collection('events');

  // Stream of events for a specific Organization
  // We filter by organizationId to keep data secure/relevant
  Stream<List<CalendarEvent>> getOrganizationEvents(String organizationId) {
    return _eventsRef
        .where('organizationId', isEqualTo: organizationId)
        // You might want to limit this to a date range (e.g., this month)
        // later for performance, but for now, let's get them all.
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CalendarEvent.fromFirestore(doc);
          }).toList();
        });
  }

  // Add a new event
  Future<void> createEvent(CalendarEvent event) async {
    await _eventsRef.add({
      'title': event.title,
      'description': event.description,
      'startTime': Timestamp.fromDate(event.startTime),
      'endTime': Timestamp.fromDate(event.endTime),
      'type': event.type.toString(), // Stores as "EventType.practice"
      'location': event.location,
      'organizationId': event.organizationId,
      'teamId': event.teamId,
      'createdByUserId': event.createdByUserId,
    });
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    await _eventsRef.doc(eventId).delete();
  }
}
