import 'package:flutter/material.dart';
import 'package:hello_rowing/screens/edit_profile_screen.dart';
import 'package:hello_rowing/screens/report_damage_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/membership_service.dart';
import '../services/organization_service.dart';
import '../services/team_service.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import 'settings_screen.dart';
import 'equipment_screen.dart';
import 'team_selector_screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _membershipService = MembershipService();
  final _orgService = OrganizationService();
  final _teamService = TeamService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser!.uid;

    return StreamBuilder<AppUser?>(
      stream: _userService.getUserStream(userId),
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
          stream: _membershipService.getUserMemberships(userId),
          builder: (context, membershipsSnapshot) {
            if (membershipsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final memberships = membershipsSnapshot.data ?? [];

            if (memberships.isEmpty) {
              return _buildEmptyState(context, user);
            }

            Membership currentMembership;
            if (user.currentMembershipId != null) {
              currentMembership = memberships.firstWhere(
                (m) => m.id == user.currentMembershipId,
                orElse: () => memberships.first,
              );
            } else {
              currentMembership = memberships.first;
            }

            return FutureBuilder<Organization?>(
              future: _orgService.getOrganization(
                currentMembership.organizationId,
              ),
              builder: (context, orgSnapshot) {
                if (orgSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final organization = orgSnapshot.data;
                final organizationId = organization!.id;

                String? teamIdToLoad = currentMembership.teamId;

                final modalRoute = ModalRoute.of(context);
                if (teamIdToLoad == null &&
                    currentMembership.role == MembershipRole.admin &&
                    modalRoute?.settings.arguments != null) {
                  final args =
                      modalRoute!.settings.arguments as Map<String, dynamic>?;
                  teamIdToLoad = args?['teamId'] as String?;
                }

                if (teamIdToLoad != null) {
                  return FutureBuilder<Team?>(
                    future: _teamService.getTeam(teamIdToLoad),
                    builder: (context, teamSnapshot) {
                      final team = teamSnapshot.data;

                      return _DashboardContent(
                        user: user,
                        memberships: memberships,
                        currentMembership: currentMembership,
                        organization: organization,
                        organizationId: organizationId,
                        team: team,
                        onMembershipChanged: (newMembership) async {
                          await _userService.updateCurrentContext(
                            userId,
                            newMembership.organizationId,
                            newMembership.id,
                          );
                        },
                      );
                    },
                  );
                } else {
                  return _DashboardContent(
                    user: user,
                    memberships: memberships,
                    currentMembership: currentMembership,
                    organization: organization,
                    organizationId: organizationId,
                    team: null,
                    onMembershipChanged: (newMembership) async {
                      await _userService.updateCurrentContext(
                        userId,
                        newMembership.organizationId,
                        newMembership.id,
                      );
                    },
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppUser user) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Top bar with sign out
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () => _showSignOutDialog(context),
                  icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),

              const Spacer(),

              const Icon(Icons.house_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Welcome to The Boathouse',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'You haven\'t joined any organizations yet.\nGet started by joining or creating one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OnboardingScreen(user: user),
                      ),
                    );
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text(
                    'Join or Create an Organization',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await _authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

class _DashboardContent extends StatelessWidget {
  final AppUser user;
  final List<Membership> memberships;
  final Membership currentMembership;
  final Organization? organization;
  final Team? team;
  final Function(Membership) onMembershipChanged;
  final String organizationId;

  const _DashboardContent({
    required this.user,
    required this.memberships,
    required this.currentMembership,
    required this.organization,
    required this.team,
    required this.onMembershipChanged,
    required this.organizationId,
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
        return 'Admin ${user.name}';
      default:
        return user.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = team?.primaryColorObj ?? const Color(0xFF1976D2);
    final secondaryColor = team?.secondaryColorObj ?? const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (memberships.length > 1 ||
                            currentMembership.role == MembershipRole.admin)
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
                    if (organization != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        organization!.name,
                        style: TextStyle(
                          color: primaryColor.computeLuminance() > 0.5
                              ? Colors.black54
                              : Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (team != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        team!.name,
                        style: TextStyle(
                          color: primaryColor.computeLuminance() > 0.5
                              ? Colors.black.withOpacity(0.6)
                              : Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
                    if (isCoach || isAdmin) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _DashboardCard(
                              title: 'Roster',
                              subtitle: 'Manage members',
                              icon: Icons.people,
                              color: primaryColor,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Roster coming soon!'),
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
                                    builder: (context) => EditProfileScreen(
                                      user: user,
                                      membership: currentMembership,
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
                              subtitle: 'Report damage',
                              icon: Icons.warning,
                              color: primaryColor,
                              onTap: () {
                                debugPrint("Dashboard team: ${team?.name}");
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ReportDamageScreen(
                                      userId: user.id,
                                      organization: organization,
                                      organizationId: organizationId,
                                      userName: user.name,
                                      team: team,
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

class _RoleSwitcher extends StatelessWidget {
  final List<Membership> memberships;
  final Membership currentMembership;
  final Function(Membership) onChanged;
  final Color textColor;

  const _RoleSwitcher({
    required this.memberships,
    required this.currentMembership,
    required this.onChanged,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Membership>(
      value: currentMembership,
      dropdownColor: Colors.white,
      underline: Container(),
      icon: Icon(Icons.expand_more, color: textColor),
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      items: memberships.map((membership) {
        return DropdownMenuItem<Membership>(
          value: membership,
          child: Text(
            '${membership.displayName}',
            style: const TextStyle(color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: (membership) {
        if (membership != null) {
          onChanged(membership);
        }
      },
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
