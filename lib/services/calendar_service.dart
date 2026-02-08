import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Create event
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final data = event.toMap();
      data['id'] = docRef.id;
      await docRef.set(data);
      return CalendarEvent(
        id: docRef.id,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        type: event.type,
        location: event.location,
        organizationId: event.organizationId,
        teamId: event.teamId,
        createdByUserId: event.createdByUserId,
        linkedWorkoutSessionIds: event.linkedWorkoutSessionIds,
      );
    } catch (e) {
      throw 'Error creating event: $e';
    }
  }

  // Update event
  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update(updates);
    } catch (e) {
      throw 'Error updating event: $e';
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).delete();
    } catch (e) {
      throw 'Error deleting event: $e';
    }
  }

  // Get events for a team (real-time)
  Stream<List<CalendarEvent>> getTeamEvents(String teamId) {
    return _firestore
        .collection(_collection)
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CalendarEvent.fromFirestore(doc))
              .toList();
        });
  }

  // Get events for an organization (real-time)
  Stream<List<CalendarEvent>> getOrganizationEvents(String organizationId) {
    return _firestore
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CalendarEvent.fromFirestore(doc))
              .toList();
        });
  }

  // ── Practice-Workout Linking ────────────────────────────────

  /// Get upcoming practices for a team (for workout linking picker)
  Future<List<CalendarEvent>> getUpcomingPractices(
    String teamId, {
    int limit = 20,
  }) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('teamId', isEqualTo: teamId)
          .where('type', isEqualTo: EventType.practice.toString())
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('startTime')
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => CalendarEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      // If composite index doesn't exist yet, fall back to in-memory filter
      try {
        final snapshot = await _firestore
            .collection(_collection)
            .where('teamId', isEqualTo: teamId)
            .get();
        final events = snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .where(
              (e) =>
                  e.type == EventType.practice &&
                  e.startTime.isAfter(DateTime.now()),
            )
            .toList();
        events.sort((a, b) => a.startTime.compareTo(b.startTime));
        return events.take(limit).toList();
      } catch (e2) {
        throw 'Error getting upcoming practices: $e2';
      }
    }
  }

  /// Link a workout session to a practice event
  Future<void> linkWorkoutToEvent(
    String eventId,
    String workoutSessionId,
  ) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'linkedWorkoutSessionIds': FieldValue.arrayUnion([workoutSessionId]),
      });
    } catch (e) {
      throw 'Error linking workout to event: $e';
    }
  }

  /// Unlink a workout session from a practice event
  Future<void> unlinkWorkoutFromEvent(String eventId, String sessionId) async {
    await _firestore.collection('calendar_events').doc(eventId).update({
      'linkedWorkoutSessionIds': FieldValue.arrayRemove([sessionId]),
    });
  }

  /// Get a single event by ID
  Future<CalendarEvent?> getEvent(String eventId) async {
    final doc = await _firestore
        .collection('calendar_events')
        .doc(eventId)
        .get();
    if (!doc.exists) return null;
    return CalendarEvent.fromFirestore(doc);
  }
}
