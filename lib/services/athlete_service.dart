import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/athlete.dart';

class AthleteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'athletes';

  Stream<List<Athlete>> getAthletes() {
    return _firestore.collection(_collection).orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Athlete.fromMap(doc.data())).toList();
    });
  }

  Future<Athlete?> getAthlete(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get();
      if (doc.exists) {
        return Athlete.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error getting athlete: $e';
    }
  }

  Future<void> addAthlete(Athlete athlete) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(athlete.id)
          .set(athlete.toMap());
    } catch (e) {
      throw 'Error adding athlete: $e';
    }
  }

  Future<void> updateAthlete(Athlete athlete) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(athlete.id)
          .update(athlete.toMap());
    } catch (e) {
      throw 'Error updating athlete: $e';
    }
  }

  Future<void> deleteAthlete(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw 'Error deleting athlete: $e';
    }
  }

  Future<void> addErgScore(String athleteId, ErgScore score) async {
    try {
      Athlete? athlete = await getAthlete(athleteId);
      if (athlete != null) {
        List<ErgScore> scores = List.from(athlete.ergScores);
        scores.add(score);
        await updateAthlete(athlete.copyWith(ergScores: scores));
      }
    } catch (e) {
      throw 'Error adding erg score: $e';
    }
  }

  Stream<List<Athlete>> getAthletesByRole(String role) {
    return _firestore
        .collection(_collection)
        .where('role', isEqualTo: role)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Athlete.fromMap(doc.data()))
              .toList();
        });
  }

  // Get athletes by team ID
  Stream<List<Athlete>> getAthletesByTeam(String teamId) {
    return _firestore
        .collection(_collection)
        .where('teamId', isEqualTo: teamId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Athlete.fromMap(doc.data()))
              .toList();
        });
  }

  // Get current user's athlete profile
  Future<Athlete?> getCurrentUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(userId)
          .get();
      if (doc.exists) {
        return Athlete.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error getting user profile: $e';
    }
  }

  // Get athlete by email (for linking during registration)
  Future<Athlete?> getAthleteByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Athlete.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting athlete by email: $e');
      return null;
    }
  }
}
