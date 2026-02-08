import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../models/workout_result.dart';
import '../models/seat_race_analyses.dart';

class WorkoutService {
  final _firestore = FirebaseFirestore.instance;

  // ── Collection references ───────────────────────────────────

  CollectionReference _templates(String orgId) => _firestore
      .collection('organizations')
      .doc(orgId)
      .collection('workout_templates');

  CollectionReference _sessions(String orgId) => _firestore
      .collection('organizations')
      .doc(orgId)
      .collection('workout_sessions');

  CollectionReference _results(String orgId) => _firestore
      .collection('organizations')
      .doc(orgId)
      .collection('workout_results');

  CollectionReference _analyses(String orgId) => _firestore
      .collection('organizations')
      .doc(orgId)
      .collection('seat_race_analyses');

  // ════════════════════════════════════════════════════════════
  // TEMPLATES
  // ════════════════════════════════════════════════════════════

  /// Create a new workout template
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    final docRef = _templates(template.organizationId).doc();
    final withId = template.copyWith(id: docRef.id);
    await docRef.set(withId.toMap());
    return withId;
  }

  /// Update an existing template
  Future<void> updateTemplate(WorkoutTemplate template) async {
    await _templates(
      template.organizationId,
    ).doc(template.id).update(template.toMap());
  }

  /// Delete a template
  Future<void> deleteTemplate(String orgId, String templateId) async {
    await _templates(orgId).doc(templateId).delete();
  }

  /// Get a single template
  Future<WorkoutTemplate?> getTemplate(String orgId, String templateId) async {
    final doc = await _templates(orgId).doc(templateId).get();
    if (!doc.exists) return null;
    return WorkoutTemplate.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Stream all templates for an organization
  Stream<List<WorkoutTemplate>> getOrgTemplates(String orgId) {
    return _templates(orgId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutTemplate.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Stream templates for a specific team (includes org-wide templates)
  Stream<List<WorkoutTemplate>> getTeamTemplates(String orgId, String teamId) {
    return _templates(orgId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutTemplate.fromMap(doc.data() as Map<String, dynamic>),
              )
              .where((t) => t.teamId == null || t.teamId == teamId)
              .toList(),
        );
  }

  /// Stream benchmark templates (for historical comparison views)
  Stream<List<WorkoutTemplate>> getBenchmarkTemplates(
    String orgId, {
    String? teamId,
  }) {
    var query = _templates(orgId).where('isBenchmark', isEqualTo: true);
    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) =>
                WorkoutTemplate.fromMap(doc.data() as Map<String, dynamic>),
          )
          .where(
            (t) => teamId == null || t.teamId == null || t.teamId == teamId,
          )
          .toList(),
    );
  }

  /// Stream templates filtered by category
  Stream<List<WorkoutTemplate>> getTemplatesByCategory(
    String orgId,
    WorkoutCategory category, {
    String? teamId,
  }) {
    var query = _templates(orgId).where('category', isEqualTo: category.name);
    return query
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutTemplate.fromMap(doc.data() as Map<String, dynamic>),
              )
              .where(
                (t) => teamId == null || t.teamId == null || t.teamId == teamId,
              )
              .toList(),
        );
  }

  // ════════════════════════════════════════════════════════════
  // SESSIONS
  // ════════════════════════════════════════════════════════════

  /// Create a session (optionally from a template)
  Future<WorkoutSession> createSession(WorkoutSession session) async {
    final docRef = _sessions(session.organizationId).doc();
    final withId = session.copyWith(id: docRef.id);
    await docRef.set(withId.toMap());
    return withId;
  }

  /// Create a session from a template (snapshots the spec)
  Future<WorkoutSession> createSessionFromTemplate({
    required WorkoutTemplate template,
    required DateTime scheduledDate,
    required String createdBy,
    String? teamId,
    String? calendarEventId,
    bool hideUntilStart = false,
    bool athletesCanSeeResults = true,
  }) async {
    final session = WorkoutSession(
      id: '', // will be set by createSession
      organizationId: template.organizationId,
      teamId: teamId ?? template.teamId,
      templateId: template.id,
      calendarEventId: calendarEventId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      name: template.name,
      category: template.category,
      scheduledDate: scheduledDate,
      workoutSpec: template.toMap(), // frozen snapshot
      hideUntilStart: hideUntilStart,
      athletesCanSeeResults: athletesCanSeeResults,
    );
    return createSession(session);
  }

  /// Update a session
  Future<void> updateSession(WorkoutSession session) async {
    await _sessions(
      session.organizationId,
    ).doc(session.id).update(session.toMap());
  }

  /// Update session status
  Future<void> updateSessionStatus(
    String orgId,
    String sessionId,
    SessionStatus status,
  ) async {
    await _sessions(orgId).doc(sessionId).update({'status': status.name});
  }

  /// Delete a session
  Future<void> deleteSession(String orgId, String sessionId) async {
    await _sessions(orgId).doc(sessionId).delete();
  }

  /// Get a single session
  Future<WorkoutSession?> getSession(String orgId, String sessionId) async {
    final doc = await _sessions(orgId).doc(sessionId).get();
    if (!doc.exists) return null;
    return WorkoutSession.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Stream sessions for a team on a specific date
  Stream<List<WorkoutSession>> getTeamSessionsForDate(
    String orgId,
    String teamId,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _sessions(orgId)
        .where('teamId', isEqualTo: teamId)
        .where(
          'scheduledDate',
          isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
        )
        .where('scheduledDate', isLessThan: endOfDay.toIso8601String())
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutSession.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Stream all sessions for a team (recent first)
  Stream<List<WorkoutSession>> getTeamSessions(String orgId, String teamId) {
    return _sessions(orgId)
        .where('teamId', isEqualTo: teamId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutSession.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Stream sessions for a template (for benchmark history)
  Stream<List<WorkoutSession>> getSessionsForTemplate(
    String orgId,
    String templateId,
  ) {
    return _sessions(orgId)
        .where('templateId', isEqualTo: templateId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutSession.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Stream seat race sessions for a team
  Stream<List<WorkoutSession>> getSeatRaceSessions(
    String orgId,
    String teamId,
  ) {
    return _sessions(orgId)
        .where('teamId', isEqualTo: teamId)
        .where('isSeatRace', isEqualTo: true)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutSession.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // ════════════════════════════════════════════════════════════
  // RESULTS
  // ════════════════════════════════════════════════════════════

  /// Create or update a workout result
  Future<WorkoutResult> saveResult(WorkoutResult result) async {
    if (result.id.isEmpty) {
      // New result
      final docRef = _results(result.organizationId).doc();
      final withId = result.copyWith(id: docRef.id);
      await docRef.set(withId.toMap());
      return withId;
    } else {
      // Update existing
      await _results(
        result.organizationId,
      ).doc(result.id).update(result.toMap());
      return result;
    }
  }

  /// Delete a result
  Future<void> deleteResult(String orgId, String resultId) async {
    await _results(orgId).doc(resultId).delete();
  }

  /// Get all results for a session
  Stream<List<WorkoutResult>> getSessionResults(
    String orgId,
    String sessionId,
  ) {
    return _results(orgId)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutResult.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Get a specific user's result for a session
  Future<WorkoutResult?> getUserSessionResult(
    String orgId,
    String sessionId,
    String userId,
  ) async {
    final snap = await _results(orgId)
        .where('sessionId', isEqualTo: sessionId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return WorkoutResult.fromMap(
      snap.docs.first.data() as Map<String, dynamic>,
    );
  }

  /// Get all results for a user (personal training log)
  Stream<List<WorkoutResult>> getUserResults(String orgId, String userId) {
    return _results(orgId)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutResult.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Get personal-only results for a user (private, coaches can't see)
  Stream<List<WorkoutResult>> getPersonalResults(String orgId, String userId) {
    return _results(orgId)
        .where('userId', isEqualTo: userId)
        .where('isPersonal', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    WorkoutResult.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Get results for a user across sessions of a specific template (benchmark tracking)
  Future<List<WorkoutResult>> getUserBenchmarkResults(
    String orgId,
    String userId,
    String templateId,
  ) async {
    // First get all sessions for this template
    final sessionsSnap = await _sessions(
      orgId,
    ).where('templateId', isEqualTo: templateId).orderBy('scheduledDate').get();
    final sessionIds = sessionsSnap.docs.map((d) => d.id).toList();

    if (sessionIds.isEmpty) return [];

    // Firestore 'whereIn' supports max 30 items
    final results = <WorkoutResult>[];
    for (var i = 0; i < sessionIds.length; i += 30) {
      final chunk = sessionIds.sublist(
        i,
        i + 30 > sessionIds.length ? sessionIds.length : i + 30,
      );
      final snap = await _results(orgId)
          .where('sessionId', whereIn: chunk)
          .where('userId', isEqualTo: userId)
          .get();
      results.addAll(
        snap.docs.map(
          (d) => WorkoutResult.fromMap(d.data() as Map<String, dynamic>),
        ),
      );
    }

    return results;
  }

  // ════════════════════════════════════════════════════════════
  // SEAT RACE ANALYSES
  // ════════════════════════════════════════════════════════════

  /// Save a seat race analysis (create or update)
  Future<SeatRaceAnalysis> saveAnalysis(SeatRaceAnalysis analysis) async {
    if (analysis.id.isEmpty) {
      final docRef = _analyses(analysis.organizationId).doc();
      final withId = analysis.copyWith(id: docRef.id);
      await docRef.set(withId.toMap());
      return withId;
    } else {
      await _analyses(
        analysis.organizationId,
      ).doc(analysis.id).update(analysis.toMap());
      return analysis;
    }
  }

  /// Get analysis for a session
  Future<SeatRaceAnalysis?> getSessionAnalysis(
    String orgId,
    String sessionId,
  ) async {
    final snap = await _analyses(
      orgId,
    ).where('sessionId', isEqualTo: sessionId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return SeatRaceAnalysis.fromMap(
      snap.docs.first.data() as Map<String, dynamic>,
    );
  }

  /// Stream all seat race analyses for a team
  Stream<List<SeatRaceAnalysis>> getTeamAnalyses(String orgId, String teamId) {
    return _analyses(orgId)
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => SeatRaceAnalysis.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  /// Delete an analysis
  Future<void> deleteAnalysis(String orgId, String analysisId) async {
    await _analyses(orgId).doc(analysisId).delete();
  }
}
