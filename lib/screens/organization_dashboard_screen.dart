import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/membership_service.dart';
import '../services/organization_service.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import 'settings_screen.dart';
import 'equipment_screen.dart';
import 'organization_roster_screen.dart';
import 'team_selector_screen.dart';
import 'team_management_screen.dart';
import 'organization_settings_screen.dart';
import 'join_requests_screen.dart';

class OrganizationDashboardScreen extends StatefulWidget {
  const OrganizationDashboardScreen({super.key});

  @override
  State<OrganizationDashboardScreen> createState() =>
      _OrganizationDashboardScreenState();
}

class _OrganizationDashboardScreenState
    extends State<OrganizationDashboardScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _membershipService = MembershipService();
  final _orgService = OrganizationService();

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

            // Find current membership
            final currentMembership = memberships.firstWhere(
              (m) => m.id == user.currentMembershipId,
              orElse: () => memberships.first,
            );

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

                return _OrganizationDashboardContent(
                  user: user,
                  memberships: memberships,
                  currentMembership: currentMembership,
                  organization: organization,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _OrganizationDashboardContent extends StatelessWidget {
  final AppUser user;
  final List<Membership> memberships;
  final Membership currentMembership;
  final Organization? organization;

  const _OrganizationDashboardContent({
    required this.user,
    required this.memberships,
    required this.currentMembership,
    required this.organization,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6A1B9A); // Deep purple for org view

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
                    colors: [
                      organization?.primaryColorObj ?? primaryColor,
                      organization?.secondaryColorObj ??
                          primaryColor.withOpacity(0.7),
                    ],
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
                    // Top row: View switcher + Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // View switcher button
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
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Switch View',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () {
                            if (organization != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OrganizationSettingsScreen(
                                        organization: organization!,
                                        user: user,
                                        membership: currentMembership,
                                      ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Organization icon
                    Center(
                      child: Icon(
                        Icons.business,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Welcome message
                    const Text(
                      'Organization View',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (organization != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        organization!.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
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
                      'Organization Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // First row
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardCard(
                            title: 'All Members',
                            subtitle: 'Organization roster',
                            icon: Icons.people,
                            color:
                                organization?.primaryColorObj ??
                                const Color(0xFF6A1B9A),
                            onTap: () {
                              if (organization != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrganizationRosterScreen(
                                          organizationId: organization!.id,
                                          organization: organization,
                                        ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardCard(
                            title: 'Equipment',
                            subtitle: 'All gear',
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
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Second row
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardCard(
                            title: 'Teams',
                            subtitle: 'Manage teams',
                            icon: Icons.groups,
                            color: primaryColor,
                            onTap: () {
                              if (organization != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TeamManagementScreen(
                                      organization: organization!,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardCard(
                            title: 'Schedule',
                            subtitle: 'Organization calendar',
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
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Third row
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardCard(
                            title: 'Announcements',
                            subtitle: 'Organization-wide',
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardCard(
                            title: 'Join Requests',
                            subtitle: 'Approve members',
                            icon: Icons.person_add,
                            color:
                                organization?.primaryColorObj ??
                                const Color(0xFF6A1B9A),
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
