class Team {
  final String id;
  final String name;
  final String coachId; // The coach who created/owns the team
  final List<String> coachIds; // Multiple coaches can manage a team
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.coachId,
    this.coachIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coachId': coachId,
      'coachIds': coachIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      coachId: map['coachId'] ?? '',
      coachIds: List<String>.from(map['coachIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Team copyWith({
    String? id,
    String? name,
    String? coachId,
    List<String>? coachIds,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      coachId: coachId ?? this.coachId,
      coachIds: coachIds ?? this.coachIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
