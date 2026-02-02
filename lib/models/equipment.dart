enum EquipmentType { shell, oar, coxbox, launch, erg }

enum ShellType {
  eight, // 8+
  four, // 4+ or 4x
  quad, // 4x
  double, // 2x
  single, // 1x
  pair, // 2-
}

enum OarType {
  sweep, // Sweeping oars
  scull, // Sculling oars
}

enum ErgType {
  rowErg, // Concept2 RowErg
  bikeErg, // Concept2 BikeErg
  rp3, // RowPerfect RP3
}

enum EquipmentStatus { available, inUse, damaged, maintenance }

class Equipment {
  final String id;
  final String organizationId; // NEW - equipment belongs to org, not team
  final EquipmentType type;
  final String name; // e.g., "Resolute", "Launch 1", "Cox Box A"
  final EquipmentStatus status;
  final DateTime createdAt;
  final DateTime? lastMaintenanceDate;
  final String? notes;

  // Shell-specific fields
  final ShellType? shellType;
  final int? seatCount; // For shells
  final String? manufacturer; // e.g., "Vespoli", "Empacher"
  final int? year;

  // Oar-specific fields
  final OarType? oarType;
  final int? oarCount; // Number of oars in the set (2, 4, 8)
  final double? oarLength; // in cm

  // Erg-specific fields
  final ErgType? ergType;
  final String? serialNumber;
  final String? model; // e.g., "Model D", "RP3 Dynamic"

  // Damage tracking
  final bool isDamaged;
  final List<DamageReport> damageReports;

  Equipment({
    required this.id,
    required this.organizationId,
    required this.type,
    required this.name,
    this.status = EquipmentStatus.available,
    required this.createdAt,
    this.lastMaintenanceDate,
    this.notes,
    this.shellType,
    this.seatCount,
    this.manufacturer,
    this.year,
    this.oarType,
    this.oarCount,
    this.oarLength,
    this.ergType,
    this.serialNumber,
    this.model,
    this.isDamaged = false,
    this.damageReports = const [],
  });

  String get displayName {
    switch (type) {
      case EquipmentType.shell:
        return '$name (${_getShellDisplayName()})';
      case EquipmentType.oar:
        return '$name (${oarCount ?? 0} ${oarType?.name ?? ''} oars)';
      case EquipmentType.erg:
        return '$name (${ergType?.name ?? 'Erg'})';
      default:
        return name;
    }
  }

  String _getShellDisplayName() {
    switch (shellType) {
      case ShellType.eight:
        return '8+';
      case ShellType.four:
        return '4+/4x';
      case ShellType.quad:
        return '4x';
      case ShellType.double:
        return '2x';
      case ShellType.single:
        return '1x';
      case ShellType.pair:
        return '2-';
      default:
        return '';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'type': type.name,
      'name': name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
      'notes': notes,
      'shellType': shellType?.name,
      'seatCount': seatCount,
      'manufacturer': manufacturer,
      'year': year,
      'oarType': oarType?.name,
      'oarCount': oarCount,
      'oarLength': oarLength,
      'ergType': ergType?.name,
      'serialNumber': serialNumber,
      'model': model,
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
      name: map['name'] ?? '',
      status: EquipmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EquipmentStatus.available,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      lastMaintenanceDate: map['lastMaintenanceDate'] != null
          ? DateTime.parse(map['lastMaintenanceDate'])
          : null,
      notes: map['notes'],
      shellType: map['shellType'] != null
          ? ShellType.values.firstWhere((e) => e.name == map['shellType'])
          : null,
      seatCount: map['seatCount'],
      manufacturer: map['manufacturer'],
      year: map['year'],
      oarType: map['oarType'] != null
          ? OarType.values.firstWhere((e) => e.name == map['oarType'])
          : null,
      oarCount: map['oarCount'],
      oarLength: map['oarLength']?.toDouble(),
      ergType: map['ergType'] != null
          ? ErgType.values.firstWhere((e) => e.name == map['ergType'])
          : null,
      serialNumber: map['serialNumber'],
      model: map['model'],
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
    EquipmentStatus? status,
    DateTime? createdAt,
    DateTime? lastMaintenanceDate,
    String? notes,
    ShellType? shellType,
    int? seatCount,
    String? manufacturer,
    int? year,
    OarType? oarType,
    int? oarCount,
    double? oarLength,
    ErgType? ergType,
    String? serialNumber,
    String? model,
    bool? isDamaged,
    List<DamageReport>? damageReports,
  }) {
    return Equipment(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      type: type ?? this.type,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      notes: notes ?? this.notes,
      shellType: shellType ?? this.shellType,
      seatCount: seatCount ?? this.seatCount,
      manufacturer: manufacturer ?? this.manufacturer,
      year: year ?? this.year,
      oarType: oarType ?? this.oarType,
      oarCount: oarCount ?? this.oarCount,
      oarLength: oarLength ?? this.oarLength,
      ergType: ergType ?? this.ergType,
      serialNumber: serialNumber ?? this.serialNumber,
      model: model ?? this.model,
      isDamaged: isDamaged ?? this.isDamaged,
      damageReports: damageReports ?? this.damageReports,
    );
  }
}

class DamageReport {
  final String id;
  final String reportedBy; // Athlete ID
  final String reportedByName; // Athlete name for display
  final DateTime reportedAt;
  final String description;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy; // Coach ID who marked as resolved
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
