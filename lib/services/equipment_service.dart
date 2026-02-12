import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'equipment';

  // ── Queries ─────────────────────────────────────────────

  Stream<List<Equipment>> getEquipmentByType(
    String organizationId,
    EquipmentType type, {
    String? teamId,
  }) {
    return _firestore
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .where('type', isEqualTo: type.name)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          final allEquipment = snapshot.docs
              .map((doc) => Equipment.fromMap(doc.data()))
              .toList();
          if (teamId == null || teamId.isEmpty) return allEquipment;
          return allEquipment
              .where(
                (e) =>
                    e.availableToAllTeams || e.assignedTeamIds.contains(teamId),
              )
              .toList();
        });
  }

  Stream<List<Equipment>> getEquipmentByTeam(String organizationId) {
    return _firestore
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Equipment.fromMap(doc.data()))
              .toList();
        });
  }

  /// Stream equipment that needs attention (damaged or under maintenance).
  Stream<List<Equipment>> getNeedsAttention(String organizationId) {
    return getEquipmentByTeam(
      organizationId,
    ).map((list) => list.where((e) => e.needsAttention).toList());
  }

  Future<Equipment?> getEquipment(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get();
      if (doc.exists) {
        return Equipment.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error getting equipment: $e';
    }
  }

  // ── CRUD ────────────────────────────────────────────────

  Future<void> addEquipment(Equipment equipment) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final equipmentWithId = equipment.copyWith(id: docRef.id);
      await docRef.set(equipmentWithId.toMap());
    } catch (e) {
      throw 'Error adding equipment: $e';
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(equipment.id)
          .update(equipment.toMap());
    } catch (e) {
      throw 'Error updating equipment: $e';
    }
  }

  Future<void> deleteEquipment(String equipmentId) async {
    try {
      await _firestore.collection(_collection).doc(equipmentId).delete();
    } catch (e) {
      throw 'Error deleting equipment: $e';
    }
  }

  // ── Rigging ─────────────────────────────────────────────

  Future<void> updateRiggingSetup(
    String equipmentId,
    RiggingSetup setup,
  ) async {
    try {
      await _firestore.collection(_collection).doc(equipmentId).update({
        'riggingSetup': setup.toMap(),
      });
    } catch (e) {
      throw 'Error updating rigging setup: $e';
    }
  }

  Future<void> switchDualRigConfig(
    String equipmentId,
    ShellType targetShellType,
  ) async {
    try {
      await _firestore.collection(_collection).doc(equipmentId).update({
        'activeShellType': targetShellType.name,
      });
    } catch (e) {
      throw 'Error switching dual-rig config: $e';
    }
  }

  Future<void> resetDualRigConfig(String equipmentId) async {
    try {
      await _firestore.collection(_collection).doc(equipmentId).update({
        'activeShellType': FieldValue.delete(),
      });
    } catch (e) {
      throw 'Error resetting dual-rig config: $e';
    }
  }

  // ── Damage Reports ──────────────────────────────────────

  Future<void> addDamageReport(String equipmentId, DamageReport report) async {
    try {
      final equipment = await getEquipment(equipmentId);
      if (equipment != null) {
        final updatedReports = [...equipment.damageReports, report];
        final updatedEquipment = equipment.copyWith(
          damageReports: updatedReports,
          isDamaged: true,
          status: EquipmentStatus.damaged,
        );
        await updateEquipment(updatedEquipment);
      }
    } catch (e) {
      throw 'Error adding damage report: $e';
    }
  }

  Future<void> resolveDamageReport(
    String equipmentId,
    String reportId,
    String resolvedBy,
    String? resolutionNotes,
  ) async {
    try {
      final equipment = await getEquipment(equipmentId);
      if (equipment != null) {
        final updatedReports = equipment.damageReports.map((report) {
          if (report.id == reportId) {
            return report.copyWith(
              isResolved: true,
              resolvedAt: DateTime.now(),
              resolvedBy: resolvedBy,
              resolutionNotes: resolutionNotes,
            );
          }
          return report;
        }).toList();

        final allResolved = updatedReports.every((r) => r.isResolved);

        final updatedEquipment = equipment.copyWith(
          damageReports: updatedReports,
          isDamaged: !allResolved,
          status: allResolved
              ? EquipmentStatus.available
              : EquipmentStatus.damaged,
        );
        await updateEquipment(updatedEquipment);
      }
    } catch (e) {
      throw 'Error resolving damage report: $e';
    }
  }

  // ── Maintenance Workflow ────────────────────────────────

  /// Move equipment from "damaged" to "maintenance" status.
  /// Creates a status_change MaintenanceEntry and optionally links
  /// the unresolved damage reports it's addressing.
  Future<void> startMaintenance({
    required String equipmentId,
    required String authorId,
    required String authorName,
    required String notes,
    List<String>? damageReportIds,
  }) async {
    try {
      final equipment = await getEquipment(equipmentId);
      if (equipment == null) throw 'Equipment not found';

      // Determine which damage reports to link
      final linkedIds =
          damageReportIds ??
          equipment.unresolvedDamageReports.map((r) => r.id).toList();

      final entry = MaintenanceEntry(
        id: const Uuid().v4(),
        type: MaintenanceEntryType.statusChange,
        authorId: authorId,
        authorName: authorName,
        createdAt: DateTime.now(),
        notes: notes,
        newStatus: EquipmentStatus.maintenance,
        linkedDamageReportIds: linkedIds,
      );

      final updatedLog = [...equipment.maintenanceLog, entry];
      final updatedEquipment = equipment.copyWith(
        status: EquipmentStatus.maintenance,
        maintenanceLog: updatedLog,
        lastMaintenanceDate: DateTime.now(),
      );
      await updateEquipment(updatedEquipment);
    } catch (e) {
      throw 'Error starting maintenance: $e';
    }
  }

  /// Add a progress update to the maintenance log.
  Future<void> addMaintenanceUpdate({
    required String equipmentId,
    required String authorId,
    required String authorName,
    required String notes,
  }) async {
    try {
      final equipment = await getEquipment(equipmentId);
      if (equipment == null) throw 'Equipment not found';

      final entry = MaintenanceEntry(
        id: const Uuid().v4(),
        type: MaintenanceEntryType.progressUpdate,
        authorId: authorId,
        authorName: authorName,
        createdAt: DateTime.now(),
        notes: notes,
      );

      final updatedLog = [...equipment.maintenanceLog, entry];
      final updatedEquipment = equipment.copyWith(
        maintenanceLog: updatedLog,
        lastMaintenanceDate: DateTime.now(),
      );
      await updateEquipment(updatedEquipment);
    } catch (e) {
      throw 'Error adding maintenance update: $e';
    }
  }

  /// Complete maintenance — resolves all linked damage reports,
  /// sets status back to available, and logs a resolution entry.
  Future<void> completeMaintenance({
    required String equipmentId,
    required String authorId,
    required String authorName,
    required String notes,
  }) async {
    try {
      final equipment = await getEquipment(equipmentId);
      if (equipment == null) throw 'Equipment not found';

      // Create resolution entry
      final entry = MaintenanceEntry(
        id: const Uuid().v4(),
        type: MaintenanceEntryType.resolution,
        authorId: authorId,
        authorName: authorName,
        createdAt: DateTime.now(),
        notes: notes,
        newStatus: EquipmentStatus.available,
        linkedDamageReportIds: equipment.unresolvedDamageReports
            .map((r) => r.id)
            .toList(),
      );

      // Resolve all unresolved damage reports
      final updatedDamageReports = equipment.damageReports.map((report) {
        if (!report.isResolved) {
          return report.copyWith(
            isResolved: true,
            resolvedAt: DateTime.now(),
            resolvedBy: authorId,
            resolutionNotes: 'Resolved via maintenance: $notes',
          );
        }
        return report;
      }).toList();

      final updatedLog = [...equipment.maintenanceLog, entry];
      final updatedEquipment = equipment.copyWith(
        status: EquipmentStatus.available,
        isDamaged: false,
        damageReports: updatedDamageReports,
        maintenanceLog: updatedLog,
        lastMaintenanceDate: DateTime.now(),
      );
      await updateEquipment(updatedEquipment);
    } catch (e) {
      throw 'Error completing maintenance: $e';
    }
  }

  // ── Coxbox / SpeedCoach Assignment ─────────────────────

  /// Assign a coxbox to a coxswain (by userId) or
  /// a speedcoach to a shell (by equipmentId).
  Future<void> assignCoxbox({
    required String equipmentId,
    required String assignedToId,
    required String assignedToName,
  }) async {
    try {
      await _firestore.collection(_collection).doc(equipmentId).update({
        'assignedToId': assignedToId,
        'assignedToName': assignedToName,
      });
    } catch (e) {
      throw 'Error assigning coxbox: $e';
    }
  }

  /// Remove coxbox/speedcoach assignment.
  Future<void> unassignCoxbox(String equipmentId) async {
    try {
      await _firestore.collection(_collection).doc(equipmentId).update({
        'assignedToId': null,
        'assignedToName': null,
      });
    } catch (e) {
      throw 'Error unassigning coxbox: $e';
    }
  }
}
