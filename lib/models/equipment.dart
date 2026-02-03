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

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;

    switch (type) {
      case EquipmentType.shell:
        return '${manufacturer} ${_shellTypeDisplay(shellType)}';
      case EquipmentType.oar:
        return '${manufacturer} ${_oarTypeDisplay(oarType)} Oars';
      case EquipmentType.coxbox:
        return '${manufacturer} Coxbox';
      case EquipmentType.launch:
        return '${manufacturer} Launch';
      case EquipmentType.erg:
        return ergId != null ? 'Erg #$ergId' : '${manufacturer} Erg';
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
