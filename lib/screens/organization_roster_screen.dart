import 'package:flutter/material.dart';
import '../services/membership_service.dart';
import '../services/user_service.dart';
import '../services/team_service.dart';
import '../models/membership.dart';
import '../models/user.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../widgets/team_header.dart';

class OrganizationRosterScreen extends StatelessWidget {
  final String organizationId;
  final Organization? organization;

  const OrganizationRosterScreen({
    super.key,
    required this.organizationId,
    this.organization,
  });

  @override
  Widget build(BuildContext context) {
    final membershipService = MembershipService();
    final primaryColor = const Color(0xFF6A1B9A);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        // CHANGE FROM JUST BODY TO COLUMN
        children: [
          TeamHeader(
            // REPLACE APPBAR WITH THIS
            organization: organization,
            title: 'Organization Roster',
            subtitle: 'All members',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Membership>>(
              stream: membershipService.getOrganizationMemberships(
                organizationId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final memberships = snapshot.data ?? [];

                if (memberships.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No members yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Group by team
                final noTeam = memberships
                    .where((m) => m.teamId == null)
                    .toList();
                final teamGroups = <String, List<Membership>>{};

                for (final membership in memberships) {
                  if (membership.teamId != null) {
                    if (!teamGroups.containsKey(membership.teamId)) {
                      teamGroups[membership.teamId!] = [];
                    }
                    teamGroups[membership.teamId!]!.add(membership);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary card
                    Card(
                      color: primaryColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              label: 'Total Members',
                              value: memberships.length.toString(),
                              icon: Icons.people,
                            ),
                            _StatItem(
                              label: 'Teams',
                              value: teamGroups.length.toString(),
                              icon: Icons.groups,
                            ),
                            _StatItem(
                              label: 'Admins',
                              value: memberships
                                  .where((m) => m.role == MembershipRole.admin)
                                  .length
                                  .toString(),
                              icon: Icons.admin_panel_settings,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Team sections
                    ...teamGroups.entries.map((entry) {
                      return _TeamSection(
                        teamId: entry.key,
                        memberships: entry.value,
                      );
                    }).toList(),

                    // No team section
                    if (noTeam.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Organization Members (No Team)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...noTeam.map((membership) {
                        return _MemberCard(membership: membership);
                      }).toList(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: const Color(0xFF6A1B9A)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _TeamSection extends StatelessWidget {
  final String teamId;
  final List<Membership> memberships;

  const _TeamSection({required this.teamId, required this.memberships});

  @override
  Widget build(BuildContext context) {
    final teamService = TeamService();

    return FutureBuilder<Team?>(
      future: teamService.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color:
                    team?.primaryColorObj.withOpacity(0.1) ??
                    Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups,
                    color: team?.primaryColorObj ?? Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    team?.name ?? 'Loading...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: team?.primaryColorObj ?? Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${memberships.length} members',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...memberships.map((membership) {
              return _MemberCard(membership: membership);
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  } // widget
}

class _MemberCard extends StatelessWidget {
  final Membership membership;

  const _MemberCard({required this.membership});

  Color _getRoleColor(MembershipRole role) {
    switch (role) {
      case MembershipRole.admin:
        return Colors.deepPurple;
      case MembershipRole.coach:
        return Colors.purple;
      case MembershipRole.coxswain:
        return Colors.orange;
      case MembershipRole.rower:
        return Colors.blue;
      case MembershipRole.boatman:
        return Colors.brown;
      case MembershipRole.athlete:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return FutureBuilder<AppUser?>(
      future: userService.getUser(membership.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) return const SizedBox();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member details coming soon!')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getRoleColor(membership.role),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                  membership.role,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                membership.customTitle ??
                                    membership.role.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getRoleColor(membership.role),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (membership.role == MembershipRole.rower &&
                                membership.side != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                membership.side!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (user.hasInjury)
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
