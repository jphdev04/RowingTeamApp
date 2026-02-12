import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'equipment';

  // Get equipment by type (accessible to a specific team)
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

          // If no team filter, return all org equipment
          if (teamId == null || teamId.isEmpty) return allEquipment;

          // Filter to equipment this team can access
          return allEquipment
              .where(
                (e) =>
                    e.availableToAllTeams || e.assignedTeamIds.contains(teamId),
              )
              .toList();
        });
  }

  // Get all equipment for an organization
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

  // Get single equipment
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

  // Add equipment
  Future<void> addEquipment(Equipment equipment) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final equipmentWithId = equipment.copyWith(id: docRef.id);
      await docRef.set(equipmentWithId.toMap());
    } catch (e) {
      throw 'Error adding equipment: $e';
    }
  }

  // Update equipment
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

  // Delete equipment
  Future<void> deleteEquipment(String equipmentId) async {
    try {
      await _firestore.collection(_collection).doc(equipmentId).delete();
    } catch (e) {
      throw 'Error deleting equipment: $e';
    }
  }

  // ── Rigging ─────────────────────────────────────────────

  /// Update a shell's rigging setup.
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

  /// Switch a dual-rigged shell's active configuration.
  /// Changes the activeShellType to the target shell type.
  Future<void> switchDualRigConfig(
    String equipmentId,
    ShellType targetShellType,
  ) async {
    try {
      await _firestore.collection(_collection).doc(equipmentId).update({
        'activeShellType': targetShellType.name,
        // Clear rigging setup when switching — user should set new rig
        // (sweep→scull means rigging doesn't apply; scull→sweep needs new rig)
      });
    } catch (e) {
      throw 'Error switching dual-rig config: $e';
    }
  }

  /// Clear the active shell type override (revert to base shellType).
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

  // Add damage report
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

  // Resolve damage report
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
}
