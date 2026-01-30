import 'package:flutter/material.dart';

class Team {
  final String id;
  final String name;
  final String coachId;
  final List<String> coachIds;
  final int primaryColor; // Stored as int, converted to/from Color
  final int secondaryColor;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.coachId,
    this.coachIds = const [],
    this.primaryColor = 0xFF1976D2, // Default calm blue
    this.secondaryColor = 0xFFFFFFFF, // Default white
    required this.createdAt,
  });

  // Get Color objects from int values
  Color get primaryColorObj => Color(primaryColor);
  Color get secondaryColorObj => Color(secondaryColor);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coachId': coachId,
      'coachIds': coachIds,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      coachId: map['coachId'] ?? '',
      coachIds: List<String>.from(map['coachIds'] ?? []),
      primaryColor: map['primaryColor'] ?? 0xFF1976D2,
      secondaryColor: map['secondaryColor'] ?? 0xFFFFFFFF,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Team copyWith({
    String? id,
    String? name,
    String? coachId,
    List<String>? coachIds,
    int? primaryColor,
    int? secondaryColor,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      coachId: coachId ?? this.coachId,
      coachIds: coachIds ?? this.coachIds,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
