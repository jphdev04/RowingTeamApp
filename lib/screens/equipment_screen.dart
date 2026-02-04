import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../models/team.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';
import '../services/organization_service.dart';
import '../widgets/team_header.dart';
import 'add_equipment_screen.dart';
import 'equipment_list_screen.dart';

class EquipmentScreen extends StatelessWidget {
  final String organizationId;
  final Team? team;
  final Membership? currentMembership;

  const EquipmentScreen({
    super.key,
    required this.organizationId,
    this.team,
    this.currentMembership,
  });

  bool get isCoach =>
      currentMembership?.role == MembershipRole.coach ||
      currentMembership?.role == MembershipRole.admin;

  @override
  Widget build(BuildContext context) {
    final equipmentService = EquipmentService();
    final orgService = OrganizationService();

    return FutureBuilder<Organization?>(
      future: orgService.getOrganization(organizationId),
      builder: (context, orgSnapshot) {
        final organization = orgSnapshot.data;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              TeamHeader(
                team: team,
                organization: team == null ? organization : null,
                title: 'Equipment',
                subtitle: 'Manage your gear',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Equipment>>(
                  stream: equipmentService.getEquipmentByTeam(organizationId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allEquipment = snapshot.data ?? [];

                    // Filter damaged equipment
                    final damagedEquipment = allEquipment
                        .where((e) => e.isDamaged)
                        .toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Equipment Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // First row
                          Row(
                            children: [
                              Expanded(
                                child: _EquipmentCategoryCard(
                                  title: 'Shells',
                                  icon: Icons.rowing,
                                  count: allEquipment
                                      .where(
                                        (e) => e.type == EquipmentType.shell,
                                      )
                                      .where(
                                        (e) =>
                                            team == null ||
                                            e.availableToAllTeams ||
                                            e.assignedTeamIds.contains(
                                              team!.id,
                                            ),
                                      )
                                      .length,
                                  color:
                                      team?.primaryColorObj ??
                                      organization?.primaryColorObj ??
                                      Colors.blue,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EquipmentListScreen(
                                              organizationId: organizationId,
                                              team: team,
                                              currentMembership:
                                                  currentMembership,
                                              equipmentType:
                                                  EquipmentType.shell,
                                              title: 'Shells',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EquipmentCategoryCard(
                                  title: 'Oars',
                                  icon: Icons.sports,
                                  count: allEquipment
                                      .where((e) => e.type == EquipmentType.oar)
                                      .where(
                                        (e) =>
                                            team == null ||
                                            e.availableToAllTeams ||
                                            e.assignedTeamIds.contains(
                                              team!.id,
                                            ),
                                      )
                                      .length,
                                  color:
                                      team?.primaryColorObj ??
                                      organization?.primaryColorObj ??
                                      Colors.orange,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EquipmentListScreen(
                                              organizationId: organizationId,
                                              team: team,
                                              currentMembership:
                                                  currentMembership,
                                              equipmentType: EquipmentType.oar,
                                              title: 'Oars',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Second row
                          Row(
                            children: [
                              Expanded(
                                child: _EquipmentCategoryCard(
                                  title: 'Coxboxes',
                                  icon: Icons.speaker,
                                  count: allEquipment
                                      .where(
                                        (e) => e.type == EquipmentType.coxbox,
                                      )
                                      .where(
                                        (e) =>
                                            team == null ||
                                            e.availableToAllTeams ||
                                            e.assignedTeamIds.contains(
                                              team!.id,
                                            ),
                                      )
                                      .length,
                                  color:
                                      team?.primaryColorObj ??
                                      organization?.primaryColorObj ??
                                      Colors.purple,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EquipmentListScreen(
                                              organizationId: organizationId,
                                              team: team,
                                              currentMembership:
                                                  currentMembership,
                                              equipmentType:
                                                  EquipmentType.coxbox,
                                              title: 'Coxboxes & Speakers',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EquipmentCategoryCard(
                                  title: 'Launches',
                                  icon: Icons.directions_boat,
                                  count: allEquipment
                                      .where(
                                        (e) => e.type == EquipmentType.launch,
                                      )
                                      .where(
                                        (e) =>
                                            team == null ||
                                            e.availableToAllTeams ||
                                            e.assignedTeamIds.contains(
                                              team!.id,
                                            ),
                                      )
                                      .length,
                                  color:
                                      team?.primaryColorObj ??
                                      organization?.primaryColorObj ??
                                      Colors.teal,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EquipmentListScreen(
                                              organizationId: organizationId,
                                              team: team,
                                              currentMembership:
                                                  currentMembership,
                                              equipmentType:
                                                  EquipmentType.launch,
                                              title: 'Coaching Launches',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Third row
                          Row(
                            children: [
                              Expanded(
                                child: _EquipmentCategoryCard(
                                  title: 'Ergs',
                                  icon: Icons.fitness_center,
                                  count: allEquipment
                                      .where((e) => e.type == EquipmentType.erg)
                                      .where(
                                        (e) =>
                                            team == null ||
                                            e.availableToAllTeams ||
                                            e.assignedTeamIds.contains(
                                              team!.id,
                                            ),
                                      )
                                      .length,
                                  color:
                                      team?.primaryColorObj ??
                                      organization?.primaryColorObj ??
                                      Colors.red,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EquipmentListScreen(
                                              organizationId: organizationId,
                                              team: team,
                                              currentMembership:
                                                  currentMembership,
                                              equipmentType: EquipmentType.erg,
                                              title: 'Ergs & Land Training',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: SizedBox()),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Quick Stats
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Equipment Status',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _CriticalStatItem(
                                        icon: Icons.check_circle,
                                        label: 'Ready',
                                        value: allEquipment
                                            .where(
                                              (e) =>
                                                  team == null ||
                                                  e.availableToAllTeams ||
                                                  e.assignedTeamIds.contains(
                                                    team!.id,
                                                  ),
                                            )
                                            .where(
                                              (e) =>
                                                  e.status ==
                                                  EquipmentStatus.available,
                                            )
                                            .length
                                            .toString(),
                                        color: Colors.green,
                                      ),
                                      if (allEquipment
                                          .where(
                                            (e) =>
                                                team == null ||
                                                e.availableToAllTeams ||
                                                e.assignedTeamIds.contains(
                                                  team!.id,
                                                ),
                                          )
                                          .where(
                                            (e) =>
                                                e.status ==
                                                EquipmentStatus.damaged,
                                          )
                                          .isNotEmpty)
                                        _CriticalStatItem(
                                          icon: Icons.warning,
                                          label: 'Damaged',
                                          value: allEquipment
                                              .where(
                                                (e) =>
                                                    team == null ||
                                                    e.availableToAllTeams ||
                                                    e.assignedTeamIds.contains(
                                                      team!.id,
                                                    ),
                                              )
                                              .where(
                                                (e) =>
                                                    e.status ==
                                                    EquipmentStatus.damaged,
                                              )
                                              .length
                                              .toString(),
                                          color: Colors.red,
                                        ),
                                      if (allEquipment
                                          .where(
                                            (e) =>
                                                team == null ||
                                                e.availableToAllTeams ||
                                                e.assignedTeamIds.contains(
                                                  team!.id,
                                                ),
                                          )
                                          .where(
                                            (e) =>
                                                e.status ==
                                                EquipmentStatus.maintenance,
                                          )
                                          .isNotEmpty)
                                        _CriticalStatItem(
                                          icon: Icons.build,
                                          label: 'Maintenance',
                                          value: allEquipment
                                              .where(
                                                (e) =>
                                                    team == null ||
                                                    e.availableToAllTeams ||
                                                    e.assignedTeamIds.contains(
                                                      team!.id,
                                                    ),
                                              )
                                              .where(
                                                (e) =>
                                                    e.status ==
                                                    EquipmentStatus.maintenance,
                                              )
                                              .length
                                              .toString(),
                                          color: Colors.orange,
                                        ),
                                      if (allEquipment
                                          .where(
                                            (e) =>
                                                team == null ||
                                                e.availableToAllTeams ||
                                                e.assignedTeamIds.contains(
                                                  team!.id,
                                                ),
                                          )
                                          .where(
                                            (e) =>
                                                e.status ==
                                                EquipmentStatus.inUse,
                                          )
                                          .isNotEmpty)
                                        _CriticalStatItem(
                                          icon: Icons.timelapse,
                                          label: 'In Use',
                                          value: allEquipment
                                              .where(
                                                (e) =>
                                                    team == null ||
                                                    e.availableToAllTeams ||
                                                    e.assignedTeamIds.contains(
                                                      team!.id,
                                                    ),
                                              )
                                              .where(
                                                (e) =>
                                                    e.status ==
                                                    EquipmentStatus.inUse,
                                              )
                                              .length
                                              .toString(),
                                          color: Colors.blue,
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
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: isCoach
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddEquipmentScreen(
                          organizationId: organizationId,
                          organization: organization,
                          team: team,
                        ),
                      ),
                    );
                  },
                  backgroundColor:
                      team?.primaryColorObj ?? organization?.primaryColorObj,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}

class _EquipmentCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _EquipmentCategoryCard({
    required this.title,
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? 'item' : 'items'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _CriticalStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CriticalStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
