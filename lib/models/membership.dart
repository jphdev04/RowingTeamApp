enum MembershipRole { admin, coach, boatman, rower, coxswain, athlete }

class PermissionPresets {
  static const Map<MembershipRole, List<String>> defaults = {
    MembershipRole.admin: [
      'manage_organization',
      'manage_teams',
      'manage_members',
      'manage_equipment',
      'view_all_data',
      'create_lineups',
      'assign_workouts',
      'view_analytics',
    ],
    MembershipRole.coach: [
      'manage_team_roster',
      'manage_equipment',
      'create_lineups',
      'assign_workouts',
      'view_team_analytics',
      'log_team_workouts',
    ],
    MembershipRole.boatman: [
      'manage_equipment',
      'view_equipment',
      'resolve_damage_reports',
    ],
    MembershipRole.rower: [
      'view_team_roster',
      'view_lineups',
      'view_workouts',
      'log_personal_workouts',
      'report_equipment_damage',
      'view_schedule',
    ],
    MembershipRole.coxswain: [
      'view_team_roster',
      'view_lineups',
      'view_workouts',
      'log_team_workouts',
      'report_equipment_damage',
      'view_schedule',
    ],
    MembershipRole.athlete: [
      'view_equipment',
      'log_personal_workouts',
      'report_equipment_damage',
    ],
  };

  static List<String> getDefaults(MembershipRole role) {
    return List<String>.from(defaults[role] ?? []);
  }
}

class Membership {
  final String id;
  final String userId;
  final String organizationId;
  final String? teamId;
  final MembershipRole role;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;

  // Permissions
  final List<String> permissions;
  final bool useDefaultPermissions;

  // Role-specific rowing attributes
  final String? side; // port/starboard/both
  final String? weightClass; // lightweight/heavyweight/openweight
  final String? coachingLevel; // head/assistant/volunteer

  // Display preferences
  final String? customTitle;
  final int? displayOrder;

  Membership({
    required this.id,
    required this.userId,
    required this.organizationId,
    this.teamId,
    required this.role,
    this.isActive = true,
    required this.startDate,
    this.endDate,
    List<String>? permissions,
    this.useDefaultPermissions = true,
    this.side,
    this.weightClass,
    this.coachingLevel,
    this.customTitle,
    this.displayOrder,
  }) : permissions = permissions ?? PermissionPresets.getDefaults(role);

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  String get displayName {
    if (customTitle != null) return customTitle!;

    String roleStr = role.name[0].toUpperCase() + role.name.substring(1);
    if (teamId != null) {
      return roleStr; // Will be combined with team name in UI
    }
    return roleStr;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'organizationId': organizationId,
      'teamId': teamId,
      'role': role.name,
      'isActive': isActive,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'permissions': permissions,
      'useDefaultPermissions': useDefaultPermissions,
      'side': side,
      'weightClass': weightClass,
      'coachingLevel': coachingLevel,
      'customTitle': customTitle,
      'displayOrder': displayOrder,
    };
  }

  factory Membership.fromMap(Map<String, dynamic> map) {
    return Membership(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      organizationId: map['organizationId'] ?? '',
      teamId: map['teamId'],
      role: MembershipRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MembershipRole.athlete,
      ),
      isActive: map['isActive'] ?? true,
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      permissions: List<String>.from(map['permissions'] ?? []),
      useDefaultPermissions: map['useDefaultPermissions'] ?? true,
      side: map['side'],
      weightClass: map['weightClass'],
      coachingLevel: map['coachingLevel'],
      customTitle: map['customTitle'],
      displayOrder: map['displayOrder'],
    );
  }

  Membership copyWith({
    String? id,
    String? userId,
    String? organizationId,
    String? teamId,
    MembershipRole? role,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? permissions,
    bool? useDefaultPermissions,
    String? side,
    String? weightClass,
    String? coachingLevel,
    String? customTitle,
    int? displayOrder,
  }) {
    return Membership(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      permissions: permissions ?? this.permissions,
      useDefaultPermissions:
          useDefaultPermissions ?? this.useDefaultPermissions,
      side: side ?? this.side,
      weightClass: weightClass ?? this.weightClass,
      coachingLevel: coachingLevel ?? this.coachingLevel,
      customTitle: customTitle ?? this.customTitle,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
