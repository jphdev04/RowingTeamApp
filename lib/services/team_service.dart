import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'teams';

  // Create team with colors
  Future<Team> createTeamWithColors(
    String organizationId,
    String name,
    String headCoachId,
    int primaryColor,
    int secondaryColor, {
    String? description,
    String? season,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final team = Team(
        id: docRef.id,
        organizationId: organizationId,
        name: name,
        description: description,
        headCoachIds: [headCoachId],
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        season: season,
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

  // Get team stream
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

  // Get all teams in an organization
  Stream<List<Team>> getOrganizationTeams(String organizationId) {
    print('=== DEBUG TeamService: METHOD CALLED ===');
    print('DEBUG TeamService: Querying teams for org: $organizationId');
    print('DEBUG TeamService: Collection: $_collection');
    return _firestore
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .where('isActive', isEqualTo: true)
        //.orderBy('name')
        .snapshots()
        .map((snapshot) {
          print('DEBUG TeamService: Found ${snapshot.docs.length} teams');
          for (var doc in snapshot.docs) {
            print('DEBUG TeamService: Team data: ${doc.data()}');
          }
          return snapshot.docs.map((doc) => Team.fromMap(doc.data())).toList();
        });
  }

  // Get teams where user is head coach
  Stream<List<Team>> getTeamsByHeadCoach(String userId) {
    return _firestore
        .collection(_collection)
        .where('headCoachIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Team.fromMap(doc.data())).toList();
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

  // Add head coach
  Future<void> addHeadCoach(String teamId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(teamId).update({
        'headCoachIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw 'Error adding head coach: $e';
    }
  }

  // Remove head coach
  Future<void> removeHeadCoach(String teamId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(teamId).update({
        'headCoachIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw 'Error removing head coach: $e';
    }
  }

  // Deactivate team (soft delete)
  Future<void> deactivateTeam(String teamId) async {
    try {
      await _firestore.collection(_collection).doc(teamId).update({
        'isActive': false,
      });
    } catch (e) {
      throw 'Error deactivating team: $e';
    }
  }

  // Delete team (hard delete)
  Future<void> deleteTeam(String teamId) async {
    try {
      await _firestore.collection(_collection).doc(teamId).delete();
    } catch (e) {
      throw 'Error deleting team: $e';
    }
  }
}
