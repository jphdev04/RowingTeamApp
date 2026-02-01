import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../services/organization_service.dart';
import '../services/team_service.dart';
import '../services/user_service.dart';
import 'organization_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'team_dashboard_wrapper.dart';

class TeamSelectorScreen extends StatelessWidget {
  final AppUser user;
  final List<Membership> memberships;

  const TeamSelectorScreen({
    super.key,
    required this.user,
    required this.memberships,
  });

  @override
  Widget build(BuildContext context) {
    // Group memberships by organization
    final orgGroups = <String, List<Membership>>{};
    for (final membership in memberships) {
      if (!orgGroups.containsKey(membership.organizationId)) {
        orgGroups[membership.organizationId] = [];
      }
      orgGroups[membership.organizationId]!.add(membership);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.rowing, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Welcome, ${user.name}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select which team or organization to view',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: orgGroups.entries.map((entry) {
                    return _OrganizationSection(
                      user: user,
                      organizationId: entry.key,
                      memberships: entry.value,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizationSection extends StatelessWidget {
  final AppUser user;
  final String organizationId;
  final List<Membership> memberships;

  const _OrganizationSection({
    required this.user,
    required this.organizationId,
    required this.memberships,
  });

  @override
  Widget build(BuildContext context) {
    final orgService = OrganizationService();
    final teamService = TeamService();

    return FutureBuilder<Organization?>(
      future: orgService.getOrganization(organizationId),
      builder: (context, orgSnapshot) {
        if (orgSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final organization = orgSnapshot.data;
        if (organization == null) return const SizedBox();

        final hasAdminRole = memberships.any(
          (m) => m.role == MembershipRole.admin,
        );

        print('DEBUG: Organization loaded: ${organization.name}');
        print('DEBUG: hasAdminRole: $hasAdminRole');
        print('DEBUG: Number of memberships: ${memberships.length}');
        for (final m in memberships) {
          print('DEBUG: Membership role: ${m.role}');
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organization.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Organization-level view (for admins)
                if (hasAdminRole) ...[
                  _ViewOption(
                    title: 'Organization View',
                    subtitle: 'Manage entire organization',
                    icon: Icons.business,
                    color: Colors.deepPurple,
                    onTap: () async {
                      final adminMembership = memberships.firstWhere(
                        (m) => m.role == MembershipRole.admin,
                      );

                      // Update user's current context
                      await UserService().updateCurrentContext(
                        user.id,
                        organizationId,
                        adminMembership.id,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                const OrganizationDashboardScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Or select a specific team:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 0),
                  Builder(
                    builder: (context) {
                      print(
                        'DEBUG: Creating StreamBuilder with orgId: $organizationId',
                      );
                      print(
                        'DEBUG: teamService exists: ${teamService != null}',
                      );
                      return const SizedBox.shrink();
                    },
                  ),
                  StreamBuilder<List<Team>>(
                    stream: teamService.getOrganizationTeams(organizationId),
                    builder: (context, teamsSnapshot) {
                      if (teamsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final teams = teamsSnapshot.data ?? [];

                      if (teams.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No teams yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return Column(
                        children: teams.map((team) {
                          final adminMembership = memberships.firstWhere(
                            (m) => m.role == MembershipRole.admin,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ViewOption(
                              title: team.name,
                              subtitle: 'View as Admin',
                              icon: Icons.groups,
                              color: team.primaryColorObj,
                              onTap: () async {
                                await UserService().updateCurrentContext(
                                  user.id,
                                  organizationId,
                                  adminMembership.id,
                                );

                                if (context.mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => TeamDashboardView(
                                        team: team,
                                        membership: adminMembership,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],

                // Teams
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRoleLabel(MembershipRole role) {
    switch (role) {
      case MembershipRole.admin:
        return 'Administrator';
      case MembershipRole.coach:
        return 'Coach';
      case MembershipRole.rower:
        return 'Rower';
      case MembershipRole.coxswain:
        return 'Coxswain';
      case MembershipRole.boatman:
        return 'Boatman';
      case MembershipRole.athlete:
        return 'Athlete';
    }
  }
}

class _ViewOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ViewOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
}
