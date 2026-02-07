import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../services/organization_service.dart';
import '../services/team_service.dart';
import '../services/user_service.dart';
import 'main_shell.dart';

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

        // Non-admin memberships that are tied to a specific team
        final teamMemberships = memberships
            .where((m) => m.role != MembershipRole.admin && m.teamId != null)
            .toList();

        // Org-level memberships (athlete, boatman) that aren't admin
        final orgLevelMemberships = memberships
            .where((m) => m.role != MembershipRole.admin && m.teamId == null)
            .toList();

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

                // ── Admin: org-level view ─────────────────────────
                if (hasAdminRole) ...[
                  _ViewOption(
                    title: 'Organization View',
                    subtitle: 'Manage entire organization',
                    icon: Icons.business,
                    color: organization.primaryColorObj ?? Colors.deepPurple,
                    onTap: () => _switchToMembership(
                      context,
                      memberships.firstWhere(
                        (m) => m.role == MembershipRole.admin,
                      ),
                      teamOverrideId: null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Or view a specific team:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Show all teams in the org (admin can view any)
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

                      final adminMembership = memberships.firstWhere(
                        (m) => m.role == MembershipRole.admin,
                      );

                      return Column(
                        children: teams.map((team) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ViewOption(
                              title: team.name,
                              subtitle: 'View as Admin',
                              icon: Icons.groups,
                              color: team.primaryColorObj,
                              onTap: () => _switchToMembership(
                                context,
                                adminMembership,
                                teamOverrideId: team.id,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],

                // ── Non-admin team memberships ────────────────────
                if (teamMemberships.isNotEmpty) ...[
                  if (hasAdminRole) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Your team memberships:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ...teamMemberships.map((membership) {
                    return FutureBuilder<Team?>(
                      future: teamService.getTeam(membership.teamId!),
                      builder: (context, teamSnapshot) {
                        final team = teamSnapshot.data;
                        final teamName = team?.name ?? 'Loading...';
                        final teamColor = team?.primaryColorObj ?? Colors.blue;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ViewOption(
                            title: teamName,
                            subtitle: _getRoleLabel(membership.role),
                            icon: Icons.groups,
                            color: teamColor,
                            onTap: () =>
                                _switchToMembership(context, membership),
                          ),
                        );
                      },
                    );
                  }),
                ],

                // ── Org-level non-admin memberships (athlete, boatman) ──
                if (orgLevelMemberships.isNotEmpty) ...[
                  if (hasAdminRole || teamMemberships.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
                  ...orgLevelMemberships.map((membership) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ViewOption(
                        title: _getRoleLabel(membership.role),
                        subtitle: organization.name,
                        icon: _getRoleIcon(membership.role),
                        color: organization.primaryColorObj ?? Colors.teal,
                        onTap: () => _switchToMembership(context, membership),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Switch to a membership and navigate to MainShell
  Future<void> _switchToMembership(
    BuildContext context,
    Membership membership, {
    String? teamOverrideId,
  }) async {
    await UserService().updateCurrentContext(
      user.id,
      organizationId,
      membership.id,
    );

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainShell(teamOverrideId: teamOverrideId),
        ),
      );
    }
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

  IconData _getRoleIcon(MembershipRole role) {
    switch (role) {
      case MembershipRole.admin:
        return Icons.admin_panel_settings;
      case MembershipRole.coach:
        return Icons.sports;
      case MembershipRole.rower:
        return Icons.rowing;
      case MembershipRole.coxswain:
        return Icons.record_voice_over;
      case MembershipRole.boatman:
        return Icons.build;
      case MembershipRole.athlete:
        return Icons.person;
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
