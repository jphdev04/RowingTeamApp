import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'teams';

  // Create a new team
  Future<Team> createTeam(String name, String coachId) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final team = Team(
        id: docRef.id,
        name: name,
        coachId: coachId,
        coachIds: [coachId],
        createdAt: DateTime.now(),
      );
      await docRef.set(team.toMap());
      return team;
    } catch (e) {
      throw 'Error creating team: $e';
    }
  }

  // Get team by ID
  Future<Team?> getTeam(String teamId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(teamId)
          .get();
      if (doc.exists) {
        return Team.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error getting team: $e';
    }
  }

  // Get team by coach ID
  Future<Team?> getTeamByCoachId(String coachId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('coachId', isEqualTo: coachId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Team.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error getting team by coach: $e';
    }
  }

  // Get team stream (real-time updates)
  Stream<Team?> getTeamStream(String teamId) {
    return _firestore.collection(_collection).doc(teamId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return Team.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update team
  Future<void> updateTeam(Team team) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(team.id)
          .update(team.toMap());
    } catch (e) {
      throw 'Error updating team: $e';
    }
  }
}
