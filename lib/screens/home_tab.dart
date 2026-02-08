import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../widgets/dashboard_card.dart';
import 'equipment_screen.dart';
import 'report_damage_screen.dart';
import 'roster_screen.dart';
import 'organization_roster_screen.dart';
import 'team_management_screen.dart';
import 'join_requests_screen.dart';

class HomeTab extends StatelessWidget {
  final AppUser user;
  final List<Membership> memberships;
  final Membership currentMembership;
  final Organization? organization;
  final Team? team;

  const HomeTab({
    super.key,
    required this.user,
    required this.memberships,
    required this.currentMembership,
    required this.organization,
    required this.team,
  });

  MembershipRole get role => currentMembership.role;

  Color get primaryColor =>
      team?.primaryColorObj ??
      organization?.primaryColorObj ??
      const Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 8),
        ..._buildCardsForRole(context),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildCardsForRole(BuildContext context) {
    switch (role) {
      case MembershipRole.admin:
        if (team != null) return _buildCoachCards(context);
        return _buildAdminCards(context);
      case MembershipRole.coach:
        return _buildCoachCards(context);
      case MembershipRole.boatman:
        return _buildBoatmanCards(context);
      case MembershipRole.rower:
        return _buildRowerCards(context);
      case MembershipRole.coxswain:
        return _buildCoxswainCards(context);
      case MembershipRole.athlete:
        return _buildAthleteCards(context);
    }
  }

  // ── Admin (org-level) ──────────────────────────────────────────
  List<Widget> _buildAdminCards(BuildContext context) {
    return [
      _cardRow(
        DashboardCard(
          title: 'All Members',
          subtitle: 'Organization roster',
          icon: Icons.people,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrganizationRosterScreen(
                    organizationId: organization!.id,
                    organization: organization,
                  ),
                ),
              );
            }
          },
        ),
        DashboardCard(
          title: 'Equipment',
          subtitle: 'All org equipment',
          icon: Icons.rowing,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EquipmentScreen(
                    organizationId: organization!.id,
                    team: null,
                    currentMembership: currentMembership,
                  ),
                ),
              );
            }
          },
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Manage Teams',
          subtitle: 'All org teams',
          icon: Icons.groups,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      TeamManagementScreen(organization: organization!),
                ),
              );
            }
          },
        ),
        DashboardCard(
          title: 'Report Damage',
          subtitle: 'Equipment issues',
          icon: Icons.warning_amber,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReportDamageScreen(
                    organizationId: organization!.id,
                    userId: user.id,
                    userName: user.name,
                    organization: organization,
                    team: team,
                  ),
                ),
              );
            }
          },
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Org Calendar',
          subtitle: 'Manage schedule',
          icon: Icons.event,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Org calendar'),
        ),
        DashboardCard(
          title: 'Announcements',
          subtitle: 'Post org-wide',
          icon: Icons.campaign,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Announcements'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Join Requests',
          subtitle: 'Approve members',
          icon: Icons.person_add,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => JoinRequestsScreen(
                    organizationId: organization!.id,
                    organization: organization!,
                  ),
                ),
              );
            }
          },
        ),
        null,
      ),
    ];
  }

  // ── Coach ──────────────────────────────────────────────────────
  List<Widget> _buildCoachCards(BuildContext context) {
    return [
      _cardRow(
        DashboardCard(
          title: 'Team Roster',
          subtitle: 'Manage members',
          icon: Icons.people,
          color: primaryColor,
          onTap: () {
            if (organization != null && team != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RosterScreen(
                    organizationId: organization!.id,
                    teamId: team!.id,
                    team: team!,
                  ),
                ),
              );
            }
          },
        ),
        DashboardCard(
          title: 'Equipment',
          subtitle: 'Team gear',
          icon: Icons.rowing,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EquipmentScreen(
                    organizationId: organization!.id,
                    team: team,
                    currentMembership: currentMembership,
                  ),
                ),
              );
            }
          },
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Report Damage',
          subtitle: 'Equipment issues',
          icon: Icons.warning_amber,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReportDamageScreen(
                    organizationId: organization!.id,
                    userId: user.id,
                    userName: user.name,
                    organization: organization,
                    team: team,
                  ),
                ),
              );
            }
          },
        ),
        DashboardCard(
          title: 'Manage Lineups',
          subtitle: 'Create lineups',
          icon: Icons.sports,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Lineups'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Assign Workouts',
          subtitle: 'Team workouts',
          icon: Icons.fitness_center,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Workouts'),
        ),
        DashboardCard(
          title: 'Team Schedule',
          subtitle: 'Manage schedule',
          icon: Icons.event,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Schedule'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Announcements',
          subtitle: 'Post updates',
          icon: Icons.campaign,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Announcements'),
        ),
        null,
      ),
    ];
  }

  // ── Boatman ────────────────────────────────────────────────────
  List<Widget> _buildBoatmanCards(BuildContext context) {
    return [
      _cardRow(
        DashboardCard(
          title: 'Unaddressed Reports',
          subtitle: 'Pending damage',
          icon: Icons.report_problem,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Unaddressed reports'),
        ),
        DashboardCard(
          title: 'Maintenance Log',
          subtitle: 'Current log',
          icon: Icons.build,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Maintenance log'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'All Equipment',
          subtitle: 'Manage / view',
          icon: Icons.rowing,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EquipmentScreen(
                    organizationId: organization!.id,
                    team: null,
                    currentMembership: currentMembership,
                  ),
                ),
              );
            }
          },
        ),
        DashboardCard(
          title: 'Org Schedule',
          subtitle: 'View schedule',
          icon: Icons.event,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Schedule'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Announcements',
          subtitle: 'Org updates',
          icon: Icons.campaign,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Announcements'),
        ),
        null,
      ),
    ];
  }

  // ── Rower ──────────────────────────────────────────────────────
  List<Widget> _buildRowerCards(BuildContext context) {
    return [
      _cardRow(
        DashboardCard(
          title: 'Lineups',
          subtitle: 'View lineups',
          icon: Icons.sports,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Lineups'),
        ),
        DashboardCard(
          title: 'Report Damage',
          subtitle: 'Equipment issues',
          icon: Icons.warning_amber,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReportDamageScreen(
                    organizationId: organization!.id,
                    userId: user.id,
                    userName: user.name,
                    organization: organization,
                    team: team,
                  ),
                ),
              );
            }
          },
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Team Schedule',
          subtitle: 'Racing & events',
          icon: Icons.event,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Team schedule'),
        ),
        DashboardCard(
          title: 'Team News',
          subtitle: 'Announcements',
          icon: Icons.campaign,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Team announcements'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Org Schedule',
          subtitle: 'Organization events',
          icon: Icons.calendar_today,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Org schedule'),
        ),
        DashboardCard(
          title: 'Org News',
          subtitle: 'Org announcements',
          icon: Icons.announcement,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Org announcements'),
        ),
      ),
    ];
  }

  List<Widget> _buildCoxswainCards(BuildContext context) =>
      _buildRowerCards(context);

  // ── Individual Athlete ─────────────────────────────────────────
  List<Widget> _buildAthleteCards(BuildContext context) {
    return [
      _cardRow(
        DashboardCard(
          title: 'Equipment',
          subtitle: 'Sign out gear',
          icon: Icons.rowing,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EquipmentScreen(
                    organizationId: organization!.id,
                    team: null,
                    currentMembership: currentMembership,
                  ),
                ),
              );
            }
          },
        ),
        DashboardCard(
          title: 'Report Damage',
          subtitle: 'Equipment issues',
          icon: Icons.warning_amber,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReportDamageScreen(
                    organizationId: organization!.id,
                    userId: user.id,
                    userName: user.name,
                    organization: organization,
                    team: null,
                  ),
                ),
              );
            }
          },
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Org Schedule',
          subtitle: 'Organization events',
          icon: Icons.event,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Org schedule'),
        ),
        DashboardCard(
          title: 'Announcements',
          subtitle: 'Org updates',
          icon: Icons.campaign,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Announcements'),
        ),
      ),
    ];
  }

  Widget _cardRow(DashboardCard first, DashboardCard? second) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        if (second != null)
          Expanded(child: second)
        else
          const Expanded(child: SizedBox()),
      ],
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon!')));
  }
}
