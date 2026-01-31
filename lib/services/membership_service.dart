import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/membership.dart';

class MembershipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'memberships';

  // Create membership
  Future<Membership> createMembership({
    required String userId,
    required String organizationId,
    String? teamId,
    required MembershipRole role,
    List<String>? customPermissions,
    String? side,
    String? weightClass,
    String? coachingLevel,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();

      final membership = Membership(
        id: docRef.id,
        userId: userId,
        organizationId: organizationId,
        teamId: teamId,
        role: role,
        startDate: DateTime.now(),
        permissions: customPermissions,
        side: side,
        weightClass: weightClass,
        coachingLevel: coachingLevel,
      );

      await docRef.set(membership.toMap());
      return membership;
    } catch (e) {
      throw 'Error creating membership: $e';
    }
  }

  // Get membership by ID
  Future<Membership?> getMembership(String membershipId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(membershipId)
          .get();
      if (doc.exists) {
        return Membership.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error getting membership: $e';
    }
  }

  // Get all active memberships for a user
  Stream<List<Membership>> getUserMemberships(String userId) {
    print('DEBUG: Querying memberships for user: $userId');
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        // .orderBy('displayOrder')  // Comment this out for now
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Found ${snapshot.docs.length} memberships');
          return snapshot.docs
              .map((doc) => Membership.fromMap(doc.data()))
              .toList();
        });
  }

  // Get all memberships for an organization
  Stream<List<Membership>> getOrganizationMemberships(String orgId) {
    return _firestore
        .collection(_collection)
        .where('organizationId', isEqualTo: orgId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Membership.fromMap(doc.data()))
              .toList();
        });
  }

  // Get all memberships for a team
  Stream<List<Membership>> getTeamMemberships(String teamId) {
    return _firestore
        .collection(_collection)
        .where('teamId', isEqualTo: teamId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Membership.fromMap(doc.data()))
              .toList();
        });
  }

  // Get memberships by role
  Stream<List<Membership>> getMembershipsByRole(
    String orgId,
    MembershipRole role,
  ) {
    return _firestore
        .collection(_collection)
        .where('organizationId', isEqualTo: orgId)
        .where('role', isEqualTo: role.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Membership.fromMap(doc.data()))
              .toList();
        });
  }

  // Update membership
  Future<void> updateMembership(Membership membership) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(membership.id)
          .update(membership.toMap());
    } catch (e) {
      throw 'Error updating membership: $e';
    }
  }

  // Deactivate membership (soft delete)
  Future<void> deactivateMembership(String membershipId) async {
    try {
      await _firestore.collection(_collection).doc(membershipId).update({
        'isActive': false,
        'endDate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Error deactivating membership: $e';
    }
  }

  // Delete membership (hard delete)
  Future<void> deleteMembership(String membershipId) async {
    try {
      await _firestore.collection(_collection).doc(membershipId).delete();
    } catch (e) {
      throw 'Error deleting membership: $e';
    }
  }

  // Update permissions
  Future<void> updatePermissions(
    String membershipId,
    List<String> permissions, {
    bool useDefaults = false,
  }) async {
    try {
      await _firestore.collection(_collection).doc(membershipId).update({
        'permissions': permissions,
        'useDefaultPermissions': useDefaults,
      });
    } catch (e) {
      throw 'Error updating permissions: $e';
    }
  }
}
