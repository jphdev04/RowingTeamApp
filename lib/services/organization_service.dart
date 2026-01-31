import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organization.dart';
import 'dart:math';

class OrganizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'organizations';

  // Generate unique join code
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Create organization
  Future<Organization> createOrganization(
    String name,
    String creatorId, {
    String? address,
    String? website,
    bool requiresApproval = true,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final joinCode = _generateJoinCode();

      final org = Organization(
        id: docRef.id,
        name: name,
        address: address,
        website: website,
        adminIds: [creatorId],
        createdAt: DateTime.now(),
        joinCode: joinCode,
        requiresApproval: requiresApproval,
      );

      await docRef.set(org.toMap());
      return org;
    } catch (e) {
      throw 'Error creating organization: $e';
    }
  }

  // Get organization by ID
  Future<Organization?> getOrganization(String orgId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(orgId)
          .get();
      if (doc.exists) {
        return Organization.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error getting organization: $e';
    }
  }

  // Get organization stream
  Stream<Organization?> getOrganizationStream(String orgId) {
    return _firestore.collection(_collection).doc(orgId).snapshots().map((doc) {
      if (doc.exists) {
        return Organization.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Get organization by join code
  Future<Organization?> getOrganizationByJoinCode(String joinCode) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('joinCode', isEqualTo: joinCode.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Organization.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw 'Error finding organization: $e';
    }
  }

  // Get all public organizations
  Stream<List<Organization>> getPublicOrganizations() {
    return _firestore
        .collection(_collection)
        .where('isPublic', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Organization.fromMap(doc.data()))
              .toList();
        });
  }

  // Update organization
  Future<void> updateOrganization(Organization org) async {
    try {
      await _firestore.collection(_collection).doc(org.id).update(org.toMap());
    } catch (e) {
      throw 'Error updating organization: $e';
    }
  }

  // Add admin
  Future<void> addAdmin(String orgId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(orgId).update({
        'adminIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw 'Error adding admin: $e';
    }
  }

  // Remove admin
  Future<void> removeAdmin(String orgId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(orgId).update({
        'adminIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw 'Error removing admin: $e';
    }
  }

  // Delete organization
  Future<void> deleteOrganization(String orgId) async {
    try {
      await _firestore.collection(_collection).doc(orgId).delete();
    } catch (e) {
      throw 'Error deleting organization: $e';
    }
  }
}
