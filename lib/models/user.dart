class AppUser {
  final String id; // Firebase Auth UID
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final DateTime createdAt;

  // Personal attributes
  final String? gender;
  final DateTime? dateOfBirth;
  final double? height; // inches
  final double? weight; // lbs
  final double? wingspan; // inches

  // Medical/emergency
  final bool hasInjury;
  final String? injuryDetails;
  final String? emergencyContact;
  final String? emergencyPhone;

  // Multi-org support - remembers last selection
  final String? currentOrganizationId;
  final String? currentMembershipId;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    required this.createdAt,
    this.gender,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.wingspan,
    this.hasInjury = false,
    this.injuryDetails,
    this.emergencyContact,
    this.emergencyPhone,
    this.currentOrganizationId,
    this.currentMembershipId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'height': height,
      'weight': weight,
      'wingspan': wingspan,
      'hasInjury': hasInjury,
      'injuryDetails': injuryDetails,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'currentOrganizationId': currentOrganizationId,
      'currentMembershipId': currentMembershipId,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      wingspan: map['wingspan']?.toDouble(),
      hasInjury: map['hasInjury'] ?? false,
      injuryDetails: map['injuryDetails'],
      emergencyContact: map['emergencyContact'],
      emergencyPhone: map['emergencyPhone'],
      currentOrganizationId: map['currentOrganizationId'],
      currentMembershipId: map['currentMembershipId'],
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    DateTime? createdAt,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    double? wingspan,
    bool? hasInjury,
    String? injuryDetails,
    String? emergencyContact,
    String? emergencyPhone,
    String? currentOrganizationId,
    String? currentMembershipId,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      wingspan: wingspan ?? this.wingspan,
      hasInjury: hasInjury ?? this.hasInjury,
      injuryDetails: injuryDetails ?? this.injuryDetails,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      currentOrganizationId:
          currentOrganizationId ?? this.currentOrganizationId,
      currentMembershipId: currentMembershipId ?? this.currentMembershipId,
    );
  }
}
