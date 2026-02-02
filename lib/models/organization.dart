import 'package:flutter/material.dart';

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

  final int primaryColor;
  final int secondaryColor;

  Color get primaryColorObj => Color(primaryColor);
  Color get secondaryColorObj => Color(secondaryColor);

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
    this.primaryColor = 0xFF6A1B9A, // Default deep purple
    this.secondaryColor = 0xFFFFFFFF, // Default white
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
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
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
      primaryColor: map['primaryColor'] ?? 0xFF6A1B9A,
      secondaryColor: map['secondaryColor'] ?? 0xFFFFFFFF,
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
    int? primaryColor,
    int? secondaryColor,
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
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }
}
