import 'workout_template.dart';

enum SessionStatus { scheduled, active, completed }

// ════════════════════════════════════════════════════════════
// LINEUP MODELS
// ════════════════════════════════════════════════════════════

/// A single athlete assigned to a specific seat in a boat.
/// Seat 1 = bow, seat N = stroke.
class SeatAssignment {
  final int seat;
  final String userId;

  SeatAssignment({required this.seat, required this.userId});

  Map<String, dynamic> toMap() => {'seat': seat, 'userId': userId};

  factory SeatAssignment.fromMap(Map<String, dynamic> map) =>
      SeatAssignment(seat: map['seat'] ?? 0, userId: map['userId'] ?? '');

  SeatAssignment copyWith({int? seat, String? userId}) =>
      SeatAssignment(seat: seat ?? this.seat, userId: userId ?? this.userId);
}

/// Tracks how many oars from a specific oar set are allocated to a boat.
/// Allows splitting a set of 8 across two fours, etc.
class OarAllocation {
  final String oarSetId; // FK to equipment doc
  final String oarSetName; // snapshot of display name
  final int totalInSet; // total oars in this set (for reference)
  final int quantityUsed; // how many this boat is using

  OarAllocation({
    required this.oarSetId,
    required this.oarSetName,
    required this.totalInSet,
    required this.quantityUsed,
  });

  Map<String, dynamic> toMap() => {
    'oarSetId': oarSetId,
    'oarSetName': oarSetName,
    'totalInSet': totalInSet,
    'quantityUsed': quantityUsed,
  };

  factory OarAllocation.fromMap(Map<String, dynamic> map) => OarAllocation(
    oarSetId: map['oarSetId'] ?? '',
    oarSetName: map['oarSetName'] ?? '',
    totalInSet: map['totalInSet'] ?? 0,
    quantityUsed: map['quantityUsed'] ?? 0,
  );

  OarAllocation copyWith({
    String? oarSetId,
    String? oarSetName,
    int? totalInSet,
    int? quantityUsed,
  }) => OarAllocation(
    oarSetId: oarSetId ?? this.oarSetId,
    oarSetName: oarSetName ?? this.oarSetName,
    totalInSet: totalInSet ?? this.totalInSet,
    quantityUsed: quantityUsed ?? this.quantityUsed,
  );
}

/// A single boat's lineup: shell, oars, cox, and athletes.
class BoatLineup {
  final String boatName; // display name (shell name or "Boat A")
  final String boatClass; // '8+', '4+', '4-', '4x', '2-', '2x', '1x', etc.
  final String shellId; // FK to equipment (shell) — REQUIRED
  final List<OarAllocation> oarAllocations; // which oar sets + quantity
  final List<SeatAssignment> seats; // ordered bow (1) to stroke (N)
  final String? coxswainId; // null for coxless boats

  BoatLineup({
    required this.boatName,
    required this.boatClass,
    required this.shellId,
    this.oarAllocations = const [],
    required this.seats,
    this.coxswainId,
  });

  Map<String, dynamic> toMap() => {
    'boatName': boatName,
    'boatClass': boatClass,
    'shellId': shellId,
    'oarAllocations': oarAllocations.map((o) => o.toMap()).toList(),
    'seats': seats.map((s) => s.toMap()).toList(),
    if (coxswainId != null) 'coxswainId': coxswainId,
  };

  factory BoatLineup.fromMap(Map<String, dynamic> map) => BoatLineup(
    boatName: map['boatName'] ?? '',
    boatClass: map['boatClass'] ?? '',
    shellId: map['shellId'] ?? '',
    oarAllocations: (map['oarAllocations'] as List? ?? [])
        .map((o) => OarAllocation.fromMap(o))
        .toList(),
    seats: (map['seats'] as List? ?? [])
        .map((s) => SeatAssignment.fromMap(s))
        .toList(),
    coxswainId: map['coxswainId'],
  );

  BoatLineup copyWith({
    String? boatName,
    String? boatClass,
    String? shellId,
    List<OarAllocation>? oarAllocations,
    List<SeatAssignment>? seats,
    String? coxswainId,
  }) => BoatLineup(
    boatName: boatName ?? this.boatName,
    boatClass: boatClass ?? this.boatClass,
    shellId: shellId ?? this.shellId,
    oarAllocations: oarAllocations ?? this.oarAllocations,
    seats: seats ?? this.seats,
    coxswainId: coxswainId ?? this.coxswainId,
  );
}

/// Lineup for a specific piece (or all pieces if pieceNumber == 0).
class PieceLineup {
  final int pieceNumber; // 0 = applies to all pieces
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

  PieceLineup copyWith({int? pieceNumber, List<BoatLineup>? boats}) =>
      PieceLineup(
        pieceNumber: pieceNumber ?? this.pieceNumber,
        boats: boats ?? this.boats,
      );
}

// ════════════════════════════════════════════════════════════
// SEAT RACE MODELS
// ════════════════════════════════════════════════════════════

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

/// Seat race metadata — lineups themselves live on session.lineups.
class SeatRaceConfig {
  final SeatRaceFormat format;
  final List<String> athletePool;
  final List<String>? portAthletes;
  final List<String>? starboardAthletes;
  final SeatRaceStandardization? standardization;

  SeatRaceConfig({
    required this.format,
    required this.athletePool,
    this.portAthletes,
    this.starboardAthletes,
    this.standardization,
  });

  Map<String, dynamic> toMap() => {
    'format': format.name,
    'athletePool': athletePool,
    if (portAthletes != null) 'portAthletes': portAthletes,
    if (starboardAthletes != null) 'starboardAthletes': starboardAthletes,
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
    standardization: map['standardization'] != null
        ? SeatRaceStandardization.fromMap(map['standardization'])
        : null,
  );
}

// ════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ════════════════════════════════════════════════════════════

/// Number of rowing seats (not counting cox) for a given boat class.
int seatsForBoatClass(String boatClass) {
  switch (boatClass) {
    case '8+':
      return 8;
    case '4+':
    case '4-':
    case '4x':
    case '4x+':
      return 4;
    case '2-':
    case '2+':
    case '2x':
      return 2;
    case '1x':
      return 1;
    default:
      return 0;
  }
}

/// Whether a boat class includes a coxswain.
bool boatClassHasCox(String boatClass) {
  return boatClass.contains('+');
}

/// Whether a boat class is sculling (each rower uses 2 oars).
bool boatClassIsScull(String boatClass) {
  return boatClass.contains('x');
}

/// Number of oars needed for a boat class.
int oarsForBoatClass(String boatClass) {
  final seats = seatsForBoatClass(boatClass);
  return boatClassIsScull(boatClass) ? seats * 2 : seats;
}

/// Standard boat classes for display.
const List<String> standardBoatClasses = [
  '8+',
  '4+',
  '4-',
  '4x',
  '4x+',
  '2-',
  '2x',
  '1x',
];

// ════════════════════════════════════════════════════════════
// WORKOUT SESSION
// ════════════════════════════════════════════════════════════

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

  // ── Lineups ──
  // For regular workouts: single PieceLineup with pieceNumber 0
  // For seat races: one PieceLineup per piece (allowing swaps)
  final List<PieceLineup>? lineups;

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
    this.lineups,
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
      if (lineups != null) 'lineups': lineups!.map((l) => l.toMap()).toList(),
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
      lineups: map['lineups'] != null
          ? (map['lineups'] as List).map((l) => PieceLineup.fromMap(l)).toList()
          : null,
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
    List<PieceLineup>? lineups,
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
      lineups: lineups ?? this.lineups,
      isSeatRace: isSeatRace ?? this.isSeatRace,
      seatRaceConfig: seatRaceConfig ?? this.seatRaceConfig,
    );
  }
}
