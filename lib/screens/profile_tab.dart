import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileTab extends StatelessWidget {
  final AppUser user;
  final List<Membership> memberships;
  final Membership currentMembership;
  final Organization? organization;
  final Team? team;

  const ProfileTab({
    super.key,
    required this.user,
    required this.memberships,
    required this.currentMembership,
    required this.organization,
    required this.team,
  });

  Color get primaryColor =>
      team?.primaryColorObj ?? organization?.primaryColorObj ?? Colors.blue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(currentMembership.role),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentMembership.customTitle ??
                        currentMembership.role.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (organization != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    organization!.name,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
                if (team != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    team!.name,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Actions
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.chevron_right),
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
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
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
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'The Boathouse',
                    applicationVersion: '2.0.0',
                    applicationLegalese: '© 2026 The Boathouse',
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Sign out
        OutlinedButton.icon(
          onPressed: () => _showSignOutDialog(context),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.red),
          ),
        ),

        const SizedBox(height: 24),
      ],
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
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

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
}
