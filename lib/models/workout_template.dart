// ── Enums ─────────────────────────────────────────────────────

enum WorkoutCategory { water, race, erg, lift, circuit }

enum ErgType { single, standardIntervals, variableIntervals }

enum ErgFormat { time, distance }

enum WaterFormat { loose, structured }

enum RaceType { head, sprint, dual }

enum CircuitFormat { timed, reps }

enum SeatRaceFormat { directSwap, foursMatrix, pairsMatrix, trial }

// ── Helper sub-models ─────────────────────────────────────────

class VariableInterval {
  final int? distance; // meters (if ergFormat = distance)
  final int? time; // seconds (if ergFormat = time)
  final int restSeconds;
  final int? strokeRateCap; // spm — null means no cap

  VariableInterval({
    this.distance,
    this.time,
    required this.restSeconds,
    this.strokeRateCap,
  });

  Map<String, dynamic> toMap() => {
    if (distance != null) 'distance': distance,
    if (time != null) 'time': time,
    'restSeconds': restSeconds,
    if (strokeRateCap != null) 'strokeRateCap': strokeRateCap,
  };

  factory VariableInterval.fromMap(Map<String, dynamic> map) =>
      VariableInterval(
        distance: map['distance'],
        time: map['time'],
        restSeconds: map['restSeconds'] ?? 0,
        strokeRateCap: map['strokeRateCap'],
      );
}

class WaterPiece {
  final int pieceNumber;
  final int? distance; // meters
  final int? time; // seconds
  final int? restSeconds;
  final int? strokeRateCap; // spm — null means no cap

  WaterPiece({
    required this.pieceNumber,
    this.distance,
    this.time,
    this.restSeconds,
    this.strokeRateCap,
  });

  Map<String, dynamic> toMap() => {
    'pieceNumber': pieceNumber,
    if (distance != null) 'distance': distance,
    if (time != null) 'time': time,
    if (restSeconds != null) 'restSeconds': restSeconds,
    if (strokeRateCap != null) 'strokeRateCap': strokeRateCap,
  };

  factory WaterPiece.fromMap(Map<String, dynamic> map) => WaterPiece(
    pieceNumber: map['pieceNumber'] ?? 0,
    distance: map['distance'],
    time: map['time'],
    restSeconds: map['restSeconds'],
    strokeRateCap: map['strokeRateCap'],
  );
}

class LiftExercise {
  final String name;
  final int sets;
  final int reps;
  final double? weight;
  final String? notes;

  LiftExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    if (weight != null) 'weight': weight,
    if (notes != null) 'notes': notes,
  };

  factory LiftExercise.fromMap(Map<String, dynamic> map) => LiftExercise(
    name: map['name'] ?? '',
    sets: map['sets'] ?? 0,
    reps: map['reps'] ?? 0,
    weight: map['weight']?.toDouble(),
    notes: map['notes'],
  );
}

class CircuitExercise {
  final String name;
  final int? reps;
  final String? notes;

  CircuitExercise({required this.name, this.reps, this.notes});

  Map<String, dynamic> toMap() => {
    'name': name,
    if (reps != null) 'reps': reps,
    if (notes != null) 'notes': notes,
  };

  factory CircuitExercise.fromMap(Map<String, dynamic> map) => CircuitExercise(
    name: map['name'] ?? '',
    reps: map['reps'],
    notes: map['notes'],
  );
}

// ── WorkoutTemplate ───────────────────────────────────────────

class WorkoutTemplate {
  final String id;
  final String organizationId;
  final String? teamId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Core
  final String name;
  final WorkoutCategory category;
  final bool isBenchmark;
  final String? description;

  // Erg
  final ErgType? ergType;
  final ErgFormat? ergFormat;
  final int? targetDistance;
  final int? targetTime;
  final int? intervalCount;
  final int? intervalDistance;
  final int? intervalTime;
  final int? restSeconds;
  final List<VariableInterval>? variableIntervals;

  // Stroke rate cap (spm) — used by single piece & standard intervals.
  // For standard intervals this is a per-interval list (length == intervalCount).
  // For single piece it's a single-element list or just [0] index.
  // For variable intervals, the cap lives on each VariableInterval.
  final int? strokeRateCap; // single piece cap
  final List<int?>?
  intervalStrokeRateCaps; // per-interval caps for standard intervals

  // Water
  final WaterFormat? waterFormat;
  final String? waterDescription;
  final int? waterPieceCount;
  final List<WaterPiece>? waterPieces;
  final List<String>? boatClasses;

  // Race
  final RaceType? raceType;
  final int? raceDistance;

  // Lift
  final List<LiftExercise>? liftExercises;

  // Circuit
  final CircuitFormat? circuitFormat;
  final int? circuitRounds;
  final int? circuitStationTime;
  final int? circuitRestBetweenStations;
  final int? circuitRestBetweenRounds;
  final List<CircuitExercise>? circuitExercises;

  WorkoutTemplate({
    required this.id,
    required this.organizationId,
    this.teamId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.category,
    this.isBenchmark = false,
    this.description,
    this.ergType,
    this.ergFormat,
    this.targetDistance,
    this.targetTime,
    this.intervalCount,
    this.intervalDistance,
    this.intervalTime,
    this.restSeconds,
    this.variableIntervals,
    this.strokeRateCap,
    this.intervalStrokeRateCaps,
    this.waterFormat,
    this.waterDescription,
    this.waterPieceCount,
    this.waterPieces,
    this.boatClasses,
    this.raceType,
    this.raceDistance,
    this.liftExercises,
    this.circuitFormat,
    this.circuitRounds,
    this.circuitStationTime,
    this.circuitRestBetweenStations,
    this.circuitRestBetweenRounds,
    this.circuitExercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'teamId': teamId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
      'category': category.name,
      'isBenchmark': isBenchmark,
      'description': description,
      // Erg
      if (ergType != null) 'ergType': ergType!.name,
      if (ergFormat != null) 'ergFormat': ergFormat!.name,
      if (targetDistance != null) 'targetDistance': targetDistance,
      if (targetTime != null) 'targetTime': targetTime,
      if (intervalCount != null) 'intervalCount': intervalCount,
      if (intervalDistance != null) 'intervalDistance': intervalDistance,
      if (intervalTime != null) 'intervalTime': intervalTime,
      if (restSeconds != null) 'restSeconds': restSeconds,
      if (variableIntervals != null)
        'variableIntervals': variableIntervals!.map((v) => v.toMap()).toList(),
      if (strokeRateCap != null) 'strokeRateCap': strokeRateCap,
      if (intervalStrokeRateCaps != null)
        'intervalStrokeRateCaps': intervalStrokeRateCaps,
      // Water
      if (waterFormat != null) 'waterFormat': waterFormat!.name,
      if (waterDescription != null) 'waterDescription': waterDescription,
      if (waterPieceCount != null) 'waterPieceCount': waterPieceCount,
      if (waterPieces != null)
        'waterPieces': waterPieces!.map((p) => p.toMap()).toList(),
      if (boatClasses != null) 'boatClasses': boatClasses,
      // Race
      if (raceType != null) 'raceType': raceType!.name,
      if (raceDistance != null) 'raceDistance': raceDistance,
      // Lift
      if (liftExercises != null)
        'liftExercises': liftExercises!.map((e) => e.toMap()).toList(),
      // Circuit
      if (circuitFormat != null) 'circuitFormat': circuitFormat!.name,
      if (circuitRounds != null) 'circuitRounds': circuitRounds,
      if (circuitStationTime != null) 'circuitStationTime': circuitStationTime,
      if (circuitRestBetweenStations != null)
        'circuitRestBetweenStations': circuitRestBetweenStations,
      if (circuitRestBetweenRounds != null)
        'circuitRestBetweenRounds': circuitRestBetweenRounds,
      if (circuitExercises != null)
        'circuitExercises': circuitExercises!.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map) {
    return WorkoutTemplate(
      id: map['id'] ?? '',
      organizationId: map['organizationId'] ?? '',
      teamId: map['teamId'],
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      name: map['name'] ?? '',
      category: WorkoutCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => WorkoutCategory.erg,
      ),
      isBenchmark: map['isBenchmark'] ?? false,
      description: map['description'],
      // Erg
      ergType: map['ergType'] != null
          ? ErgType.values.firstWhere(
              (e) => e.name == map['ergType'],
              orElse: () => ErgType.single,
            )
          : null,
      ergFormat: map['ergFormat'] != null
          ? ErgFormat.values.firstWhere(
              (e) => e.name == map['ergFormat'],
              orElse: () => ErgFormat.distance,
            )
          : null,
      targetDistance: map['targetDistance'],
      targetTime: map['targetTime'],
      intervalCount: map['intervalCount'],
      intervalDistance: map['intervalDistance'],
      intervalTime: map['intervalTime'],
      restSeconds: map['restSeconds'],
      variableIntervals: map['variableIntervals'] != null
          ? (map['variableIntervals'] as List)
                .map((v) => VariableInterval.fromMap(v))
                .toList()
          : null,
      strokeRateCap: map['strokeRateCap'],
      intervalStrokeRateCaps: map['intervalStrokeRateCaps'] != null
          ? (map['intervalStrokeRateCaps'] as List)
                .map((e) => e as int?)
                .toList()
          : null,
      // Water
      waterFormat: map['waterFormat'] != null
          ? WaterFormat.values.firstWhere(
              (e) => e.name == map['waterFormat'],
              orElse: () => WaterFormat.loose,
            )
          : null,
      waterDescription: map['waterDescription'],
      waterPieceCount: map['waterPieceCount'],
      waterPieces: map['waterPieces'] != null
          ? (map['waterPieces'] as List)
                .map((p) => WaterPiece.fromMap(p))
                .toList()
          : null,
      boatClasses: map['boatClasses'] != null
          ? List<String>.from(map['boatClasses'])
          : null,
      // Race
      raceType: map['raceType'] != null
          ? RaceType.values.firstWhere(
              (e) => e.name == map['raceType'],
              orElse: () => RaceType.sprint,
            )
          : null,
      raceDistance: map['raceDistance'],
      // Lift
      liftExercises: map['liftExercises'] != null
          ? (map['liftExercises'] as List)
                .map((e) => LiftExercise.fromMap(e))
                .toList()
          : null,
      // Circuit
      circuitFormat: map['circuitFormat'] != null
          ? CircuitFormat.values.firstWhere(
              (e) => e.name == map['circuitFormat'],
              orElse: () => CircuitFormat.timed,
            )
          : null,
      circuitRounds: map['circuitRounds'],
      circuitStationTime: map['circuitStationTime'],
      circuitRestBetweenStations: map['circuitRestBetweenStations'],
      circuitRestBetweenRounds: map['circuitRestBetweenRounds'],
      circuitExercises: map['circuitExercises'] != null
          ? (map['circuitExercises'] as List)
                .map((e) => CircuitExercise.fromMap(e))
                .toList()
          : null,
    );
  }

  WorkoutTemplate copyWith({
    String? id,
    String? organizationId,
    String? teamId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    WorkoutCategory? category,
    bool? isBenchmark,
    String? description,
    ErgType? ergType,
    ErgFormat? ergFormat,
    int? targetDistance,
    int? targetTime,
    int? intervalCount,
    int? intervalDistance,
    int? intervalTime,
    int? restSeconds,
    List<VariableInterval>? variableIntervals,
    int? strokeRateCap,
    List<int?>? intervalStrokeRateCaps,
    WaterFormat? waterFormat,
    String? waterDescription,
    int? waterPieceCount,
    List<WaterPiece>? waterPieces,
    List<String>? boatClasses,
    RaceType? raceType,
    int? raceDistance,
    List<LiftExercise>? liftExercises,
    CircuitFormat? circuitFormat,
    int? circuitRounds,
    int? circuitStationTime,
    int? circuitRestBetweenStations,
    int? circuitRestBetweenRounds,
    List<CircuitExercise>? circuitExercises,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      teamId: teamId ?? this.teamId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      category: category ?? this.category,
      isBenchmark: isBenchmark ?? this.isBenchmark,
      description: description ?? this.description,
      ergType: ergType ?? this.ergType,
      ergFormat: ergFormat ?? this.ergFormat,
      targetDistance: targetDistance ?? this.targetDistance,
      targetTime: targetTime ?? this.targetTime,
      intervalCount: intervalCount ?? this.intervalCount,
      intervalDistance: intervalDistance ?? this.intervalDistance,
      intervalTime: intervalTime ?? this.intervalTime,
      restSeconds: restSeconds ?? this.restSeconds,
      variableIntervals: variableIntervals ?? this.variableIntervals,
      strokeRateCap: strokeRateCap ?? this.strokeRateCap,
      intervalStrokeRateCaps:
          intervalStrokeRateCaps ?? this.intervalStrokeRateCaps,
      waterFormat: waterFormat ?? this.waterFormat,
      waterDescription: waterDescription ?? this.waterDescription,
      waterPieceCount: waterPieceCount ?? this.waterPieceCount,
      waterPieces: waterPieces ?? this.waterPieces,
      boatClasses: boatClasses ?? this.boatClasses,
      raceType: raceType ?? this.raceType,
      raceDistance: raceDistance ?? this.raceDistance,
      liftExercises: liftExercises ?? this.liftExercises,
      circuitFormat: circuitFormat ?? this.circuitFormat,
      circuitRounds: circuitRounds ?? this.circuitRounds,
      circuitStationTime: circuitStationTime ?? this.circuitStationTime,
      circuitRestBetweenStations:
          circuitRestBetweenStations ?? this.circuitRestBetweenStations,
      circuitRestBetweenRounds:
          circuitRestBetweenRounds ?? this.circuitRestBetweenRounds,
      circuitExercises: circuitExercises ?? this.circuitExercises,
    );
  }
}
