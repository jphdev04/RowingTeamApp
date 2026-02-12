import 'package:flutter/material.dart';

enum EquipmentType { shell, oar, coxbox, launch, erg }

enum ShellType {
  eight, // 8+
  coxedFour, // 4+
  four, // 4-
  quad, // 4x
  coxedQuad, // 4x+
  pair, // 2-
  double, // 2x
  single, // 1x
}

enum RiggingType { sweep, scull, dualRigged }

enum OarType { sweep, scull }

enum EquipmentStatus { available, inUse, damaged, maintenance }

/// Which side a rigger is on for a specific seat.
enum RiggerSide { port, starboard }

// ════════════════════════════════════════════════════════════
// RIGGING SETUP
// ════════════════════════════════════════════════════════════

/// A single seat's rigger position — seat number + which side.
class RiggerPosition {
  final int seat; // 1 = bow, N = stroke
  final RiggerSide side;

  RiggerPosition({required this.seat, required this.side});

  Map<String, dynamic> toMap() => {'seat': seat, 'side': side.name};

  factory RiggerPosition.fromMap(Map<String, dynamic> map) => RiggerPosition(
    seat: map['seat'] ?? 0,
    side: RiggerSide.values.firstWhere(
      (e) => e.name == map['side'],
      orElse: () => RiggerSide.port,
    ),
  );

  RiggerPosition copyWith({int? seat, RiggerSide? side}) =>
      RiggerPosition(seat: seat ?? this.seat, side: side ?? this.side);
}

/// Complete rigging configuration for a shell.
/// Only meaningful for sweep boats — sculling boats don't need side assignments.
class RiggingSetup {
  final String name; // e.g., "Standard Port Stroke", "Bucket 7-6", custom name
  final List<RiggerPosition> positions; // one per rowing seat
  final bool isDefault; // whether this is the shell's current active rig

  RiggingSetup({
    required this.name,
    required this.positions,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'positions': positions.map((p) => p.toMap()).toList(),
    'isDefault': isDefault,
  };

  factory RiggingSetup.fromMap(Map<String, dynamic> map) => RiggingSetup(
    name: map['name'] ?? '',
    positions: (map['positions'] as List? ?? [])
        .map((p) => RiggerPosition.fromMap(p))
        .toList(),
    isDefault: map['isDefault'] ?? false,
  );

  RiggingSetup copyWith({
    String? name,
    List<RiggerPosition>? positions,
    bool? isDefault,
  }) => RiggingSetup(
    name: name ?? this.name,
    positions: positions ?? this.positions,
    isDefault: isDefault ?? this.isDefault,
  );

  /// Validates that the rig has equal port and starboard riggers.
  bool get isBalanced {
    if (positions.isEmpty) return true;
    final portCount = positions.where((p) => p.side == RiggerSide.port).length;
    final stbdCount = positions
        .where((p) => p.side == RiggerSide.starboard)
        .length;
    return portCount == stbdCount;
  }

  /// Returns which side the stroke seat is on.
  RiggerSide? get strokeSide {
    if (positions.isEmpty) return null;
    final strokeSeat = positions
        .where((p) => p.seat == positions.length)
        .toList();
    return strokeSeat.isNotEmpty ? strokeSeat.first.side : null;
  }

  /// Returns a human-readable description of the rig pattern.
  String get description {
    if (positions.isEmpty) return 'No rigging set';
    final strokeS = strokeSide;
    if (strokeS == null) return name;

    // Check if it's standard alternating
    bool isStandardAlternating = true;
    for (final p in positions) {
      final expectedSide = (p.seat % 2 == positions.length % 2)
          ? strokeS
          : (strokeS == RiggerSide.port
                ? RiggerSide.starboard
                : RiggerSide.port);
      if (p.side != expectedSide) {
        isStandardAlternating = false;
        break;
      }
    }

    if (isStandardAlternating) {
      return strokeS == RiggerSide.port
          ? 'Standard (port stroke)'
          : 'Standard (starboard stroke)';
    }

    // Check for buckets — consecutive same-side seats
    final buckets = <String>[];
    for (int i = positions.length; i > 1; i--) {
      final current = positions.firstWhere(
        (p) => p.seat == i,
        orElse: () => positions[0],
      );
      final below = positions.firstWhere(
        (p) => p.seat == i - 1,
        orElse: () => positions[0],
      );
      if (current.side == below.side) {
        buckets.add('$i-${i - 1}');
      }
    }

    if (buckets.isNotEmpty) {
      final strokeLabel = strokeS == RiggerSide.port
          ? 'port stroke'
          : 'starboard stroke';
      return 'Bucket ${buckets.join(", ")} ($strokeLabel)';
    }

    return name;
  }
}

// ════════════════════════════════════════════════════════════
// RIGGING PRESETS
// ════════════════════════════════════════════════════════════

class RiggingPresets {
  /// Standard port-stroke alternating rig for N seats.
  static RiggingSetup standardPortStroke(int seatCount) {
    return RiggingSetup(
      name: 'Standard (port stroke)',
      positions: List.generate(seatCount, (i) {
        final seat = i + 1;
        // Stroke (highest seat) is port, then alternates
        final isPort = (seat % 2 == seatCount % 2);
        return RiggerPosition(
          seat: seat,
          side: isPort ? RiggerSide.port : RiggerSide.starboard,
        );
      }),
      isDefault: true,
    );
  }

  /// Standard starboard-stroke alternating rig for N seats.
  static RiggingSetup standardStarboardStroke(int seatCount) {
    return RiggingSetup(
      name: 'Standard (starboard stroke)',
      positions: List.generate(seatCount, (i) {
        final seat = i + 1;
        final isStbd = (seat % 2 == seatCount % 2);
        return RiggerPosition(
          seat: seat,
          side: isStbd ? RiggerSide.starboard : RiggerSide.port,
        );
      }),
    );
  }

  /// Italian/bucket rig — bucket at stroke+7 (or top two seats).
  /// Stroke and seat below stroke are on same side, then alternates.
  static RiggingSetup bucketTop(
    int seatCount, {
    RiggerSide strokeSide = RiggerSide.port,
  }) {
    if (seatCount < 4) return standardPortStroke(seatCount);
    final opposite = strokeSide == RiggerSide.port
        ? RiggerSide.starboard
        : RiggerSide.port;

    final positions = <RiggerPosition>[];
    for (int seat = 1; seat <= seatCount; seat++) {
      RiggerSide side;
      if (seat == seatCount || seat == seatCount - 1) {
        // Top bucket: stroke + seat below are same side
        side = strokeSide;
      } else if (seat == seatCount - 2 || seat == seatCount - 3) {
        side = opposite;
      } else {
        // Continue alternating in pairs going down
        final pairIndex = (seatCount - 1 - seat) ~/ 2;
        side = pairIndex % 2 == 0 ? strokeSide : opposite;
      }
      positions.add(RiggerPosition(seat: seat, side: side));
    }

    return RiggingSetup(
      name: 'Bucket ${seatCount}-${seatCount - 1}',
      positions: positions,
    );
  }

  /// German rig — bucket in the middle (seats 5-4 or 3-2 for a four).
  static RiggingSetup bucketMiddle(
    int seatCount, {
    RiggerSide strokeSide = RiggerSide.port,
  }) {
    if (seatCount < 4) return standardPortStroke(seatCount);
    final opposite = strokeSide == RiggerSide.port
        ? RiggerSide.starboard
        : RiggerSide.port;

    final midHigh = (seatCount ~/ 2) + 1;
    final midLow = seatCount ~/ 2;

    final positions = <RiggerPosition>[];
    for (int seat = 1; seat <= seatCount; seat++) {
      RiggerSide side;
      if (seat == seatCount) {
        side = strokeSide;
      } else if (seat == seatCount - 1) {
        side = opposite;
      } else if (seat == midHigh || seat == midLow) {
        // Middle bucket — same side as whichever makes it balanced
        side = opposite;
      } else {
        // Standard alternating from stroke down, but skip the bucket
        final distFromStroke = seatCount - seat;
        side = distFromStroke % 2 == 0 ? strokeSide : opposite;
      }
      positions.add(RiggerPosition(seat: seat, side: side));
    }

    // Verify balance; if not balanced, fall back
    final setup = RiggingSetup(
      name: 'Bucket $midHigh-$midLow',
      positions: positions,
    );
    if (!setup.isBalanced) return standardPortStroke(seatCount);
    return setup;
  }

  /// Get all applicable presets for a given seat count.
  static List<RiggingSetup> presetsForSeatCount(int seatCount) {
    if (seatCount <= 1) return []; // Singles don't need rigging
    if (seatCount == 2) {
      return [standardPortStroke(2), standardStarboardStroke(2)];
    }

    final presets = <RiggingSetup>[
      standardPortStroke(seatCount),
      standardStarboardStroke(seatCount),
      bucketTop(seatCount, strokeSide: RiggerSide.port),
      bucketTop(seatCount, strokeSide: RiggerSide.starboard),
    ];

    if (seatCount >= 8) {
      presets.add(bucketMiddle(seatCount, strokeSide: RiggerSide.port));
      presets.add(bucketMiddle(seatCount, strokeSide: RiggerSide.starboard));
    }

    return presets;
  }
}

// ════════════════════════════════════════════════════════════
// EQUIPMENT MODEL
// ════════════════════════════════════════════════════════════

class Equipment {
  final String id;
  final String organizationId;
  final EquipmentType type;
  final String? name;
  final String manufacturer;
  final String? model;
  final int? year;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? notes;

  // Team assignment
  final bool availableToAllTeams;
  final List<String> assignedTeamIds;

  final EquipmentStatus status;
  final DateTime createdAt;
  final DateTime? lastMaintenanceDate;

  // Shell-specific fields
  final ShellType? shellType;
  final RiggingType? riggingType;
  final String? currentRiggingSetup; // For dual-rigged shells

  // ── Rigging ──
  /// The shell's current rigging configuration (sweep boats only).
  /// If null, defaults to standard port-stroke.
  final RiggingSetup? riggingSetup;

  /// For dual-rigged shells: the currently active configuration.
  /// When a dual-rigged shell is set to scull, this overrides shellType.
  final ShellType? activeShellType;

  // Oar-specific fields
  final OarType? oarType;
  final int? oarCount;
  final String? bladeType;
  final double? oarLength; // in cm

  // Coxbox-specific fields
  final bool? microphoneIncluded;
  final String? batteryStatus;

  // Launch-specific fields
  final bool? gasTankAssigned;
  final String? tankNumber;
  final String? fuelType;

  // Erg-specific fields
  final String? ergId;

  // Damage tracking
  final bool isDamaged;
  final List<DamageReport> damageReports;

  Equipment({
    required this.id,
    required this.organizationId,
    required this.type,
    this.name,
    required this.manufacturer,
    this.model,
    this.year,
    this.serialNumber,
    this.purchaseDate,
    this.purchasePrice,
    this.notes,
    this.availableToAllTeams = false,
    this.assignedTeamIds = const [],
    this.status = EquipmentStatus.available,
    required this.createdAt,
    this.lastMaintenanceDate,
    this.shellType,
    this.riggingType,
    this.currentRiggingSetup,
    this.riggingSetup,
    this.activeShellType,
    this.oarType,
    this.oarCount,
    this.bladeType,
    this.oarLength,
    this.microphoneIncluded,
    this.batteryStatus,
    this.gasTankAssigned,
    this.tankNumber,
    this.fuelType,
    this.ergId,
    this.isDamaged = false,
    this.damageReports = const [],
  });

  /// Returns the effective shell type — uses activeShellType for dual-rigged,
  /// otherwise falls back to shellType.
  ShellType? get effectiveShellType {
    if (riggingType == RiggingType.dualRigged && activeShellType != null) {
      return activeShellType;
    }
    return shellType;
  }

  /// Returns the effective rigging setup. If none is set, generates a
  /// standard port-stroke default based on the shell type.
  RiggingSetup? get effectiveRiggingSetup {
    if (riggingSetup != null) return riggingSetup;
    final st = effectiveShellType;
    if (st == null) return null;
    final seatCount = _seatCountForShellType(st);
    if (seatCount <= 1) return null; // Singles don't need rigging
    if (_isScullShellType(st))
      return null; // Sculling doesn't need side assignments
    return RiggingPresets.standardPortStroke(seatCount);
  }

  bool get isSweepConfig {
    final st = effectiveShellType;
    if (st == null) return false;
    return !_isScullShellType(st);
  }

  bool get isScullConfig {
    final st = effectiveShellType;
    if (st == null) return false;
    return _isScullShellType(st);
  }

  bool _isScullShellType(ShellType st) {
    return st == ShellType.single ||
        st == ShellType.double ||
        st == ShellType.quad ||
        st == ShellType.coxedQuad;
  }

  int _seatCountForShellType(ShellType st) {
    switch (st) {
      case ShellType.eight:
        return 8;
      case ShellType.coxedFour:
      case ShellType.four:
      case ShellType.quad:
      case ShellType.coxedQuad:
        return 4;
      case ShellType.pair:
      case ShellType.double:
        return 2;
      case ShellType.single:
        return 1;
    }
  }

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;

    switch (type) {
      case EquipmentType.shell:
        return '$manufacturer ${_shellTypeDisplay(effectiveShellType ?? shellType)}';
      case EquipmentType.oar:
        return '$manufacturer ${_oarTypeDisplay(oarType)} Oars';
      case EquipmentType.coxbox:
        return '$manufacturer Coxbox';
      case EquipmentType.launch:
        return '$manufacturer Launch';
      case EquipmentType.erg:
        return ergId != null ? 'Erg #$ergId' : '$manufacturer Erg';
    }
  }

  String _shellTypeDisplay(ShellType? type) {
    if (type == null) return 'Shell';
    switch (type) {
      case ShellType.eight:
        return '8+';
      case ShellType.coxedFour:
        return '4+';
      case ShellType.four:
        return '4-';
      case ShellType.quad:
        return '4x';
      case ShellType.coxedQuad:
        return '4x+';
      case ShellType.pair:
        return '2-';
      case ShellType.double:
        return '2x';
      case ShellType.single:
        return '1x';
    }
  }

  String _oarTypeDisplay(OarType? type) {
    if (type == null) return '';
    return type == OarType.sweep ? 'Sweep' : 'Scull';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'type': type.name,
      'name': name,
      'manufacturer': manufacturer,
      'model': model,
      'year': year,
      'serialNumber': serialNumber,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'purchasePrice': purchasePrice,
      'notes': notes,
      'availableToAllTeams': availableToAllTeams,
      'assignedTeamIds': assignedTeamIds,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
      'shellType': shellType?.name,
      'riggingType': riggingType?.name,
      'currentRiggingSetup': currentRiggingSetup,
      'riggingSetup': riggingSetup?.toMap(),
      'activeShellType': activeShellType?.name,
      'oarType': oarType?.name,
      'oarCount': oarCount,
      'bladeType': bladeType,
      'oarLength': oarLength,
      'microphoneIncluded': microphoneIncluded,
      'batteryStatus': batteryStatus,
      'gasTankAssigned': gasTankAssigned,
      'tankNumber': tankNumber,
      'fuelType': fuelType,
      'ergId': ergId,
      'isDamaged': isDamaged,
      'damageReports': damageReports.map((r) => r.toMap()).toList(),
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] ?? '',
      organizationId: map['organizationId'] ?? '',
      type: EquipmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EquipmentType.shell,
      ),
      name: map['name'],
      manufacturer: map['manufacturer'] ?? '',
      model: map['model'],
      year: map['year'],
      serialNumber: map['serialNumber'],
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.parse(map['purchaseDate'])
          : null,
      purchasePrice: map['purchasePrice']?.toDouble(),
      notes: map['notes'],
      availableToAllTeams: map['availableToAllTeams'] ?? false,
      assignedTeamIds: List<String>.from(map['assignedTeamIds'] ?? []),
      status: EquipmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EquipmentStatus.available,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      lastMaintenanceDate: map['lastMaintenanceDate'] != null
          ? DateTime.parse(map['lastMaintenanceDate'])
          : null,
      shellType: map['shellType'] != null
          ? ShellType.values.firstWhere((e) => e.name == map['shellType'])
          : null,
      riggingType: map['riggingType'] != null
          ? RiggingType.values.firstWhere((e) => e.name == map['riggingType'])
          : null,
      currentRiggingSetup: map['currentRiggingSetup'],
      riggingSetup: map['riggingSetup'] != null
          ? RiggingSetup.fromMap(map['riggingSetup'])
          : null,
      activeShellType: map['activeShellType'] != null
          ? ShellType.values.firstWhere((e) => e.name == map['activeShellType'])
          : null,
      oarType: map['oarType'] != null
          ? OarType.values.firstWhere((e) => e.name == map['oarType'])
          : null,
      oarCount: map['oarCount'],
      bladeType: map['bladeType'],
      oarLength: map['oarLength']?.toDouble(),
      microphoneIncluded: map['microphoneIncluded'],
      batteryStatus: map['batteryStatus'],
      gasTankAssigned: map['gasTankAssigned'],
      tankNumber: map['tankNumber'],
      fuelType: map['fuelType'],
      ergId: map['ergId'],
      isDamaged: map['isDamaged'] ?? false,
      damageReports:
          (map['damageReports'] as List<dynamic>?)
              ?.map((r) => DamageReport.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Equipment copyWith({
    String? id,
    String? organizationId,
    EquipmentType? type,
    String? name,
    String? manufacturer,
    String? model,
    int? year,
    String? serialNumber,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? notes,
    bool? availableToAllTeams,
    List<String>? assignedTeamIds,
    EquipmentStatus? status,
    DateTime? createdAt,
    DateTime? lastMaintenanceDate,
    ShellType? shellType,
    RiggingType? riggingType,
    String? currentRiggingSetup,
    RiggingSetup? riggingSetup,
    ShellType? activeShellType,
    OarType? oarType,
    int? oarCount,
    String? bladeType,
    double? oarLength,
    bool? microphoneIncluded,
    String? batteryStatus,
    bool? gasTankAssigned,
    String? tankNumber,
    String? fuelType,
    String? ergId,
    bool? isDamaged,
    List<DamageReport>? damageReports,
  }) {
    return Equipment(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      type: type ?? this.type,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      year: year ?? this.year,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      notes: notes ?? this.notes,
      availableToAllTeams: availableToAllTeams ?? this.availableToAllTeams,
      assignedTeamIds: assignedTeamIds ?? this.assignedTeamIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      shellType: shellType ?? this.shellType,
      riggingType: riggingType ?? this.riggingType,
      currentRiggingSetup: currentRiggingSetup ?? this.currentRiggingSetup,
      riggingSetup: riggingSetup ?? this.riggingSetup,
      activeShellType: activeShellType ?? this.activeShellType,
      oarType: oarType ?? this.oarType,
      oarCount: oarCount ?? this.oarCount,
      bladeType: bladeType ?? this.bladeType,
      oarLength: oarLength ?? this.oarLength,
      microphoneIncluded: microphoneIncluded ?? this.microphoneIncluded,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      gasTankAssigned: gasTankAssigned ?? this.gasTankAssigned,
      tankNumber: tankNumber ?? this.tankNumber,
      fuelType: fuelType ?? this.fuelType,
      ergId: ergId ?? this.ergId,
      isDamaged: isDamaged ?? this.isDamaged,
      damageReports: damageReports ?? this.damageReports,
    );
  }
}

class DamageReport {
  final String id;
  final String reportedBy;
  final String reportedByName;
  final DateTime reportedAt;
  final String description;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;

  DamageReport({
    required this.id,
    required this.reportedBy,
    required this.reportedByName,
    required this.reportedAt,
    required this.description,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'reportedAt': reportedAt.toIso8601String(),
      'description': description,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
      'resolutionNotes': resolutionNotes,
    };
  }

  factory DamageReport.fromMap(Map<String, dynamic> map) {
    return DamageReport(
      id: map['id'] ?? '',
      reportedBy: map['reportedBy'] ?? '',
      reportedByName: map['reportedByName'] ?? '',
      reportedAt: DateTime.parse(map['reportedAt']),
      description: map['description'] ?? '',
      isResolved: map['isResolved'] ?? false,
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.parse(map['resolvedAt'])
          : null,
      resolvedBy: map['resolvedBy'],
      resolutionNotes: map['resolutionNotes'],
    );
  }

  DamageReport copyWith({
    String? id,
    String? reportedBy,
    String? reportedByName,
    DateTime? reportedAt,
    String? description,
    bool? isResolved,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? resolutionNotes,
  }) {
    return DamageReport(
      id: id ?? this.id,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      reportedAt: reportedAt ?? this.reportedAt,
      description: description ?? this.description,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }
}
