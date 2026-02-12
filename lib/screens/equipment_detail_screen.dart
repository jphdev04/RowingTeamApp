import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/team.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';
import '../services/team_service.dart';
import '../services/organization_service.dart';
import '../widgets/team_header.dart';
import 'edit_equipment_screen.dart';
import 'rigging_editor_screen.dart';

class EquipmentDetailScreen extends StatelessWidget {
  final String equipmentId;
  final String organizationId;
  final Team? team;
  final AppUser? user;
  final Membership? currentMembership;

  const EquipmentDetailScreen({
    super.key,
    required this.equipmentId,
    required this.organizationId,
    this.team,
    this.user,
    this.currentMembership,
  });

  @override
  Widget build(BuildContext context) {
    final equipmentService = EquipmentService();
    final orgService = OrganizationService();
    final teamService = TeamService();

    return FutureBuilder<Organization?>(
      future: orgService.getOrganization(organizationId),
      builder: (context, orgSnapshot) {
        final organization = orgSnapshot.data;

        return StreamBuilder<List<Equipment>>(
          stream: equipmentService.getEquipmentByTeam(organizationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final equipment = snapshot.data?.firstWhere(
              (e) => e.id == equipmentId,
              orElse: () => throw 'Equipment not found',
            );

            if (equipment == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Equipment Not Found')),
                body: const Center(child: Text('Equipment not found')),
              );
            }

            return _EquipmentDetailContent(
              equipment: equipment,
              organization: organization,
              team: team,
              teamService: teamService,
              user: user,
              currentMembership: currentMembership,
            );
          },
        );
      },
    );
  }
}

class _EquipmentDetailContent extends StatelessWidget {
  final Equipment equipment;
  final Organization? organization;
  final TeamService teamService;
  final Team? team;
  final AppUser? user;
  final Membership? currentMembership;

  const _EquipmentDetailContent({
    required this.equipment,
    required this.organization,
    required this.teamService,
    this.team,
    this.user,
    this.currentMembership,
  });

  Color _getStatusColor() {
    switch (equipment.status) {
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

  String _getStatusText() {
    switch (equipment.status) {
      case EquipmentStatus.available:
        return 'Available';
      case EquipmentStatus.inUse:
        return 'In Use';
      case EquipmentStatus.damaged:
        return 'Damaged';
      case EquipmentStatus.maintenance:
        return 'Maintenance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 16,
              24,
              24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  team?.primaryColorObj ??
                      organization?.primaryColorObj ??
                      const Color(0xFF1976D2),
                  team?.secondaryColorObj ??
                      organization?.secondaryColorObj ??
                      (team?.primaryColorObj ??
                              organization?.primaryColorObj ??
                              const Color(0xFF1976D2))
                          .withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditEquipmentScreen(
                              equipment: equipment,
                              organizationId: equipment.organizationId,
                              organization: organization,
                              team: team,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  equipment.displayName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info Card
                  _InfoCard(
                    title: 'Basic Information',
                    children: [
                      _InfoRow(
                        label: 'Manufacturer',
                        value: equipment.manufacturer,
                      ),
                      if (equipment.model != null)
                        _InfoRow(label: 'Model', value: equipment.model!),
                      if (equipment.year != null)
                        _InfoRow(
                          label: 'Year',
                          value: equipment.year.toString(),
                        ),
                      if (equipment.serialNumber != null)
                        _InfoRow(
                          label: 'Serial Number',
                          value: equipment.serialNumber!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Type-Specific Info
                  if (_hasTypeSpecificInfo())
                    _InfoCard(
                      title: _getTypeSpecificTitle(),
                      children: _buildTypeSpecificInfo(),
                    ),

                  // ── Rigging Card (shells only) ──
                  if (equipment.type == EquipmentType.shell &&
                      equipment.isSweepConfig) ...[
                    const SizedBox(height: 16),
                    _buildRiggingCard(context),
                  ],

                  const SizedBox(height: 16),

                  // Purchase Info
                  if (equipment.purchaseDate != null ||
                      equipment.purchasePrice != null)
                    _InfoCard(
                      title: 'Purchase Information',
                      children: [
                        if (equipment.purchaseDate != null)
                          _InfoRow(
                            label: 'Purchase Date',
                            value: DateFormat(
                              'MM/dd/yyyy',
                            ).format(equipment.purchaseDate!),
                          ),
                        if (equipment.purchasePrice != null)
                          _InfoRow(
                            label: 'Purchase Price',
                            value:
                                '\$${equipment.purchasePrice!.toStringAsFixed(2)}',
                          ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Team Assignment
                  _InfoCard(
                    title: 'Team Assignment',
                    children: [
                      if (equipment.availableToAllTeams)
                        const _InfoRow(
                          label: 'Available To',
                          value: 'All Teams',
                        )
                      else if (equipment.assignedTeamIds.isNotEmpty)
                        _TeamsList(
                          teamIds: equipment.assignedTeamIds,
                          teamService: teamService,
                        )
                      else
                        const _InfoRow(
                          label: 'Available To',
                          value: 'No teams assigned',
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  if (equipment.notes != null && equipment.notes!.isNotEmpty)
                    _InfoCard(
                      title: 'Notes',
                      children: [
                        Text(
                          equipment.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Damage Reports
                  if (equipment.isDamaged && equipment.damageReports.isNotEmpty)
                    _DamageReportsCard(
                      damageReports: equipment.damageReports
                          .where((r) => !r.isResolved)
                          .toList(),
                    ),

                  const SizedBox(height: 16),

                  // Maintenance History
                  if (equipment.lastMaintenanceDate != null)
                    _InfoCard(
                      title: 'Maintenance',
                      children: [
                        _InfoRow(
                          label: 'Last Maintenance',
                          value: DateFormat(
                            'MM/dd/yyyy',
                          ).format(equipment.lastMaintenanceDate!),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rigging info card with Edit button ──

  Widget _buildRiggingCard(BuildContext context) {
    final rig = equipment.effectiveRiggingSetup;
    final primaryColor =
        team?.primaryColorObj ??
        organization?.primaryColorObj ??
        const Color(0xFF1976D2);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Rigging Setup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (user != null &&
                    currentMembership != null &&
                    organization != null)
                  TextButton.icon(
                    onPressed: () => _navigateToRiggingEditor(context),
                    icon: Icon(Icons.tune, size: 18, color: primaryColor),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (rig != null) ...[
              _InfoRow(label: 'Configuration', value: rig.name),
              _InfoRow(label: 'Pattern', value: rig.description),
              const SizedBox(height: 8),
              // Mini visual preview
              _buildMiniRiggingPreview(rig),
            ] else
              Text(
                'No rigging configured — using default port stroke',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),

            if (equipment.riggingType == RiggingType.dualRigged) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Dual Rigged',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    equipment.activeShellType != null
                        ? 'Active: ${_shellTypeDisplay(equipment.effectiveShellType!)}'
                        : 'Using base config',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniRiggingPreview(RiggingSetup rig) {
    return Row(
      children: rig.positions.reversed.map((p) {
        final seatNum = p.seat;
        final totalSeats = rig.positions.length;
        final label = seatNum == totalSeats
            ? 'S'
            : seatNum == 1
            ? 'B'
            : '$seatNum';
        final isPort = p.side == RiggerSide.port;

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isPort
                  ? Colors.red.withOpacity(0.15)
                  : Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isPort
                    ? Colors.red.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isPort ? Colors.red[700] : Colors.green[700],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _navigateToRiggingEditor(BuildContext context) {
    if (user == null || currentMembership == null || organization == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RiggingEditorScreen(
          user: user!,
          currentMembership: currentMembership!,
          organization: organization!,
          team: team,
          shell: equipment,
        ),
      ),
    );
  }

  bool _hasTypeSpecificInfo() {
    switch (equipment.type) {
      case EquipmentType.shell:
        return equipment.shellType != null || equipment.riggingType != null;
      case EquipmentType.oar:
        return equipment.oarType != null || equipment.oarCount != null;
      case EquipmentType.coxbox:
        return true;
      case EquipmentType.launch:
        return true;
      case EquipmentType.erg:
        return equipment.ergId != null;
    }
  }

  String _getTypeSpecificTitle() {
    switch (equipment.type) {
      case EquipmentType.shell:
        return 'Shell Details';
      case EquipmentType.oar:
        return 'Oar Details';
      case EquipmentType.coxbox:
        return 'Coxbox Details';
      case EquipmentType.launch:
        return 'Launch Details';
      case EquipmentType.erg:
        return 'Erg Details';
    }
  }

  List<Widget> _buildTypeSpecificInfo() {
    switch (equipment.type) {
      case EquipmentType.shell:
        return [
          if (equipment.shellType != null)
            _InfoRow(
              label: 'Boat Type',
              value: _shellTypeDisplay(equipment.shellType!),
            ),
          if (equipment.riggingType != null)
            _InfoRow(
              label: 'Rigging',
              value: _riggingTypeDisplay(equipment.riggingType!),
            ),
        ];
      case EquipmentType.oar:
        return [
          if (equipment.oarType != null)
            _InfoRow(
              label: 'Type',
              value: equipment.oarType == OarType.sweep ? 'Sweep' : 'Scull',
            ),
          if (equipment.oarCount != null)
            _InfoRow(label: 'Count', value: equipment.oarCount.toString()),
          if (equipment.bladeType != null)
            _InfoRow(label: 'Blade Type', value: equipment.bladeType!),
          if (equipment.oarLength != null)
            _InfoRow(label: 'Length', value: '${equipment.oarLength} cm'),
        ];
      case EquipmentType.coxbox:
        return [
          _InfoRow(
            label: 'Microphone',
            value: equipment.microphoneIncluded == true
                ? 'Included'
                : 'Not Included',
          ),
          if (equipment.batteryStatus != null)
            _InfoRow(label: 'Battery Status', value: equipment.batteryStatus!),
        ];
      case EquipmentType.launch:
        return [
          _InfoRow(
            label: 'Gas Tank',
            value: equipment.gasTankAssigned == true
                ? 'Assigned'
                : 'Not Assigned',
          ),
          if (equipment.tankNumber != null)
            _InfoRow(label: 'Tank Number', value: equipment.tankNumber!),
          if (equipment.fuelType != null)
            _InfoRow(label: 'Fuel Type', value: equipment.fuelType!),
        ];
      case EquipmentType.erg:
        return [
          if (equipment.ergId != null)
            _InfoRow(label: 'Erg ID', value: equipment.ergId!),
        ];
    }
  }

  String _shellTypeDisplay(ShellType type) {
    switch (type) {
      case ShellType.eight:
        return '8+ (Eight)';
      case ShellType.coxedFour:
        return '4+ (Coxed Four)';
      case ShellType.four:
        return '4- (Coxless Four)';
      case ShellType.quad:
        return '4x (Quad)';
      case ShellType.coxedQuad:
        return '4x+ (Coxed Quad)';
      case ShellType.pair:
        return '2- (Pair)';
      case ShellType.double:
        return '2x (Double)';
      case ShellType.single:
        return '1x (Single)';
    }
  }

  String _riggingTypeDisplay(RiggingType type) {
    switch (type) {
      case RiggingType.sweep:
        return 'Sweep Only';
      case RiggingType.scull:
        return 'Scull Only';
      case RiggingType.dualRigged:
        return 'Dual-Rigged (Both)';
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _TeamsList extends StatelessWidget {
  final List<String> teamIds;
  final TeamService teamService;

  const _TeamsList({required this.teamIds, required this.teamService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: teamIds.map((teamId) {
        return FutureBuilder<Team?>(
          future: teamService.getTeam(teamId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Loading...'),
              );
            }

            final team = snapshot.data;
            if (team == null) return const SizedBox();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: team.primaryColorObj,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(team.name, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _DamageReportsCard extends StatelessWidget {
  final List<DamageReport> damageReports;

  const _DamageReportsCard({required this.damageReports});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Damage Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...damageReports.map((report) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reported by ${report.reportedByName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('MM/dd/yyyy').format(report.reportedAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(report.description),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
