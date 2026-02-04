import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../models/team.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';
import '../services/organization_service.dart';
import '../widgets/team_header.dart';
import 'equipment_detail_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  final String organizationId;
  final Team? team;
  final Membership? currentMembership;
  final EquipmentType equipmentType;
  final String title;

  const EquipmentListScreen({
    super.key,
    required this.organizationId,
    this.team,
    this.currentMembership,
    required this.equipmentType,
    required this.title,
  });

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _equipmentService = EquipmentService();
  final _orgService = OrganizationService();

  String _filterStatus = 'All';
  String _sortBy = 'Name';

  bool get isCoach =>
      widget.currentMembership?.role == MembershipRole.coach ||
      widget.currentMembership?.role == MembershipRole.admin;

  bool get isTeamView => widget.team != null;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Organization?>(
      future: _orgService.getOrganization(widget.organizationId),
      builder: (context, orgSnapshot) {
        final organization = orgSnapshot.data;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              TeamHeader(
                team: widget.team,
                organization: widget.team == null ? organization : null,
                title: widget.title,
                subtitle: _getSubtitle(),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items:
                            [
                                  'All',
                                  'Available',
                                  'In Use',
                                  'Damaged',
                                  'Maintenance',
                                ]
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() => _filterStatus = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(
                          labelText: 'Sort By',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: ['Name', 'Year', 'Status']
                            .map(
                              (sort) => DropdownMenuItem(
                                value: sort,
                                child: Text(sort),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _sortBy = value!);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Equipment list
              Expanded(
                child: StreamBuilder<List<Equipment>>(
                  stream: _equipmentService.getEquipmentByTeam(
                    widget.organizationId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    var equipment = snapshot.data ?? [];

                    print(
                      'DEBUG: Total equipment from stream: ${equipment.length}',
                    );
                    // Filter by equipment type
                    equipment = equipment
                        .where((e) => e.type == widget.equipmentType)
                        .toList();

                    print(
                      'DEBUG: After type filter (${widget.equipmentType.name}): ${equipment.length}',
                    );
                    // Filter by team if in team view
                    if (isTeamView) {
                      print(
                        'DEBUG: Team view - filtering for team: ${widget.team!.id}',
                      );
                      equipment = equipment.where((e) {
                        final matches =
                            e.availableToAllTeams ||
                            e.assignedTeamIds.contains(widget.team!.id);
                        if (matches) {
                          print(
                            'DEBUG: Equipment ${e.displayName}: availableToAll=${e.availableToAllTeams}, teams=${e.assignedTeamIds}',
                          );
                        }
                        return matches;
                      }).toList();
                      print('DEBUG: After team filter: ${equipment.length}');
                    }

                    // Filter by status
                    if (_filterStatus != 'All') {
                      equipment = equipment.where((e) {
                        switch (_filterStatus) {
                          case 'Available':
                            return e.status == EquipmentStatus.available;
                          case 'In Use':
                            return e.status == EquipmentStatus.inUse;
                          case 'Damaged':
                            return e.status == EquipmentStatus.damaged;
                          case 'Maintenance':
                            return e.status == EquipmentStatus.maintenance;
                          default:
                            return true;
                        }
                      }).toList();
                    }

                    // Sort
                    equipment.sort((a, b) {
                      switch (_sortBy) {
                        case 'Name':
                          return a.displayName.compareTo(b.displayName);
                        case 'Year':
                          return (b.year ?? 0).compareTo(a.year ?? 0);
                        case 'Status':
                          return a.status.name.compareTo(b.status.name);
                        default:
                          return 0;
                      }
                    });

                    if (equipment.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconForType(widget.equipmentType),
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${widget.title.toLowerCase()} yet',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            if (isCoach) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Tap + to add equipment',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    // Group by sub-type for certain equipment
                    if (widget.equipmentType == EquipmentType.shell) {
                      return _buildShellGroupedList(equipment, organization);
                    } else if (widget.equipmentType == EquipmentType.oar) {
                      return _buildOarGroupedList(equipment, organization);
                    } else if (widget.equipmentType == EquipmentType.erg) {
                      return _buildErgGroupedList(equipment, organization);
                    } else {
                      return _buildSimpleList(equipment, organization);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSubtitle() {
    if (isTeamView) {
      return '${widget.team!.name} equipment';
    } else {
      return 'All organization equipment';
    }
  }

  IconData _getIconForType(EquipmentType type) {
    switch (type) {
      case EquipmentType.shell:
        return Icons.rowing;
      case EquipmentType.oar:
        return Icons.sports;
      case EquipmentType.coxbox:
        return Icons.speaker;
      case EquipmentType.launch:
        return Icons.directions_boat;
      case EquipmentType.erg:
        return Icons.fitness_center;
    }
  }

  // Shell list grouped by boat type
  Widget _buildShellGroupedList(List<Equipment> equipment, Organization? org) {
    final grouped = <ShellType, List<Equipment>>{};
    for (final e in equipment) {
      if (e.shellType != null) {
        grouped.putIfAbsent(e.shellType!, () => []).add(e);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats card
        _buildStatsCard(equipment, org),
        const SizedBox(height: 16),

        // Grouped by shell type
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _shellTypeDisplay(entry.key),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...entry.value.map(
                (e) => _EquipmentCard(
                  equipment: e,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EquipmentDetailScreen(
                          equipmentId: e.id,
                          organizationId: widget.organizationId,
                          team: widget.team,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Oar list grouped by type
  Widget _buildOarGroupedList(List<Equipment> equipment, Organization? org) {
    final sweep = equipment.where((e) => e.oarType == OarType.sweep).toList();
    final scull = equipment.where((e) => e.oarType == OarType.scull).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsCard(equipment, org),
        const SizedBox(height: 16),

        if (sweep.isNotEmpty) ...[
          const Text(
            'Sweep Oars',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...sweep.map(
            (e) => _EquipmentCard(
              equipment: e,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EquipmentDetailScreen(
                      equipmentId: e.id,
                      organizationId: widget.organizationId,
                      team: widget.team,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        if (scull.isNotEmpty) ...[
          const Text(
            'Sculling Oars',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...scull.map(
            (e) => _EquipmentCard(
              equipment: e,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EquipmentDetailScreen(
                      equipmentId: e.id,
                      organizationId: widget.organizationId,
                      team: widget.team,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // Erg list grouped by manufacturer/model
  Widget _buildErgGroupedList(List<Equipment> equipment, Organization? org) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsCard(equipment, org),
        const SizedBox(height: 16),
        ...equipment.map(
          (e) => _EquipmentCard(
            equipment: e,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EquipmentDetailScreen(
                    equipmentId: e.id,
                    organizationId: widget.organizationId,
                    team: widget.team,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Simple list for coxboxes and launches
  Widget _buildSimpleList(List<Equipment> equipment, Organization? org) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsCard(equipment, org),
        const SizedBox(height: 16),
        ...equipment.map(
          (e) => _EquipmentCard(
            equipment: e,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EquipmentDetailScreen(
                    equipmentId: e.id,
                    organizationId: widget.organizationId,
                    team: widget.team,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(List<Equipment> equipment, Organization? org) {
    final available = equipment
        .where((e) => e.status == EquipmentStatus.available)
        .length;
    final inUse = equipment
        .where((e) => e.status == EquipmentStatus.inUse)
        .length;
    final damaged = equipment
        .where((e) => e.status == EquipmentStatus.damaged)
        .length;
    final maintenance = equipment
        .where((e) => e.status == EquipmentStatus.maintenance)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(label: 'Total', value: equipment.length.toString()),
            _StatItem(
              label: 'Available',
              value: available.toString(),
              color: Colors.green,
            ),
            _StatItem(
              label: 'In Use',
              value: inUse.toString(),
              color: Colors.blue,
            ),
            _StatItem(
              label: 'Damaged',
              value: damaged.toString(),
              color: Colors.red,
            ),
            _StatItem(
              label: 'Maintenance',
              value: maintenance.toString(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  String _shellTypeDisplay(ShellType type) {
    switch (type) {
      case ShellType.eight:
        return 'Eights (8+)';
      case ShellType.coxedFour:
        return 'Coxed Fours (4+)';
      case ShellType.four:
        return 'Coxless Fours (4-)';
      case ShellType.quad:
        return 'Quads (4x)';
      case ShellType.coxedQuad:
        return 'Coxed Quads (4x+)';
      case ShellType.pair:
        return 'Pairs (2-)';
      case ShellType.double:
        return 'Doubles (2x)';
      case ShellType.single:
        return 'Singles (1x)';
    }
  }
}

class _EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const _EquipmentCard({required this.equipment, required this.onTap});

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

  IconData _getStatusIcon() {
    switch (equipment.status) {
      case EquipmentStatus.available:
        return Icons.check_circle;
      case EquipmentStatus.inUse:
        return Icons.timelapse;
      case EquipmentStatus.damaged:
        return Icons.warning;
      case EquipmentStatus.maintenance:
        return Icons.build;
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Equipment info
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
                    const SizedBox(height: 4),
                    Text(
                      '${equipment.manufacturer}${equipment.model != null ? ' ${equipment.model}' : ''}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (equipment.year != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Year: ${equipment.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
