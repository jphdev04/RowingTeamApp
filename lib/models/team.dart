import 'package:flutter/material.dart';

class Team {
  final String id;
  final String organizationId; // Changed from standalone to org-based
  final String name;
  final String? description;
  final List<String> headCoachIds;
  final int primaryColor;
  final int secondaryColor;
  final String? season;
  final bool isActive;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.headCoachIds = const [],
    this.primaryColor = 0xFF1976D2,
    this.secondaryColor = 0xFFFFFFFF,
    this.season,
    this.isActive = true,
    required this.createdAt,
  });

  Color get primaryColorObj => Color(primaryColor);
  Color get secondaryColorObj => Color(secondaryColor);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'description': description,
      'headCoachIds': headCoachIds,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'season': season,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] ?? '',
      organizationId: map['organizationId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      headCoachIds: List<String>.from(map['headCoachIds'] ?? []),
      primaryColor: map['primaryColor'] ?? 0xFF1976D2,
      secondaryColor: map['secondaryColor'] ?? 0xFFFFFFFF,
      season: map['season'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Team copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? description,
    List<String>? headCoachIds,
    int? primaryColor,
    int? secondaryColor,
    String? season,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      headCoachIds: headCoachIds ?? this.headCoachIds,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      season: season ?? this.season,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
