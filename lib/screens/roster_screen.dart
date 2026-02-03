import 'package:flutter/material.dart';
import '../services/membership_service.dart';
import '../services/user_service.dart';
import '../services/organization_service.dart';
import '../services/team_service.dart';
import '../models/membership.dart';
import '../models/user.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../widgets/team_header.dart';

class RosterScreen extends StatelessWidget {
  final String organizationId;
  final String? teamId;
  final Team? team;

  const RosterScreen({
    super.key,
    required this.organizationId,
    this.teamId,
    this.team,
  });

  @override
  Widget build(BuildContext context) {
    final membershipService = MembershipService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TeamHeader(
            team: team,
            title: 'Team Roster',
            subtitle: 'Manage your team',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Membership>>(
              stream: teamId != null
                  ? membershipService.getTeamMemberships(teamId!)
                  : membershipService.getOrganizationMemberships(
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
                        SizedBox(height: 8),
                        Text(
                          'Share your join code to invite members',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Group by role
                final coaches = memberships
                    .where(
                      (m) =>
                          m.role == MembershipRole.coach ||
                          m.role == MembershipRole.admin,
                    )
                    .toList();
                final rowers = memberships
                    .where((m) => m.role == MembershipRole.rower)
                    .toList();
                final coxswains = memberships
                    .where((m) => m.role == MembershipRole.coxswain)
                    .toList();
                final others = memberships
                    .where(
                      (m) =>
                          m.role != MembershipRole.coach &&
                          m.role != MembershipRole.admin &&
                          m.role != MembershipRole.rower &&
                          m.role != MembershipRole.coxswain,
                    )
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (coaches.isNotEmpty) ...[
                      _RoleSection(
                        title: 'Coaches & Admins',
                        memberships: coaches,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (rowers.isNotEmpty) ...[
                      _RoleSection(
                        title: 'Rowers',
                        memberships: rowers,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (coxswains.isNotEmpty) ...[
                      _RoleSection(
                        title: 'Coxswains',
                        memberships: coxswains,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (others.isNotEmpty) ...[
                      _RoleSection(
                        title: 'Other Members',
                        memberships: others,
                        color: Colors.grey,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Share join code to invite members')),
          );
        },
        backgroundColor: team?.primaryColorObj ?? Colors.blue,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }
}

class _RoleSection extends StatelessWidget {
  final String title;
  final List<Membership> memberships;
  final Color color;

  const _RoleSection({
    required this.title,
    required this.memberships,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...memberships.map((membership) {
          return _MemberCard(membership: membership, roleColor: color);
        }).toList(),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Membership membership;
  final Color roleColor;

  const _MemberCard({required this.membership, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return FutureBuilder<AppUser?>(
      future: userService.getUser(membership.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const SizedBox();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              // TODO: Navigate to member detail screen
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
                    backgroundColor: roleColor,
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
                            if (membership.customTitle != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  membership.customTitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: roleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (membership.role == MembershipRole.rower &&
                                membership.side != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSideColor(
                                    membership.side!,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  membership.side!.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getSideColor(membership.side!),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (user.hasInjury)
                    const Icon(Icons.warning, color: Colors.red, size: 24)
                  else
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getSideColor(String side) {
    switch (side.toLowerCase()) {
      case 'port':
        return Colors.red;
      case 'starboard':
        return Colors.green;
      case 'both':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
