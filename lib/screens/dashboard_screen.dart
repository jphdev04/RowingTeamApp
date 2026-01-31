import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/athlete_service.dart';
import '../services/team_service.dart';
import '../models/athlete.dart';
import '../models/team.dart';
import 'team_setup_screen.dart';
import 'roster_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'equipment_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final athleteService = AthleteService();
    final user = authService.currentUser;

    return FutureBuilder<Athlete?>(
      future: athleteService.getCurrentUserProfile(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Details: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out and Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final athlete = snapshot.data;

        if (athlete == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_off,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Profile Found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'User ID: ${user.uid}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This account exists but has no athlete profile in the database.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out and Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (athlete.role == 'coach') {
          return _CoachDashboard(athlete: athlete);
        } else {
          return _AthleteDashboard(athlete: athlete);
        }
      },
    );
  }
}

// Coach Dashboard
class _CoachDashboard extends StatelessWidget {
  final Athlete athlete;

  const _CoachDashboard({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final teamService = TeamService();

    return FutureBuilder<Team?>(
      future: teamService.getTeamByCoachId(athlete.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final team = snapshot.data;

        if (team == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const TeamSetupScreen()),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _DashboardScaffold(athlete: athlete, team: team, isCoach: true);
      },
    );
  }
}

// Athlete Dashboard
class _AthleteDashboard extends StatelessWidget {
  final Athlete athlete;

  const _AthleteDashboard({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final teamService = TeamService();

    if (athlete.teamId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('The Boathouse'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 80, color: Colors.grey),
                SizedBox(height: 24),
                Text(
                  'Not Assigned to a Team',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Please contact your coach to be added to the team roster.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FutureBuilder<Team?>(
      future: teamService.getTeam(athlete.teamId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final team = snapshot.data;

        return _DashboardScaffold(athlete: athlete, team: team, isCoach: false);
      },
    );
  }
}

// Main Dashboard Scaffold
// Main Dashboard Scaffold
class _DashboardScaffold extends StatefulWidget {
  final Athlete athlete;
  final Team? team;
  final bool isCoach;

  const _DashboardScaffold({
    required this.athlete,
    required this.team,
    required this.isCoach,
  });

  @override
  State<_DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<_DashboardScaffold> {
  late Team? currentTeam;

  @override
  void initState() {
    super.initState();
    currentTeam = widget.team;
  }

  // Refresh team data
  Future<void> _refreshTeam() async {
    if (currentTeam != null) {
      final teamService = TeamService();
      final updatedTeam = await teamService.getTeam(currentTeam!.id);
      if (mounted) {
        setState(() {
          currentTeam = updatedTeam;
        });
      }
    }
  }

  String _getDisplayName() {
    if (widget.athlete.role == 'coach') {
      return 'Coach ${widget.athlete.name}';
    }
    return widget.athlete.name;
  }

  @override
  Widget build(BuildContext context) {
    // Use team colors or defaults
    final primaryColor =
        currentTeam?.primaryColorObj ?? const Color(0xFF1976D2);
    final secondaryColor =
        currentTeam?.secondaryColorObj ?? const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header with boathouse icon
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
                    // Settings button in top right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: primaryColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(
                                  athlete: widget.athlete,
                                  team: currentTeam,
                                ),
                              ),
                            );
                            // Refresh team if settings were updated
                            if (result == true) {
                              await _refreshTeam();
                            }
                          },
                        ),
                      ],
                    ),
                    // Boathouse icon placeholder
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
                      _getDisplayName(),
                      style: TextStyle(
                        color: primaryColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentTeam != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        currentTeam!.name,
                        style: TextStyle(
                          color: primaryColor.computeLuminance() > 0.5
                              ? Colors.black54
                              : Colors.white70,
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
                      'Home',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (widget.isCoach) ...[
                      // Coach view
                      Row(
                        children: [
                          Expanded(
                            child: _DashboardCard(
                              title: 'Roster',
                              subtitle: 'Manage team members',
                              icon: Icons.people,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RosterScreen(
                                      teamId: currentTeam!.id,
                                      team: currentTeam,
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
                              subtitle: 'Boats, oars & gear',
                              icon: Icons.rowing,
                              color: primaryColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EquipmentScreen(
                                      teamId: currentTeam!.id,
                                      team: currentTeam,
                                      athlete: widget.athlete,
                                    ),
                                  ),
                                );
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
                              subtitle: 'View your stats',
                              icon: Icons.person,
                              color: primaryColor,
                              onTap: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SettingsScreen(
                                      athlete: widget.athlete,
                                      team: currentTeam,
                                    ),
                                  ),
                                );
                                // Refresh if profile was updated
                                if (result == true) {
                                  await _refreshTeam();
                                }
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EquipmentScreen(
                                      teamId: currentTeam!.id,
                                      team: currentTeam,
                                      athlete: widget.athlete,
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
                            subtitle: widget.isCoach
                                ? 'Create boat lineups'
                                : 'View lineups',
                            icon: Icons.sports,
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lineups page coming soon!'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardCard(
                            title: 'Workouts',
                            subtitle: widget.isCoach
                                ? 'Manage workouts'
                                : 'View workouts',
                            icon: Icons.fitness_center,
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Workouts page coming soon!'),
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
                            subtitle: widget.isCoach
                                ? 'Manage schedule'
                                : 'View schedule',
                            icon: Icons.calendar_today,
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Schedule page coming soon!'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardCard(
                            title: 'Announcements',
                            subtitle: widget.isCoach
                                ? 'Post updates'
                                : 'View updates',
                            icon: Icons.announcement,
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Announcements page coming soon!',
                                  ),
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
