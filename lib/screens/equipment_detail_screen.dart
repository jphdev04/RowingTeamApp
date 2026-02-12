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
import 'maintenance_log_screen.dart';

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

  Color get _primaryColor =>
      team?.primaryColorObj ??
      organization?.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      _primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  bool get _canManageMaintenance =>
      currentMembership?.role == MembershipRole.coach ||
      currentMembership?.role == MembershipRole.admin ||
      currentMembership?.role == MembershipRole.boatman;

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
        return 'Under Maintenance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ── Flat TeamHeader ──
          TeamHeader(
            team: team,
            organization: team == null ? organization : null,
            title: equipment.displayName,
            subtitle: _getStatusText(),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _onPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit, color: _onPrimary),
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

          // ── Status badge below header ──
          Container(
            width: double.infinity,
            color: Colors.grey[50],
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
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
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getEquipmentTypeLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Needs attention banner
                  if (equipment.needsAttention)
                    _buildNeedsAttentionBanner(context),

                  // Basic info
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

                  // Type-specific info
                  if (_hasTypeSpecificInfo())
                    _InfoCard(
                      title: _getTypeSpecificTitle(),
                      children: _buildTypeSpecificInfo(),
                    ),

                  // Coxbox assignment
                  if (equipment.type == EquipmentType.coxbox) ...[
                    const SizedBox(height: 16),
                    _buildCoxboxAssignmentCard(),
                  ],

                  // ── Rigging card with full visual diagram ──
                  if (equipment.type == EquipmentType.shell &&
                      equipment.isSweepConfig) ...[
                    const SizedBox(height: 16),
                    _buildRiggingCard(context),
                  ],

                  const SizedBox(height: 16),

                  // Purchase info
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

                  // Team assignment
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

                  // Damage reports
                  if (equipment.isDamaged &&
                      equipment.unresolvedDamageReports.isNotEmpty)
                    _DamageReportsCard(
                      damageReports: equipment.unresolvedDamageReports,
                    ),
                  const SizedBox(height: 16),

                  // Maintenance log
                  _buildMaintenanceLogCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEquipmentTypeLabel() {
    switch (equipment.type) {
      case EquipmentType.shell:
        return equipment.shellType != null
            ? _shellTypeDisplay(equipment.shellType!)
            : 'Shell';
      case EquipmentType.oar:
        return equipment.oarType == OarType.sweep
            ? 'Sweep Oars'
            : 'Sculling Oars';
      case EquipmentType.coxbox:
        return equipment.coxboxType == CoxboxType.speedcoach
            ? 'SpeedCoach'
            : 'Coxbox';
      case EquipmentType.launch:
        return 'Launch';
      case EquipmentType.erg:
        return 'Erg';
    }
  }

  // ════════════════════════════════════════════════════════════
  // NEEDS ATTENTION BANNER
  // ════════════════════════════════════════════════════════════

  Widget _buildNeedsAttentionBanner(BuildContext context) {
    final statusColor = _getStatusColor();
    final unresolvedCount = equipment.unresolvedDamageReports.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            equipment.status == EquipmentStatus.damaged
                ? Icons.warning_amber_rounded
                : Icons.build,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.status == EquipmentStatus.damaged
                      ? '$unresolvedCount open damage ${unresolvedCount == 1 ? 'report' : 'reports'}'
                      : 'Under maintenance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                if (_canManageMaintenance)
                  Text(
                    'Tap "Maintenance Log" below to manage',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          if (_canManageMaintenance && user != null)
            TextButton(
              onPressed: () => _navigateToMaintenanceLog(context),
              child: Text(
                'Manage',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // RIGGING CARD — full visual diagram
  // ════════════════════════════════════════════════════════════

  Widget _buildRiggingCard(BuildContext context) {
    final rig = equipment.effectiveRiggingSetup;
    final seatCount = equipment.shellType != null
        ? _seatCountForShellType(
            equipment.effectiveShellType ?? equipment.shellType!,
          )
        : 0;
    final positions =
        rig?.positions ??
        RiggingPresets.standardPortStroke(seatCount).positions;

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
            // Header row
            Row(
              children: [
                const Text(
                  'Rigging Setup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (user != null &&
                    currentMembership != null &&
                    organization != null &&
                    _canManageMaintenance)
                  TextButton.icon(
                    onPressed: () => _navigateToRiggingEditor(context),
                    icon: Icon(Icons.tune, size: 18, color: _primaryColor),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (rig != null) ...[
              Text(
                rig.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                rig.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
            const SizedBox(height: 16),

            // ── Full visual per-seat diagram ──
            if (seatCount > 0) _buildFullRiggingDiagram(positions, seatCount),

            // Dual-rigged badge
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

  Widget _buildFullRiggingDiagram(
    List<RiggerPosition> positions,
    int seatCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  'PORT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 50,
                child: Text(
                  'STBD',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[400],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Seats from stroke (top) to bow (bottom)
        ...List.generate(seatCount, (i) {
          final seatNum = seatCount - i;
          final position = positions.firstWhere(
            (p) => p.seat == seatNum,
            orElse: () => RiggerPosition(seat: seatNum, side: RiggerSide.port),
          );
          final seatLabel = seatNum == seatCount
              ? 'Stroke'
              : seatNum == 1
              ? 'Bow'
              : 'Seat $seatNum';
          final isPort = position.side == RiggerSide.port;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                // Port indicator
                _buildSideIndicator(
                  isActive: isPort,
                  color: Colors.red,
                  label: 'P',
                ),
                const SizedBox(width: 8),

                // Port rigger arm
                if (isPort)
                  Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.red[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox(width: 24),

                const SizedBox(width: 4),

                // Seat pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isPort
                          ? Colors.red.withOpacity(0.06)
                          : Colors.green.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPort
                            ? Colors.red.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        seatLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Starboard rigger arm
                if (!isPort)
                  Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.green[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox(width: 24),

                const SizedBox(width: 8),

                // Starboard indicator
                _buildSideIndicator(
                  isActive: !isPort,
                  color: Colors.green,
                  label: 'S',
                ),
              ],
            ),
          );
        }),

        // Balance summary
        const SizedBox(height: 12),
        _buildBalanceSummary(positions),
      ],
    );
  }

  Widget _buildSideIndicator({
    required bool isActive,
    required MaterialColor color,
    required String label,
  }) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withOpacity(0.4) : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? color[700] : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSummary(List<RiggerPosition> positions) {
    final portCount = positions.where((p) => p.side == RiggerSide.port).length;
    final stbdCount = positions
        .where((p) => p.side == RiggerSide.starboard)
        .length;
    final isBalanced = portCount == stbdCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isBalanced ? Icons.check_circle : Icons.warning_amber_rounded,
          color: isBalanced ? Colors.green : Colors.orange,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          isBalanced
              ? 'Balanced ($portCount port / $stbdCount stbd)'
              : 'Unbalanced ($portCount port / $stbdCount stbd)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isBalanced ? Colors.green[700] : Colors.orange[700],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // COXBOX ASSIGNMENT CARD
  // ════════════════════════════════════════════════════════════

  Widget _buildCoxboxAssignmentCard() {
    final isCoxbox =
        equipment.coxboxType == CoxboxType.coxbox ||
        equipment.coxboxType == null;
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
                  'Assignment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (equipment.coxboxType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      equipment.coxboxType == CoxboxType.speedcoach
                          ? 'SpeedCoach'
                          : 'Coxbox',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: isCoxbox ? 'Assigned Coxswain' : 'Assigned Shell',
              value: equipment.assignedToName ?? 'Unassigned',
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // MAINTENANCE LOG CARD
  // ════════════════════════════════════════════════════════════

  Widget _buildMaintenanceLogCard(BuildContext context) {
    final logCount = equipment.maintenanceLog.length;
    final lastEntry = equipment.maintenanceLog.isNotEmpty
        ? equipment.maintenanceLog.last
        : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _navigateToMaintenanceLog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.build, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maintenance Log',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      logCount == 0
                          ? 'No maintenance history'
                          : '$logCount ${logCount == 1 ? 'entry' : 'entries'}${lastEntry != null ? ' · Last: ${DateFormat('MMM d').format(lastEntry.createdAt)}' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // NAVIGATION
  // ════════════════════════════════════════════════════════════

  void _navigateToMaintenanceLog(BuildContext context) {
    if (user == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MaintenanceLogScreen(
          equipmentId: equipment.id,
          organizationId: equipment.organizationId,
          userId: user!.id,
          userName: user!.name,
          organization: organization,
          team: team,
        ),
      ),
    );
  }

  void _navigateToRiggingEditor(BuildContext context) {
    if (user == null || currentMembership == null || organization == null)
      return;
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

  // ════════════════════════════════════════════════════════════
  // TYPE-SPECIFIC INFO
  // ════════════════════════════════════════════════════════════

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
        return equipment.coxboxType == CoxboxType.speedcoach
            ? 'SpeedCoach Details'
            : 'Coxbox Details';
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
          if (equipment.coxboxType != null)
            _InfoRow(
              label: 'Type',
              value: equipment.coxboxType == CoxboxType.speedcoach
                  ? 'SpeedCoach'
                  : 'Coxbox',
            ),
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

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

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

// ════════════════════════════════════════════════════════════
// REUSABLE DETAIL WIDGETS
// ════════════════════════════════════════════════════════════

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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Open Damage Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...damageReports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'by ${report.reportedByName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(report.reportedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
