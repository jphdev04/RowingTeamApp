import 'workout_template.dart';

// ── Analysis sub-models ───────────────────────────────────────

class SwapResult {
  final int swapNumber;
  final String description; // e.g. "Rower A ↔ Rower B in seat 3"
  final int beforePiece; // piece number
  final int afterPiece; // piece number
  final String boatName;
  final int beforeTimeMs;
  final int afterTimeMs;
  final String? winnerUserId;
  final int marginMs;

  SwapResult({
    required this.swapNumber,
    required this.description,
    required this.beforePiece,
    required this.afterPiece,
    required this.boatName,
    required this.beforeTimeMs,
    required this.afterTimeMs,
    this.winnerUserId,
    required this.marginMs,
  });

  Map<String, dynamic> toMap() => {
    'swapNumber': swapNumber,
    'description': description,
    'beforePiece': beforePiece,
    'afterPiece': afterPiece,
    'boatName': boatName,
    'beforeTimeMs': beforeTimeMs,
    'afterTimeMs': afterTimeMs,
    if (winnerUserId != null) 'winnerUserId': winnerUserId,
    'marginMs': marginMs,
  };

  factory SwapResult.fromMap(Map<String, dynamic> map) => SwapResult(
    swapNumber: map['swapNumber'] ?? 0,
    description: map['description'] ?? '',
    beforePiece: map['beforePiece'] ?? 0,
    afterPiece: map['afterPiece'] ?? 0,
    boatName: map['boatName'] ?? '',
    beforeTimeMs: map['beforeTimeMs'] ?? 0,
    afterTimeMs: map['afterTimeMs'] ?? 0,
    winnerUserId: map['winnerUserId'],
    marginMs: map['marginMs'] ?? 0,
  );
}

class MatrixAthleteResult {
  final String userId;
  final String side; // 'port' or 'starboard'
  final List<MatrixPieceTime> pieceTimes;
  final List<int> droppedPieces; // indices of dropped pieces
  final int totalTimeMs; // after drops
  final int rank;

  MatrixAthleteResult({
    required this.userId,
    required this.side,
    required this.pieceTimes,
    this.droppedPieces = const [],
    required this.totalTimeMs,
    required this.rank,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'side': side,
    'pieceTimes': pieceTimes.map((p) => p.toMap()).toList(),
    'droppedPieces': droppedPieces,
    'totalTimeMs': totalTimeMs,
    'rank': rank,
  };

  factory MatrixAthleteResult.fromMap(Map<String, dynamic> map) =>
      MatrixAthleteResult(
        userId: map['userId'] ?? '',
        side: map['side'] ?? '',
        pieceTimes: (map['pieceTimes'] as List? ?? [])
            .map((p) => MatrixPieceTime.fromMap(p))
            .toList(),
        droppedPieces: List<int>.from(map['droppedPieces'] ?? []),
        totalTimeMs: map['totalTimeMs'] ?? 0,
        rank: map['rank'] ?? 0,
      );
}

class MatrixPieceTime {
  final int pieceNumber;
  final String boatName;
  final int timeMs;

  MatrixPieceTime({
    required this.pieceNumber,
    required this.boatName,
    required this.timeMs,
  });

  Map<String, dynamic> toMap() => {
    'pieceNumber': pieceNumber,
    'boatName': boatName,
    'timeMs': timeMs,
  };

  factory MatrixPieceTime.fromMap(Map<String, dynamic> map) => MatrixPieceTime(
    pieceNumber: map['pieceNumber'] ?? 0,
    boatName: map['boatName'] ?? '',
    timeMs: map['timeMs'] ?? 0,
  );
}

class MatrixResults {
  final List<MatrixAthleteResult> rankings;
  final List<String> portRankings; // userIds, fastest to slowest
  final List<String> starboardRankings;

  MatrixResults({
    required this.rankings,
    required this.portRankings,
    required this.starboardRankings,
  });

  Map<String, dynamic> toMap() => {
    'rankings': rankings.map((r) => r.toMap()).toList(),
    'portRankings': portRankings,
    'starboardRankings': starboardRankings,
  };

  factory MatrixResults.fromMap(Map<String, dynamic> map) => MatrixResults(
    rankings: (map['rankings'] as List? ?? [])
        .map((r) => MatrixAthleteResult.fromMap(r))
        .toList(),
    portRankings: List<String>.from(map['portRankings'] ?? []),
    starboardRankings: List<String>.from(map['starboardRankings'] ?? []),
  );
}

class TrialBoatResult {
  final String boatName;
  final String boatClass;
  final List<String> athletes; // userIds
  final int timeMs;
  final int rank;

  TrialBoatResult({
    required this.boatName,
    required this.boatClass,
    required this.athletes,
    required this.timeMs,
    required this.rank,
  });

  Map<String, dynamic> toMap() => {
    'boatName': boatName,
    'boatClass': boatClass,
    'athletes': athletes,
    'timeMs': timeMs,
    'rank': rank,
  };

  factory TrialBoatResult.fromMap(Map<String, dynamic> map) => TrialBoatResult(
    boatName: map['boatName'] ?? '',
    boatClass: map['boatClass'] ?? '',
    athletes: List<String>.from(map['athletes'] ?? []),
    timeMs: map['timeMs'] ?? 0,
    rank: map['rank'] ?? 0,
  );
}

class TrialResults {
  final List<TrialBoatResult> boatRankings;
  final List<String> selectedForLineup; // userIds coach picked
  final String? targetBoatClass; // what they're selecting for (e.g. '8+')

  TrialResults({
    required this.boatRankings,
    this.selectedForLineup = const [],
    this.targetBoatClass,
  });

  Map<String, dynamic> toMap() => {
    'boatRankings': boatRankings.map((b) => b.toMap()).toList(),
    'selectedForLineup': selectedForLineup,
    if (targetBoatClass != null) 'targetBoatClass': targetBoatClass,
  };

  factory TrialResults.fromMap(Map<String, dynamic> map) => TrialResults(
    boatRankings: (map['boatRankings'] as List? ?? [])
        .map((b) => TrialBoatResult.fromMap(b))
        .toList(),
    selectedForLineup: List<String>.from(map['selectedForLineup'] ?? []),
    targetBoatClass: map['targetBoatClass'],
  );
}

// ── SeatRaceAnalysis ──────────────────────────────────────────

class SeatRaceAnalysis {
  final String id;
  final String sessionId;
  final String organizationId;
  final String? teamId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  final SeatRaceFormat format;

  // Direct swap
  final List<SwapResult>? swapResults;

  // Matrix (fours or pairs)
  final MatrixResults? matrixResults;

  // Trial
  final TrialResults? trialResults;

  // Coach notes
  final String? notes;

  SeatRaceAnalysis({
    required this.id,
    required this.sessionId,
    required this.organizationId,
    this.teamId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.format,
    this.swapResults,
    this.matrixResults,
    this.trialResults,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'organizationId': organizationId,
      'teamId': teamId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'format': format.name,
      if (swapResults != null)
        'swapResults': swapResults!.map((s) => s.toMap()).toList(),
      if (matrixResults != null) 'matrixResults': matrixResults!.toMap(),
      if (trialResults != null) 'trialResults': trialResults!.toMap(),
      if (notes != null) 'notes': notes,
    };
  }

  factory SeatRaceAnalysis.fromMap(Map<String, dynamic> map) {
    return SeatRaceAnalysis(
      id: map['id'] ?? '',
      sessionId: map['sessionId'] ?? '',
      organizationId: map['organizationId'] ?? '',
      teamId: map['teamId'],
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      format: SeatRaceFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => SeatRaceFormat.directSwap,
      ),
      swapResults: map['swapResults'] != null
          ? (map['swapResults'] as List)
                .map((s) => SwapResult.fromMap(s))
                .toList()
          : null,
      matrixResults: map['matrixResults'] != null
          ? MatrixResults.fromMap(map['matrixResults'])
          : null,
      trialResults: map['trialResults'] != null
          ? TrialResults.fromMap(map['trialResults'])
          : null,
      notes: map['notes'],
    );
  }

  SeatRaceAnalysis copyWith({
    String? id,
    String? sessionId,
    String? organizationId,
    String? teamId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    SeatRaceFormat? format,
    List<SwapResult>? swapResults,
    MatrixResults? matrixResults,
    TrialResults? trialResults,
    String? notes,
  }) {
    return SeatRaceAnalysis(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      organizationId: organizationId ?? this.organizationId,
      teamId: teamId ?? this.teamId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      format: format ?? this.format,
      swapResults: swapResults ?? this.swapResults,
      matrixResults: matrixResults ?? this.matrixResults,
      trialResults: trialResults ?? this.trialResults,
      notes: notes ?? this.notes,
    );
  }
}
