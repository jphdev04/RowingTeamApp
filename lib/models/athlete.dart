class Athlete {
  final String id;
  final String name;
  final String email;
  final String role; // 'coach', 'coxswain', or 'rower'
  final String? gender; // 'male' or 'female'
  final String? teamId;
  final String? side; // 'port', 'starboard', or 'both' (only for rowers)
  final String?
  weightClass; // 'lightweight', 'heavyweight', 'openweight' (only for rowers)
  final double? height; // in inches (not for coxswains)
  final double? weight; // in pounds (not for coxswains)
  final double? wingspan; // in inches (not for coxswains)
  final bool isInjured; // injury status flag
  final String? injuryDetails; // details about the injury
  final List<ErgScore> ergScores; // not for coxswains
  final DateTime createdAt;

  Athlete({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.teamId,
    this.gender,
    this.side,
    this.weightClass,
    this.height,
    this.weight,
    this.wingspan,
    this.isInjured = false,
    this.injuryDetails,
    this.ergScores = const [],
    required this.createdAt,
  });

  // Convert Athlete to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'gender': gender,
      'teamId': teamId,
      'side': side,
      'weightClass': weightClass,
      'height': height,
      'weight': weight,
      'wingspan': wingspan,
      'isInjured': isInjured,
      'injuryDetails': injuryDetails,
      'ergScores': ergScores.map((score) => score.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Athlete from Map (from Firestore)
  factory Athlete.fromMap(Map<String, dynamic> map) {
    return Athlete(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'rower',
      gender: map['gender'],
      teamId: map['teamId'],
      side: map['side'],
      weightClass: map['weightClass'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      wingspan: map['wingspan']?.toDouble(),
      isInjured: map['isInjured'] ?? false,
      injuryDetails: map['injuryDetails'],
      ergScores:
          (map['ergScores'] as List<dynamic>?)
              ?.map((score) => ErgScore.fromMap(score))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Create a copy with some fields updated
  Athlete copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? gender,
    String? teamId,
    String? side,
    String? weightClass,
    double? height,
    double? weight,
    double? wingspan,
    bool? isInjured,
    String? injuryDetails,
    List<ErgScore>? ergScores,
    DateTime? createdAt,
  }) {
    return Athlete(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      gender: gender ?? this.gender,
      side: side ?? this.side,
      weightClass: weightClass ?? this.weightClass,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      wingspan: wingspan ?? this.wingspan,
      isInjured: isInjured ?? this.isInjured,
      injuryDetails: injuryDetails ?? this.injuryDetails,
      ergScores: ergScores ?? this.ergScores,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get weight class options based on gender
  static List<String> getWeightClassOptions(String? gender) {
    if (gender == 'male') {
      return ['Lightweight', 'Heavyweight'];
    } else if (gender == 'female') {
      return ['Lightweight', 'Openweight'];
    }
    return [];
  }
}

class ErgScore {
  final String testType; // '2k', '6k', '500m sprint', etc.
  final int timeInSeconds;
  final DateTime date;
  final bool isPersonal; // true if athlete logged it themselves

  ErgScore({
    required this.testType,
    required this.timeInSeconds,
    required this.date,
    this.isPersonal = false,
  });

  // Format time as MM:SS.T
  String get formattedTime {
    int minutes = timeInSeconds ~/ 60;
    double seconds = (timeInSeconds % 60).toDouble();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toStringAsFixed(1).padLeft(4, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'testType': testType,
      'timeInSeconds': timeInSeconds,
      'date': date.toIso8601String(),
      'isPersonal': isPersonal,
    };
  }

  factory ErgScore.fromMap(Map<String, dynamic> map) {
    return ErgScore(
      testType: map['testType'] ?? '',
      timeInSeconds: map['timeInSeconds'] ?? 0,
      date: DateTime.parse(map['date']),
      isPersonal: map['isPersonal'] ?? false,
    );
  }
}
