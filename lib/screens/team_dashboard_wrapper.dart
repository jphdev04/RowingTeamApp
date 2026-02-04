import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/membership_service.dart';
import '../services/organization_service.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import 'settings_screen.dart';
import 'equipment_screen.dart';
import 'roster_screen.dart';
import 'team_selector_screen.dart';
import 'report_damage_screen.dart';

class TeamDashboardView extends StatelessWidget {
  final Team team;
  final Membership membership;

  const TeamDashboardView({
    super.key,
    required this.team,
    required this.membership,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userService = UserService();
    final membershipService = MembershipService();
    final orgService = OrganizationService();
    final userId = authService.currentUser!.uid;

    return StreamBuilder<AppUser?>(
      stream: userService.getUserStream(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = userSnapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Error loading user')),
          );
        }

        return StreamBuilder<List<Membership>>(
          stream: membershipService.getUserMemberships(userId),
          builder: (context, membershipsSnapshot) {
            if (membershipsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final memberships = membershipsSnapshot.data ?? [];

            return FutureBuilder<Organization?>(
              future: orgService.getOrganization(membership.organizationId),
              builder: (context, orgSnapshot) {
                final organization = orgSnapshot.data;

                return _TeamDashboardContent(
                  user: user,
                  memberships: memberships,
                  currentMembership: membership,
                  organization: organization,
                  team: team,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TeamDashboardContent extends StatelessWidget {
  final AppUser user;
  final List<Membership> memberships;
  final Membership currentMembership;
  final Organization? organization;
  final Team team;

  const _TeamDashboardContent({
    required this.user,
    required this.memberships,
    required this.currentMembership,
    required this.organization,
    required this.team,
  });

  bool get isAdmin => currentMembership.role == MembershipRole.admin;
  bool get isCoach => currentMembership.role == MembershipRole.coach || isAdmin;

  String _getRoleDisplayName() {
    if (currentMembership.customTitle != null) {
      return currentMembership.customTitle!;
    }

    switch (currentMembership.role) {
      case MembershipRole.coach:
        return 'Coach ${user.name}';
      case MembershipRole.admin:
        return user.name;
      default:
        return user.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = team.primaryColorObj;
    final secondaryColor = team.secondaryColorObj;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).padding.top + 16,
                  24,
                  32,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
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
                    // Top row: Switch view + Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (memberships.length > 1 || isAdmin)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => TeamSelectorScreen(
                                    user: user,
                                    memberships: memberships,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.swap_horiz,
                              color: primaryColor.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            label: Text(
                              'Switch',
                              style: TextStyle(
                                color: primaryColor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          )
                        else
                          const SizedBox(),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: primaryColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(
                                  user: user,
                                  membership: currentMembership,
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

                    // Boathouse icon
                    Center(
                      child: Icon(
                        Icons.house_outlined,
                        size: 60,
                        color: primaryColor.computeLuminance() > 0.5
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Welcome message
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: primaryColor.computeLuminance() > 0.5
                            ? Colors.black54
                            : Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRoleDisplayName(),
                      style: TextStyle(
                        color: primaryColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Team name (not organization)
                    const SizedBox(height: 8),
                    Text(
                      team.name,
                      style: TextStyle(
                        color: primaryColor.computeLuminance() > 0.5
                            ? Colors.black54
                            : Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (organization != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        organization!.name,
                        style: TextStyle(
                          color: primaryColor.computeLuminance() > 0.5
                              ? Colors.black.withOpacity(0.4)
                              : Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Main navigation cards
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isCoach) ...[
                      // Coach/Admin view
                      Row(
                        children: [
                          Expanded(
                            child: _DashboardCard(
                              title: 'Roster',
                              subtitle: 'Manage members',
                              icon: Icons.people,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RosterScreen(
                                      organizationId: organization!.id,
                                      teamId: team.id,
                                      team: team,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Equipment',
                              subtitle: 'Manage gear',
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
                        ],
                      ),
                    ] else ...[
                      // Athlete view
                      Row(
                        children: [
                          Expanded(
                            child: _DashboardCard(
                              title: 'My Profile',
                              subtitle: 'View stats',
                              icon: Icons.person,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SettingsScreen(
                                      user: user,
                                      membership: currentMembership,
                                      organization: organization,
                                      team: team,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Report Damage',
                              subtitle: 'Equipment issues',
                              icon: Icons.warning,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ReportDamageScreen(
                                      organizationId: organization!.id,
                                      userId: user.id,
                                      userName: user.name,
                                      team: team,
                                      organization: organization,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _DashboardCard(
                            title: 'Lineups',
                            subtitle: isCoach
                                ? 'Create lineups'
                                : 'View lineups',
                            icon: Icons.sports,
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lineups coming soon!'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardCard(
                            title: 'Workouts',
                            subtitle: isCoach
                                ? 'Assign workouts'
                                : 'View workouts',
                            icon: Icons.fitness_center,
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Workouts coming soon!'),
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
                          child: _DashboardCard(
                            title: 'Schedule',
                            subtitle: isCoach
                                ? 'Manage schedule'
                                : 'View schedule',
                            icon: Icons.calendar_today,
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Schedule coming soon!'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardCard(
                            title: 'Announcements',
                            subtitle: isCoach ? 'Post updates' : 'View updates',
                            icon: Icons.announcement,
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Announcements coming soon!'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
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
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
