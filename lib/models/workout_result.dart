import 'workout_template.dart';
import 'workout_session.dart';

// ── Result sub-models ─────────────────────────────────────────

class ErgIntervalResult {
  final int pieceNumber;
  final int distance; // meters
  final int timeMs; // milliseconds
  final int? avgHeartRate;
  final int? splitPer500Ms; // calculated: (timeMs / distance) * 500

  ErgIntervalResult({
    required this.pieceNumber,
    required this.distance,
    required this.timeMs,
    this.avgHeartRate,
    this.splitPer500Ms,
  });

  /// Auto-calculate split if not provided
  int get calculatedSplitPer500Ms {
    if (splitPer500Ms != null) return splitPer500Ms!;
    if (distance <= 0) return 0;
    return ((timeMs / distance) * 500).round();
  }

  Map<String, dynamic> toMap() => {
    'pieceNumber': pieceNumber,
    'distance': distance,
    'timeMs': timeMs,
    if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
    'splitPer500Ms': calculatedSplitPer500Ms,
  };

  factory ErgIntervalResult.fromMap(Map<String, dynamic> map) =>
      ErgIntervalResult(
        pieceNumber: map['pieceNumber'] ?? 0,
        distance: map['distance'] ?? 0,
        timeMs: map['timeMs'] ?? 0,
        avgHeartRate: map['avgHeartRate'],
        splitPer500Ms: map['splitPer500Ms'],
      );
}

class WaterPieceResult {
  final int pieceNumber;
  final int? distance; // meters
  final int? timeMs; // milliseconds
  final String? boatClass;
  final BoatLineup? lineupSnapshot; // who was in the boat for this piece
  final String? notes;

  WaterPieceResult({
    required this.pieceNumber,
    this.distance,
    this.timeMs,
    this.boatClass,
    this.lineupSnapshot,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'pieceNumber': pieceNumber,
    if (distance != null) 'distance': distance,
    if (timeMs != null) 'timeMs': timeMs,
    if (boatClass != null) 'boatClass': boatClass,
    if (lineupSnapshot != null) 'lineupSnapshot': lineupSnapshot!.toMap(),
    if (notes != null) 'notes': notes,
  };

  factory WaterPieceResult.fromMap(Map<String, dynamic> map) =>
      WaterPieceResult(
        pieceNumber: map['pieceNumber'] ?? 0,
        distance: map['distance'],
        timeMs: map['timeMs'],
        boatClass: map['boatClass'],
        lineupSnapshot: map['lineupSnapshot'] != null
            ? BoatLineup.fromMap(map['lineupSnapshot'])
            : null,
        notes: map['notes'],
      );
}

class LiftSetResult {
  final int reps;
  final double? weight;

  LiftSetResult({required this.reps, this.weight});

  Map<String, dynamic> toMap() => {
    'reps': reps,
    if (weight != null) 'weight': weight,
  };

  factory LiftSetResult.fromMap(Map<String, dynamic> map) =>
      LiftSetResult(reps: map['reps'] ?? 0, weight: map['weight']?.toDouble());
}

class LiftExerciseResult {
  final String exerciseName;
  final List<LiftSetResult> sets;

  LiftExerciseResult({required this.exerciseName, required this.sets});

  Map<String, dynamic> toMap() => {
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toMap()).toList(),
  };

  factory LiftExerciseResult.fromMap(Map<String, dynamic> map) =>
      LiftExerciseResult(
        exerciseName: map['exerciseName'] ?? '',
        sets: (map['sets'] as List? ?? [])
            .map((s) => LiftSetResult.fromMap(s))
            .toList(),
      );
}

// ── WorkoutResult ─────────────────────────────────────────────

class WorkoutResult {
  final String id;
  final String? sessionId; // null if personal
  final String organizationId;
  final String? teamId;
  final String userId; // athlete who performed
  final String loggedBy; // who entered data (could be cox)
  final DateTime createdAt;
  final DateTime updatedAt;

  final WorkoutCategory category;

  // Erg
  final List<ErgIntervalResult>? ergIntervals;
  final int? ergTotalDistance;
  final int? ergTotalTimeMs;
  final int? ergAvgSplitPer500Ms;
  final int? ergAvgHeartRate;

  // Water
  final List<WaterPieceResult>? waterPieces;
  final int? waterTotalDistance;
  final int? waterTotalTimeMs;
  final String? waterNotes;
  final String? boatClass;

  // Race
  final int? raceTimeMs;
  final int? racePlacement;
  final List<String>? raceOpponents;
  final int? raceMarginMs;

  // Lift
  final List<LiftExerciseResult>? liftResults;

  // Circuit
  final int? circuitRoundsCompleted;
  final String? circuitNotes;

  // Personal
  final bool isPersonal;

  WorkoutResult({
    required this.id,
    this.sessionId,
    required this.organizationId,
    this.teamId,
    required this.userId,
    required this.loggedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.ergIntervals,
    this.ergTotalDistance,
    this.ergTotalTimeMs,
    this.ergAvgSplitPer500Ms,
    this.ergAvgHeartRate,
    this.waterPieces,
    this.waterTotalDistance,
    this.waterTotalTimeMs,
    this.waterNotes,
    this.boatClass,
    this.raceTimeMs,
    this.racePlacement,
    this.raceOpponents,
    this.raceMarginMs,
    this.liftResults,
    this.circuitRoundsCompleted,
    this.circuitNotes,
    this.isPersonal = false,
  });

  // ── Computed helpers ──

  /// Calculate totals from erg intervals
  int get calculatedErgTotalDistance =>
      ergTotalDistance ??
      (ergIntervals?.fold<int>(0, (sum, i) => sum + i.distance) ?? 0);

  int get calculatedErgTotalTimeMs =>
      ergTotalTimeMs ??
      (ergIntervals?.fold<int>(0, (sum, i) => sum + i.timeMs) ?? 0);

  int get calculatedErgAvgSplitPer500Ms {
    if (ergAvgSplitPer500Ms != null) return ergAvgSplitPer500Ms!;
    final dist = calculatedErgTotalDistance;
    final time = calculatedErgTotalTimeMs;
    if (dist <= 0) return 0;
    return ((time / dist) * 500).round();
  }

  int? get calculatedErgAvgHeartRate {
    if (ergAvgHeartRate != null) return ergAvgHeartRate;
    final hrs = ergIntervals
        ?.where((i) => i.avgHeartRate != null)
        .map((i) => i.avgHeartRate!)
        .toList();
    if (hrs == null || hrs.isEmpty) return null;
    return (hrs.reduce((a, b) => a + b) / hrs.length).round();
  }

  /// Format milliseconds as rowing split string (e.g., "1:38.2")
  static String formatSplit(int ms) {
    final totalSeconds = ms / 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final secStr = seconds.toStringAsFixed(1).padLeft(4, '0');
    return '$minutes:$secStr';
  }

  /// Format milliseconds as time string (e.g., "19:42.3")
  static String formatTime(int ms) {
    final totalSeconds = ms / 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      final secStr = seconds.toStringAsFixed(1).padLeft(4, '0');
      return '$hours:${mins.toString().padLeft(2, '0')}:$secStr';
    }
    final secStr = seconds.toStringAsFixed(1).padLeft(4, '0');
    return '$minutes:$secStr';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'organizationId': organizationId,
      'teamId': teamId,
      'userId': userId,
      'loggedBy': loggedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category.name,
      // Erg
      if (ergIntervals != null)
        'ergIntervals': ergIntervals!.map((i) => i.toMap()).toList(),
      if (ergTotalDistance != null) 'ergTotalDistance': ergTotalDistance,
      if (ergTotalTimeMs != null) 'ergTotalTimeMs': ergTotalTimeMs,
      if (ergAvgSplitPer500Ms != null)
        'ergAvgSplitPer500Ms': ergAvgSplitPer500Ms,
      if (ergAvgHeartRate != null) 'ergAvgHeartRate': ergAvgHeartRate,
      // Water
      if (waterPieces != null)
        'waterPieces': waterPieces!.map((p) => p.toMap()).toList(),
      if (waterTotalDistance != null) 'waterTotalDistance': waterTotalDistance,
      if (waterTotalTimeMs != null) 'waterTotalTimeMs': waterTotalTimeMs,
      if (waterNotes != null) 'waterNotes': waterNotes,
      if (boatClass != null) 'boatClass': boatClass,
      // Race
      if (raceTimeMs != null) 'raceTimeMs': raceTimeMs,
      if (racePlacement != null) 'racePlacement': racePlacement,
      if (raceOpponents != null) 'raceOpponents': raceOpponents,
      if (raceMarginMs != null) 'raceMarginMs': raceMarginMs,
      // Lift
      if (liftResults != null)
        'liftResults': liftResults!.map((r) => r.toMap()).toList(),
      // Circuit
      if (circuitRoundsCompleted != null)
        'circuitRoundsCompleted': circuitRoundsCompleted,
      if (circuitNotes != null) 'circuitNotes': circuitNotes,
      // Personal
      'isPersonal': isPersonal,
    };
  }

  factory WorkoutResult.fromMap(Map<String, dynamic> map) {
    return WorkoutResult(
      id: map['id'] ?? '',
      sessionId: map['sessionId'],
      organizationId: map['organizationId'] ?? '',
      teamId: map['teamId'],
      userId: map['userId'] ?? '',
      loggedBy: map['loggedBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      category: WorkoutCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => WorkoutCategory.erg,
      ),
      ergIntervals: map['ergIntervals'] != null
          ? (map['ergIntervals'] as List)
                .map((i) => ErgIntervalResult.fromMap(i))
                .toList()
          : null,
      ergTotalDistance: map['ergTotalDistance'],
      ergTotalTimeMs: map['ergTotalTimeMs'],
      ergAvgSplitPer500Ms: map['ergAvgSplitPer500Ms'],
      ergAvgHeartRate: map['ergAvgHeartRate'],
      waterPieces: map['waterPieces'] != null
          ? (map['waterPieces'] as List)
                .map((p) => WaterPieceResult.fromMap(p))
                .toList()
          : null,
      waterTotalDistance: map['waterTotalDistance'],
      waterTotalTimeMs: map['waterTotalTimeMs'],
      waterNotes: map['waterNotes'],
      boatClass: map['boatClass'],
      raceTimeMs: map['raceTimeMs'],
      racePlacement: map['racePlacement'],
      raceOpponents: map['raceOpponents'] != null
          ? List<String>.from(map['raceOpponents'])
          : null,
      raceMarginMs: map['raceMarginMs'],
      liftResults: map['liftResults'] != null
          ? (map['liftResults'] as List)
                .map((r) => LiftExerciseResult.fromMap(r))
                .toList()
          : null,
      circuitRoundsCompleted: map['circuitRoundsCompleted'],
      circuitNotes: map['circuitNotes'],
      isPersonal: map['isPersonal'] ?? false,
    );
  }

  WorkoutResult copyWith({
    String? id,
    String? sessionId,
    String? organizationId,
    String? teamId,
    String? userId,
    String? loggedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    WorkoutCategory? category,
    List<ErgIntervalResult>? ergIntervals,
    int? ergTotalDistance,
    int? ergTotalTimeMs,
    int? ergAvgSplitPer500Ms,
    int? ergAvgHeartRate,
    List<WaterPieceResult>? waterPieces,
    int? waterTotalDistance,
    int? waterTotalTimeMs,
    String? waterNotes,
    String? boatClass,
    int? raceTimeMs,
    int? racePlacement,
    List<String>? raceOpponents,
    int? raceMarginMs,
    List<LiftExerciseResult>? liftResults,
    int? circuitRoundsCompleted,
    String? circuitNotes,
    bool? isPersonal,
  }) {
    return WorkoutResult(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      organizationId: organizationId ?? this.organizationId,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      loggedBy: loggedBy ?? this.loggedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      ergIntervals: ergIntervals ?? this.ergIntervals,
      ergTotalDistance: ergTotalDistance ?? this.ergTotalDistance,
      ergTotalTimeMs: ergTotalTimeMs ?? this.ergTotalTimeMs,
      ergAvgSplitPer500Ms: ergAvgSplitPer500Ms ?? this.ergAvgSplitPer500Ms,
      ergAvgHeartRate: ergAvgHeartRate ?? this.ergAvgHeartRate,
      waterPieces: waterPieces ?? this.waterPieces,
      waterTotalDistance: waterTotalDistance ?? this.waterTotalDistance,
      waterTotalTimeMs: waterTotalTimeMs ?? this.waterTotalTimeMs,
      waterNotes: waterNotes ?? this.waterNotes,
      boatClass: boatClass ?? this.boatClass,
      raceTimeMs: raceTimeMs ?? this.raceTimeMs,
      racePlacement: racePlacement ?? this.racePlacement,
      raceOpponents: raceOpponents ?? this.raceOpponents,
      raceMarginMs: raceMarginMs ?? this.raceMarginMs,
      liftResults: liftResults ?? this.liftResults,
      circuitRoundsCompleted:
          circuitRoundsCompleted ?? this.circuitRoundsCompleted,
      circuitNotes: circuitNotes ?? this.circuitNotes,
      isPersonal: isPersonal ?? this.isPersonal,
    );
  }
}
