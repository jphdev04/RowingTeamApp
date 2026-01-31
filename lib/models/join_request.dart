import 'membership.dart';

class JoinRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String organizationId;
  final String? teamId;
  final MembershipRole requestedRole;
  final String? message;
  final DateTime requestedAt;
  final bool isPending;
  final bool isApproved;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  JoinRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.organizationId,
    this.teamId,
    required this.requestedRole,
    this.message,
    required this.requestedAt,
    this.isPending = true,
    this.isApproved = false,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'organizationId': organizationId,
      'teamId': teamId,
      'requestedRole': requestedRole.name,
      'message': message,
      'requestedAt': requestedAt.toIso8601String(),
      'isPending': isPending,
      'isApproved': isApproved,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory JoinRequest.fromMap(Map<String, dynamic> map) {
    return JoinRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      organizationId: map['organizationId'] ?? '',
      teamId: map['teamId'],
      requestedRole: MembershipRole.values.firstWhere(
        (e) => e.name == map['requestedRole'],
        orElse: () => MembershipRole.athlete,
      ),
      message: map['message'],
      requestedAt: DateTime.parse(map['requestedAt']),
      isPending: map['isPending'] ?? true,
      isApproved: map['isApproved'] ?? false,
      reviewedBy: map['reviewedBy'],
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.parse(map['reviewedAt'])
          : null,
      rejectionReason: map['rejectionReason'],
    );
  }

  JoinRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? organizationId,
    String? teamId,
    MembershipRole? requestedRole,
    String? message,
    DateTime? requestedAt,
    bool? isPending,
    bool? isApproved,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      organizationId: organizationId ?? this.organizationId,
      teamId: teamId ?? this.teamId,
      requestedRole: requestedRole ?? this.requestedRole,
      message: message ?? this.message,
      requestedAt: requestedAt ?? this.requestedAt,
      isPending: isPending ?? this.isPending,
      isApproved: isApproved ?? this.isApproved,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
