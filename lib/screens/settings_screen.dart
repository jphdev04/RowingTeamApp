import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/athlete_service.dart';
import '../services/team_service.dart';
import '../models/athlete.dart';
import '../models/team.dart';
import '../widgets/team_header.dart';
import 'team_settings_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final athleteService = AthleteService();
    final teamService = TeamService();
    final user = authService.currentUser;

    return FutureBuilder<Athlete?>(
      future: athleteService.getCurrentUserProfile(user!.uid),
      builder: (context, athleteSnapshot) {
        if (athleteSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final athlete = athleteSnapshot.data;

        return FutureBuilder<Team?>(
          future: athlete?.teamId != null
              ? teamService.getTeam(athlete!.teamId!)
              : (athlete?.role == 'coach'
                    ? teamService.getTeamByCoachId(athlete!.id)
                    : Future.value(null)),
          builder: (context, teamSnapshot) {
            final team = teamSnapshot.data;

            return Scaffold(
              backgroundColor: Colors.grey[50],
              body: Column(
                children: [
                  TeamHeader(
                    team: team,
                    title: 'Settings',
                    subtitle: athlete?.name ?? 'Profile',
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color:
                              (team?.primaryColorObj.computeLuminance() ?? 0) >
                                  0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        // User profile section
                        Container(
                          padding: const EdgeInsets.all(24),
                          color: Colors.blue[50],
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  athlete?.name.isNotEmpty == true
                                      ? athlete!.name[0].toUpperCase()
                                      : user.email?[0].toUpperCase() ?? '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                athlete?.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              if (athlete != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(athlete.role),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    athlete.role.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Settings options
                        if (athlete?.role == 'coach') ...[
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Team Management',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          FutureBuilder<Team?>(
                            future: TeamService().getTeamByCoachId(athlete!.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return ListTile(
                                  leading: const Icon(Icons.palette),
                                  title: const Text('Team Settings'),
                                  subtitle: const Text(
                                    'Change team name and colors',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    final result = await Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TeamSettingsScreen(
                                                  team: snapshot.data!,
                                                ),
                                          ),
                                        );
                                    // Refresh if team was updated
                                    if (result == true) {
                                      setState(() {});
                                    }
                                  },
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const Divider(),
                        ],

                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Personal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Edit Profile'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon!')),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('Notifications'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon!')),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.help),
                          title: const Text('Help & Support'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon!')),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('About'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'The Boathouse',
                              applicationVersion: '1.0.0',
                              applicationLegalese: '© 2026 The Boathouse',
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Sign Out'),
                                  content: const Text(
                                    'Are you sure you want to sign out?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Sign Out'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                await authService.signOut();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              'Sign Out',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'coach':
        return Colors.purple;
      case 'coxswain':
        return Colors.orange;
      case 'rower':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
