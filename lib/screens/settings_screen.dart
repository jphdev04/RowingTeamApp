import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../widgets/team_header.dart';
import 'edit_profile_screen.dart';
import 'team_settings_screen.dart';
import 'organization_settings_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppUser user;
  final Membership membership;
  final Organization? organization;
  final Team? team;

  const SettingsScreen({
    super.key,
    required this.user,
    required this.membership,
    this.organization,
    this.team,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isAdmin = widget.membership.role == MembershipRole.admin;
    final isCoach = widget.membership.role == MembershipRole.coach || isAdmin;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TeamHeader(
            team: widget.team,
            organization: widget.team == null ? widget.organization : null,
            title: 'Settings',
            subtitle: widget.user.name,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: _headerTextColor,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // User profile card
                _buildProfileCard(),

                const SizedBox(height: 16),

                // Team Management section (for coaches/admins with teams)
                if (isCoach && widget.team != null) ...[
                  _buildSectionHeader('Team Management'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.palette),
                          title: const Text('Team Settings'),
                          subtitle: const Text('Change team name and colors'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TeamSettingsScreen(
                                  team: widget.team!,
                                  organization: widget.organization,
                                ),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Organization Management (for admins)
                if (isAdmin && widget.organization != null) ...[
                  _buildSectionHeader('Organization Management'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.business),
                          title: const Text('Organization Settings'),
                          subtitle: const Text('Manage organization details'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrganizationSettingsScreen(
                                      organization: widget.organization!,
                                      user: widget.user,
                                      membership: widget.membership,
                                    ),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(() {});
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('Manage Members'),
                          subtitle: const Text(
                            'View and approve join requests',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon!')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.vpn_key),
                          title: const Text('Join Code'),
                          subtitle: Text(
                            widget.organization?.joinCode ?? 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              if (widget.organization != null) {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: widget.organization!.joinCode,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Join code copied to clipboard!',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Personal section
                _buildSectionHeader('Personal'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                user: widget.user,
                                membership: widget.membership,
                                team: widget.team,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                      ),
                      const Divider(height: 1),
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
                      const Divider(height: 1),
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

                // Sign Out
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _showSignOutDialog(context, authService),
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
  }

  Color get _headerTextColor {
    final luminance =
        widget.team?.primaryColorObj.computeLuminance() ??
        widget.organization?.primaryColorObj.computeLuminance() ??
        0;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildProfileCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: _profileAvatarColor,
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.user.email,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(widget.membership.role),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.membership.customTitle ??
                    widget.membership.role.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.organization != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.organization!.name,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            if (widget.team != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.team!.name,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _profileAvatarColor {
    return widget.team?.primaryColorObj ??
        widget.organization?.primaryColorObj ??
        Colors.blue;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(
    BuildContext context,
    AuthService authService,
  ) async {
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
      await authService.signOut();
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
