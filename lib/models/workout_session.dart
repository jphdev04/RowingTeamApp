import 'workout_template.dart';

enum SessionStatus { scheduled, active, completed }

// ── Seat race sub-models ──────────────────────────────────────

class SeatAssignment {
  final int seat; // 1 = bow, N = stroke
  final String userId;

  SeatAssignment({required this.seat, required this.userId});

  Map<String, dynamic> toMap() => {'seat': seat, 'userId': userId};

  factory SeatAssignment.fromMap(Map<String, dynamic> map) =>
      SeatAssignment(seat: map['seat'] ?? 0, userId: map['userId'] ?? '');
}

class BoatLineup {
  final String boatName;
  final String boatClass; // '8+', '4+', '2-', '1x', etc.
  final List<SeatAssignment> seats; // ordered bow to stroke
  final String? coxswainId; // null for coxless boats

  BoatLineup({
    required this.boatName,
    required this.boatClass,
    required this.seats,
    this.coxswainId,
  });

  Map<String, dynamic> toMap() => {
    'boatName': boatName,
    'boatClass': boatClass,
    'seats': seats.map((s) => s.toMap()).toList(),
    if (coxswainId != null) 'coxswainId': coxswainId,
  };

  factory BoatLineup.fromMap(Map<String, dynamic> map) => BoatLineup(
    boatName: map['boatName'] ?? '',
    boatClass: map['boatClass'] ?? '',
    seats: (map['seats'] as List? ?? [])
        .map((s) => SeatAssignment.fromMap(s))
        .toList(),
    coxswainId: map['coxswainId'],
  );
}

class PieceLineup {
  final int pieceNumber;
  final List<BoatLineup> boats;

  PieceLineup({required this.pieceNumber, required this.boats});

  Map<String, dynamic> toMap() => {
    'pieceNumber': pieceNumber,
    'boats': boats.map((b) => b.toMap()).toList(),
  };

  factory PieceLineup.fromMap(Map<String, dynamic> map) => PieceLineup(
    pieceNumber: map['pieceNumber'] ?? 0,
    boats: (map['boats'] as List? ?? [])
        .map((b) => BoatLineup.fromMap(b))
        .toList(),
  );
}

class SeatRaceStandardization {
  final bool dropWorstPiece;
  final int dropCount;
  final String? customRules;

  SeatRaceStandardization({
    this.dropWorstPiece = false,
    this.dropCount = 1,
    this.customRules,
  });

  Map<String, dynamic> toMap() => {
    'dropWorstPiece': dropWorstPiece,
    'dropCount': dropCount,
    if (customRules != null) 'customRules': customRules,
  };

  factory SeatRaceStandardization.fromMap(Map<String, dynamic> map) =>
      SeatRaceStandardization(
        dropWorstPiece: map['dropWorstPiece'] ?? false,
        dropCount: map['dropCount'] ?? 1,
        customRules: map['customRules'],
      );
}

class SeatRaceConfig {
  final SeatRaceFormat format;
  final List<String> athletePool; // all participating athlete userIds
  final List<String>? portAthletes; // matrix: port-side athletes
  final List<String>? starboardAthletes; // matrix: starboard athletes
  final String? boatClass; // boat class for the seat race
  final List<PieceLineup> pieceLineups; // lineup per piece
  final SeatRaceStandardization? standardization;

  SeatRaceConfig({
    required this.format,
    required this.athletePool,
    this.portAthletes,
    this.starboardAthletes,
    this.boatClass,
    required this.pieceLineups,
    this.standardization,
  });

  Map<String, dynamic> toMap() => {
    'format': format.name,
    'athletePool': athletePool,
    if (portAthletes != null) 'portAthletes': portAthletes,
    if (starboardAthletes != null) 'starboardAthletes': starboardAthletes,
    if (boatClass != null) 'boatClass': boatClass,
    'pieceLineups': pieceLineups.map((p) => p.toMap()).toList(),
    if (standardization != null) 'standardization': standardization!.toMap(),
  };

  factory SeatRaceConfig.fromMap(Map<String, dynamic> map) => SeatRaceConfig(
    format: SeatRaceFormat.values.firstWhere(
      (e) => e.name == map['format'],
      orElse: () => SeatRaceFormat.directSwap,
    ),
    athletePool: List<String>.from(map['athletePool'] ?? []),
    portAthletes: map['portAthletes'] != null
        ? List<String>.from(map['portAthletes'])
        : null,
    starboardAthletes: map['starboardAthletes'] != null
        ? List<String>.from(map['starboardAthletes'])
        : null,
    boatClass: map['boatClass'],
    pieceLineups: (map['pieceLineups'] as List? ?? [])
        .map((p) => PieceLineup.fromMap(p))
        .toList(),
    standardization: map['standardization'] != null
        ? SeatRaceStandardization.fromMap(map['standardization'])
        : null,
  );
}

// ── WorkoutSession ────────────────────────────────────────────

class WorkoutSession {
  final String id;
  final String organizationId;
  final String? teamId;
  final String? templateId;
  final String? calendarEventId;
  final String createdBy;
  final DateTime createdAt;

  // Identity
  final String name;
  final WorkoutCategory category;
  final DateTime scheduledDate;

  // Frozen spec — snapshot of template fields at creation
  final Map<String, dynamic> workoutSpec;

  // Visibility & permissions
  final bool hideUntilStart;
  final bool athletesCanSeeResults;
  final SessionStatus status;

  // Seat racing
  final bool isSeatRace;
  final SeatRaceConfig? seatRaceConfig;

  WorkoutSession({
    required this.id,
    required this.organizationId,
    this.teamId,
    this.templateId,
    this.calendarEventId,
    required this.createdBy,
    required this.createdAt,
    required this.name,
    required this.category,
    required this.scheduledDate,
    required this.workoutSpec,
    this.hideUntilStart = false,
    this.athletesCanSeeResults = true,
    this.status = SessionStatus.scheduled,
    this.isSeatRace = false,
    this.seatRaceConfig,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'teamId': teamId,
      'templateId': templateId,
      'calendarEventId': calendarEventId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'name': name,
      'category': category.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'workoutSpec': workoutSpec,
      'hideUntilStart': hideUntilStart,
      'athletesCanSeeResults': athletesCanSeeResults,
      'status': status.name,
      'isSeatRace': isSeatRace,
      if (seatRaceConfig != null) 'seatRaceConfig': seatRaceConfig!.toMap(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] ?? '',
      organizationId: map['organizationId'] ?? '',
      teamId: map['teamId'],
      templateId: map['templateId'],
      calendarEventId: map['calendarEventId'],
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      name: map['name'] ?? '',
      category: WorkoutCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => WorkoutCategory.erg,
      ),
      scheduledDate: DateTime.parse(map['scheduledDate']),
      workoutSpec: Map<String, dynamic>.from(map['workoutSpec'] ?? {}),
      hideUntilStart: map['hideUntilStart'] ?? false,
      athletesCanSeeResults: map['athletesCanSeeResults'] ?? true,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      isSeatRace: map['isSeatRace'] ?? false,
      seatRaceConfig: map['seatRaceConfig'] != null
          ? SeatRaceConfig.fromMap(map['seatRaceConfig'])
          : null,
    );
  }

  WorkoutSession copyWith({
    String? id,
    String? organizationId,
    String? teamId,
    String? templateId,
    String? calendarEventId,
    String? createdBy,
    DateTime? createdAt,
    String? name,
    WorkoutCategory? category,
    DateTime? scheduledDate,
    Map<String, dynamic>? workoutSpec,
    bool? hideUntilStart,
    bool? athletesCanSeeResults,
    SessionStatus? status,
    bool? isSeatRace,
    SeatRaceConfig? seatRaceConfig,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      teamId: teamId ?? this.teamId,
      templateId: templateId ?? this.templateId,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      category: category ?? this.category,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      workoutSpec: workoutSpec ?? this.workoutSpec,
      hideUntilStart: hideUntilStart ?? this.hideUntilStart,
      athletesCanSeeResults:
          athletesCanSeeResults ?? this.athletesCanSeeResults,
      status: status ?? this.status,
      isSeatRace: isSeatRace ?? this.isSeatRace,
      seatRaceConfig: seatRaceConfig ?? this.seatRaceConfig,
    );
  }
}
