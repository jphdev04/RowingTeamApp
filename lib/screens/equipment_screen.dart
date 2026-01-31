import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/athlete.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import '../widgets/team_header.dart';

class EquipmentScreen extends StatelessWidget {
  final String teamId;
  final Team? team;
  final Athlete athlete;

  const EquipmentScreen({
    super.key,
    required this.teamId,
    this.team,
    required this.athlete,
  });

  bool get isCoach => athlete.role == 'coach';

  @override
  Widget build(BuildContext context) {
    final equipmentService = EquipmentService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TeamHeader(
            team: team,
            title: 'Equipment',
            subtitle: isCoach
                ? 'Manage team equipment'
                : 'View & report damage',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: (team?.primaryColorObj.computeLuminance() ?? 0) > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Equipment>>(
              stream: equipmentService.getEquipmentByTeam(teamId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allEquipment = snapshot.data ?? [];

                // Group equipment by type
                final shells = allEquipment
                    .where((e) => e.type == EquipmentType.shell)
                    .toList();
                final launches = allEquipment
                    .where((e) => e.type == EquipmentType.launch)
                    .toList();
                final coxboxes = allEquipment
                    .where((e) => e.type == EquipmentType.coxbox)
                    .toList();
                final oars = allEquipment
                    .where((e) => e.type == EquipmentType.oars)
                    .toList();
                final ergs = allEquipment
                    .where((e) => e.type == EquipmentType.erg)
                    .toList();

                final primaryColor =
                    team?.primaryColorObj ?? const Color(0xFF1976D2);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Equipment type grid (similar to dashboard)
                      Text(
                        'Equipment Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _EquipmentCategoryCard(
                              title: 'Shells',
                              count: shells.length,
                              icon: Icons.rowing,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EquipmentListScreen(
                                      teamId: teamId,
                                      team: team,
                                      athlete: athlete,
                                      equipmentType: EquipmentType.shell,
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
                              title: 'Launches',
                              count: launches.length,
                              icon: Icons.directions_boat,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EquipmentListScreen(
                                      teamId: teamId,
                                      team: team,
                                      athlete: athlete,
                                      equipmentType: EquipmentType.launch,
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

                      Row(
                        children: [
                          Expanded(
                            child: _EquipmentCategoryCard(
                              title: 'Cox Boxes',
                              count: coxboxes.length,
                              icon: Icons.speaker,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EquipmentListScreen(
                                      teamId: teamId,
                                      team: team,
                                      athlete: athlete,
                                      equipmentType: EquipmentType.coxbox,
                                      title: 'Cox Boxes',
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
                              count: oars.length,
                              icon: Icons.sports,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EquipmentListScreen(
                                      teamId: teamId,
                                      team: team,
                                      athlete: athlete,
                                      equipmentType: EquipmentType.oars,
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

                      Row(
                        children: [
                          Expanded(
                            child: _EquipmentCategoryCard(
                              title: 'Ergs',
                              count: ergs.length,
                              icon: Icons.fitness_center,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EquipmentListScreen(
                                      teamId: teamId,
                                      team: team,
                                      athlete: athlete,
                                      equipmentType: EquipmentType.erg,
                                      title: 'Ergs',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: SizedBox(),
                          ), // Empty space for alignment
                        ],
                      ),

                      // Damaged equipment section
                      if (allEquipment.any((e) => e.isDamaged)) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Damaged Equipment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...allEquipment.where((e) => e.isDamaged).map((
                          equipment,
                        ) {
                          return _DamagedEquipmentCard(
                            equipment: equipment,
                            isCoach: isCoach,
                          );
                        }).toList(),
                      ],

                      // Quick stats
                      const SizedBox(height: 32),
                      Text(
                        'Quick Stats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            _StatRow(
                              label: 'Total Equipment',
                              value: allEquipment.length.toString(),
                            ),
                            const Divider(),
                            _StatRow(
                              label: 'Available',
                              value: allEquipment
                                  .where(
                                    (e) =>
                                        e.status == EquipmentStatus.available,
                                  )
                                  .length
                                  .toString(),
                              valueColor: Colors.green,
                            ),
                            const Divider(),
                            _StatRow(
                              label: 'Damaged',
                              value: allEquipment
                                  .where((e) => e.isDamaged)
                                  .length
                                  .toString(),
                              valueColor: Colors.red,
                            ),
                            const Divider(),
                            _StatRow(
                              label: 'In Maintenance',
                              value: allEquipment
                                  .where(
                                    (e) =>
                                        e.status == EquipmentStatus.maintenance,
                                  )
                                  .length
                                  .toString(),
                              valueColor: Colors.orange,
                            ),
                          ],
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
                // TODO: Navigate to add equipment screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add equipment coming soon!')),
                );
              },
              backgroundColor: team?.primaryColorObj ?? Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _EquipmentCategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EquipmentCategoryCard({
    required this.title,
    required this.count,
    required this.icon,
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
                '$count items',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DamagedEquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final bool isCoach;

  const _DamagedEquipmentCard({required this.equipment, required this.isCoach});

  @override
  Widget build(BuildContext context) {
    final unresolvedReports = equipment.damageReports
        .where((r) => !r.isResolved)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.red, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    equipment.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${unresolvedReports.length} unresolved report${unresolvedReports.length != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (unresolvedReports.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...unresolvedReports.map((report) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reported by ${report.reportedByName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}

// Placeholder for the equipment list screen (we'll build this next)
class EquipmentListScreen extends StatelessWidget {
  final String teamId;
  final Team? team;
  final Athlete athlete;
  final EquipmentType equipmentType;
  final String title;

  const EquipmentListScreen({
    super.key,
    required this.teamId,
    this.team,
    required this.athlete,
    required this.equipmentType,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Equipment list coming soon!')),
    );
  }
}
