class Organization {
  final String id;
  final String name;
  final String? address;
  final String? website;
  final String? logoUrl;
  final List<String> adminIds;
  final DateTime createdAt;

  // Join system
  final String joinCode;
  final bool isPublic;
  final bool requiresApproval;

  Organization({
    required this.id,
    required this.name,
    this.address,
    this.website,
    this.logoUrl,
    this.adminIds = const [],
    required this.createdAt,
    required this.joinCode,
    this.isPublic = false,
    this.requiresApproval = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'website': website,
      'logoUrl': logoUrl,
      'adminIds': adminIds,
      'createdAt': createdAt.toIso8601String(),
      'joinCode': joinCode,
      'isPublic': isPublic,
      'requiresApproval': requiresApproval,
    };
  }

  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'],
      website: map['website'],
      logoUrl: map['logoUrl'],
      adminIds: List<String>.from(map['adminIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      joinCode: map['joinCode'] ?? '',
      isPublic: map['isPublic'] ?? false,
      requiresApproval: map['requiresApproval'] ?? true,
    );
  }

  Organization copyWith({
    String? id,
    String? name,
    String? address,
    String? website,
    String? logoUrl,
    List<String>? adminIds,
    DateTime? createdAt,
    String? joinCode,
    bool? isPublic,
    bool? requiresApproval,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      adminIds: adminIds ?? this.adminIds,
      createdAt: createdAt ?? this.createdAt,
      joinCode: joinCode ?? this.joinCode,
      isPublic: isPublic ?? this.isPublic,
      requiresApproval: requiresApproval ?? this.requiresApproval,
    );
  }
}
