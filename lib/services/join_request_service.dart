import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/join_request.dart';
import '../models/membership.dart';

class JoinRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'join_requests';

  // Create join request
  Future<JoinRequest> createJoinRequest({
    required String userId,
    required String userName,
    required String userEmail,
    required String organizationId,
    String? teamId,
    required MembershipRole requestedRole,
    String? message,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();

      final request = JoinRequest(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        organizationId: organizationId,
        teamId: teamId,
        requestedRole: requestedRole,
        message: message,
        requestedAt: DateTime.now(),
      );

      await docRef.set(request.toMap());
      return request;
    } catch (e) {
      throw 'Error creating join request: $e';
    }
  }

  // Get pending requests for organization
  Stream<List<JoinRequest>> getPendingRequests(String orgId) {
    return _firestore
        .collection(_collection)
        .where('organizationId', isEqualTo: orgId)
        .where('isPending', isEqualTo: true)
        // .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JoinRequest.fromMap(doc.data()))
              .toList();
        });
  }

  // Get user's pending requests
  Stream<List<JoinRequest>> getUserRequests(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        // .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JoinRequest.fromMap(doc.data()))
              .toList();
        });
  }

  // Approve request
  Future<void> approveRequest(String requestId, String reviewerId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'isPending': false,
        'isApproved': true,
        'reviewedBy': reviewerId,
        'reviewedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Error approving request: $e';
    }
  }

  // Reject request
  Future<void> rejectRequest(
    String requestId,
    String reviewerId,
    String? reason,
  ) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'isPending': false,
        'isApproved': false,
        'reviewedBy': reviewerId,
        'reviewedAt': DateTime.now().toIso8601String(),
        'rejectionReason': reason,
      });
    } catch (e) {
      throw 'Error rejecting request: $e';
    }
  }

  // Delete request
  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).delete();
    } catch (e) {
      throw 'Error deleting request: $e';
    }
  }
}
