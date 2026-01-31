import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Get user by ID
  Future<AppUser?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(userId)
          .get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error getting user: $e';
    }
  }

  // Get user stream (real-time)
  Stream<AppUser?> getUserStream(String userId) {
    return _firestore.collection(_collection).doc(userId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Create user
  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(user.toMap());
    } catch (e) {
      throw 'Error creating user: $e';
    }
  }

  // Update user
  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.id)
          .update(user.toMap());
    } catch (e) {
      throw 'Error updating user: $e';
    }
  }

  // Update current organization/membership
  Future<void> updateCurrentContext(
    String userId,
    String? orgId,
    String? membershipId,
  ) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'currentOrganizationId': orgId,
        'currentMembershipId': membershipId,
      });
    } catch (e) {
      throw 'Error updating context: $e';
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw 'Error deleting user: $e';
    }
  }
}
