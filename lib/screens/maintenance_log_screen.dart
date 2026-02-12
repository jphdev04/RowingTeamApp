import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import '../models/team.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';

class MaintenanceLogScreen extends StatefulWidget {
  final String equipmentId;
  final String organizationId;
  final String userId;
  final String userName;
  final Organization? organization;
  final Team? team;

  const MaintenanceLogScreen({
    super.key,
    required this.equipmentId,
    required this.organizationId,
    required this.userId,
    required this.userName,
    this.organization,
    this.team,
  });

  @override
  State<MaintenanceLogScreen> createState() => _MaintenanceLogScreenState();
}

class _MaintenanceLogScreenState extends State<MaintenanceLogScreen> {
  final _equipmentService = EquipmentService();
  final _notesController = TextEditingController();

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization?.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════

  void _showActionSheet(Equipment equipment) {
    final actions = <Widget>[];

    if (equipment.status == EquipmentStatus.damaged) {
      actions.add(
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.build, color: Colors.orange),
          ),
          title: const Text('Start Maintenance'),
          subtitle: const Text('Move to under maintenance'),
          onTap: () {
            Navigator.pop(context);
            _showNotesDialog(
              title: 'Start Maintenance',
              hint: 'What work will be done?',
              buttonLabel: 'Start Maintenance',
              buttonColor: Colors.orange,
              onSubmit: (notes) => _startMaintenance(equipment, notes),
            );
          },
        ),
      );
    }

    if (equipment.status == EquipmentStatus.maintenance) {
      actions.add(
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.update, color: Colors.blue),
          ),
          title: const Text('Add Progress Update'),
          subtitle: const Text('Log what was done'),
          onTap: () {
            Navigator.pop(context);
            _showNotesDialog(
              title: 'Progress Update',
              hint: 'What progress was made?',
              buttonLabel: 'Add Update',
              buttonColor: Colors.blue,
              onSubmit: (notes) => _addProgressUpdate(equipment, notes),
            );
          },
        ),
      );
      actions.add(
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green),
          ),
          title: const Text('Complete Repair'),
          subtitle: const Text('Mark as fixed and available'),
          onTap: () {
            Navigator.pop(context);
            _showNotesDialog(
              title: 'Complete Repair',
              hint: 'Summary of what was repaired',
              buttonLabel: 'Mark Complete',
              buttonColor: Colors.green,
              onSubmit: (notes) => _completeMaintenance(equipment, notes),
            );
          },
        ),
      );
    }

    // Always allow adding a note even if available (for general maintenance log)
    if (equipment.status == EquipmentStatus.available ||
        equipment.status == EquipmentStatus.inUse) {
      actions.add(
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.note_add, color: Colors.grey[600]),
          ),
          title: const Text('Add Maintenance Note'),
          subtitle: const Text('Log routine maintenance'),
          onTap: () {
            Navigator.pop(context);
            _showNotesDialog(
              title: 'Maintenance Note',
              hint: 'e.g., Oiled slide tracks, checked rigger bolts',
              buttonLabel: 'Add Note',
              buttonColor: primaryColor,
              onSubmit: (notes) => _addProgressUpdate(equipment, notes),
            );
          },
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...actions,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showNotesDialog({
    required String title,
    required String hint,
    required String buttonLabel,
    required Color buttonColor,
    required Future<void> Function(String notes) onSubmit,
  }) {
    _notesController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BoathouseStyles.textField(
              primaryColor: primaryColor,
              controller: _notesController,
              hintText: hint,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please add notes' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final notes = _notesController.text.trim();
                if (notes.isEmpty) return;
                Navigator.pop(ctx);
                await onSubmit(notes);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMaintenance(Equipment equipment, String notes) async {
    try {
      await _equipmentService.startMaintenance(
        equipmentId: equipment.id,
        authorId: widget.userId,
        authorName: widget.userName,
        notes: notes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment moved to maintenance'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addProgressUpdate(Equipment equipment, String notes) async {
    try {
      await _equipmentService.addMaintenanceUpdate(
        equipmentId: equipment.id,
        authorId: widget.userId,
        authorName: widget.userName,
        notes: notes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress update added'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _completeMaintenance(Equipment equipment, String notes) async {
    try {
      await _equipmentService.completeMaintenance(
        equipmentId: equipment.id,
        authorId: widget.userId,
        authorName: widget.userName,
        notes: notes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repair complete — equipment available!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TeamHeader(
            team: widget.team,
            organization: widget.organization,
            title: 'Maintenance Log',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: _onPrimary,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Equipment>>(
              stream: _equipmentService.getEquipmentByTeam(
                widget.organizationId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final equipment = snapshot.data
                    ?.where((e) => e.id == widget.equipmentId)
                    .firstOrNull;

                if (equipment == null) {
                  return const Center(child: Text('Equipment not found'));
                }

                return _buildContent(equipment);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<List<Equipment>>(
        stream: _equipmentService.getEquipmentByTeam(widget.organizationId),
        builder: (context, snapshot) {
          final equipment = snapshot.data
              ?.where((e) => e.id == widget.equipmentId)
              .firstOrNull;
          if (equipment == null) return const SizedBox();

          return FloatingActionButton.extended(
            onPressed: () => _showActionSheet(equipment),
            backgroundColor: _getStatusColor(equipment.status),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(_getFabLabel(equipment.status)),
          );
        },
      ),
    );
  }

  Widget _buildContent(Equipment equipment) {
    // Build unified timeline: damage reports + maintenance entries
    final timelineItems = <_TimelineItem>[];

    // Add damage reports
    for (final report in equipment.damageReports) {
      timelineItems.add(
        _TimelineItem(
          timestamp: report.reportedAt,
          type: _TimelineType.damageReport,
          title: 'Damage Reported',
          subtitle: 'by ${report.reportedByName}',
          description: report.description,
          isResolved: report.isResolved,
          resolvedAt: report.resolvedAt,
          id: report.id,
        ),
      );
    }

    // Add maintenance entries
    for (final entry in equipment.maintenanceLog) {
      _TimelineType type;
      String title;
      switch (entry.type) {
        case MaintenanceEntryType.statusChange:
          type = _TimelineType.statusChange;
          title = entry.newStatus == EquipmentStatus.maintenance
              ? 'Moved to Maintenance'
              : 'Status Changed';
          break;
        case MaintenanceEntryType.progressUpdate:
          type = _TimelineType.progressUpdate;
          title = 'Progress Update';
          break;
        case MaintenanceEntryType.resolution:
          type = _TimelineType.resolution;
          title = 'Repair Complete';
          break;
      }

      timelineItems.add(
        _TimelineItem(
          timestamp: entry.createdAt,
          type: type,
          title: title,
          subtitle: 'by ${entry.authorName}',
          description: entry.notes,
          id: entry.id,
        ),
      );
    }

    // Sort by timestamp (newest first)
    timelineItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: [
        // Equipment status banner
        _buildStatusBanner(equipment),

        // Timeline
        Expanded(
          child: timelineItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No maintenance history',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Damage reports and maintenance updates\nwill appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: timelineItems.length,
                  itemBuilder: (context, index) {
                    final item = timelineItems[index];
                    final isLast = index == timelineItems.length - 1;
                    return _buildTimelineEntry(item, isLast);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(Equipment equipment) {
    final statusColor = _getStatusColor(equipment.status);
    final statusText = _getStatusText(equipment.status);
    final unresolvedCount = equipment.unresolvedDamageReports.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStatusIcon(equipment.status),
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (unresolvedCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '$unresolvedCount open ${unresolvedCount == 1 ? 'report' : 'reports'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEntry(_TimelineItem item, bool isLast) {
    final color = _getTimelineColor(item.type);
    final icon = _getTimelineIcon(item.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[200])),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      if (item.isResolved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Resolved',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.subtitle} · ${_formatTimestamp(item.timestamp)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

  Color _getStatusColor(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return Colors.green;
      case EquipmentStatus.inUse:
        return Colors.blue;
      case EquipmentStatus.damaged:
        return Colors.red;
      case EquipmentStatus.maintenance:
        return Colors.orange;
    }
  }

  String _getStatusText(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return 'Available';
      case EquipmentStatus.inUse:
        return 'In Use';
      case EquipmentStatus.damaged:
        return 'Damaged';
      case EquipmentStatus.maintenance:
        return 'Under Maintenance';
    }
  }

  IconData _getStatusIcon(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return Icons.check_circle;
      case EquipmentStatus.inUse:
        return Icons.timelapse;
      case EquipmentStatus.damaged:
        return Icons.warning_amber_rounded;
      case EquipmentStatus.maintenance:
        return Icons.build;
    }
  }

  String _getFabLabel(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.damaged:
        return 'Start Repair';
      case EquipmentStatus.maintenance:
        return 'Update';
      default:
        return 'Add Note';
    }
  }

  Color _getTimelineColor(_TimelineType type) {
    switch (type) {
      case _TimelineType.damageReport:
        return Colors.red;
      case _TimelineType.statusChange:
        return Colors.orange;
      case _TimelineType.progressUpdate:
        return Colors.blue;
      case _TimelineType.resolution:
        return Colors.green;
    }
  }

  IconData _getTimelineIcon(_TimelineType type) {
    switch (type) {
      case _TimelineType.damageReport:
        return Icons.warning_amber_rounded;
      case _TimelineType.statusChange:
        return Icons.swap_horiz;
      case _TimelineType.progressUpdate:
        return Icons.build;
      case _TimelineType.resolution:
        return Icons.check_circle;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ════════════════════════════════════════════════════════════
// TIMELINE DATA
// ════════════════════════════════════════════════════════════

enum _TimelineType { damageReport, statusChange, progressUpdate, resolution }

class _TimelineItem {
  final DateTime timestamp;
  final _TimelineType type;
  final String title;
  final String subtitle;
  final String description;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String id;

  _TimelineItem({
    required this.timestamp,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    this.isResolved = false,
    this.resolvedAt,
    required this.id,
  });
}
