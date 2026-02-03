import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'equipment';

  // Get all equipment for a team
  Stream<List<Equipment>> getEquipmentByTeam(String teamId) {
    return _firestore
        .collection(_collection)
        .where('teamId', isEqualTo: teamId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Equipment.fromMap(doc.data()))
              .toList();
        });
  }

  // Get equipment by type
  Stream<List<Equipment>> getEquipmentByType(
    String teamId,
    EquipmentType type,
  ) {
    return _firestore
        .collection(_collection)
        .where('teamId', isEqualTo: teamId)
        .where('type', isEqualTo: type.name)
        .orderBy('name')
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
      final docRef = _firestore.collection(_collection).doc(); // Generate ID
      final equipmentWithId = equipment.copyWith(id: docRef.id); // Set the ID
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
  Future<void> deleteEquipment(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw 'Error deleting equipment: $e';
    }
  }

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

        // Check if all reports are resolved
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
