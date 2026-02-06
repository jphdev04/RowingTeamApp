import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/membership.dart';
import '../services/team_service.dart';
import '../services/join_request_service.dart';
import '../services/membership_service.dart';
import '../services/user_service.dart';
import 'dashboard_screen.dart';

class SelectTeamScreen extends StatefulWidget {
  final AppUser user;
  final Organization organization;

  const SelectTeamScreen({
    super.key,
    required this.user,
    required this.organization,
  });

  @override
  State<SelectTeamScreen> createState() => _SelectTeamScreenState();
}

class _SelectTeamScreenState extends State<SelectTeamScreen> {
  final _teamService = TeamService();
  final _joinRequestService = JoinRequestService();
  final _membershipService = MembershipService();
  final _userService = UserService();
  final _messageController = TextEditingController();

  MembershipRole _selectedRole = MembershipRole.athlete;
  Team? _selectedTeam;
  bool _isLoading = false;

  /// Roles that require a team selection
  static const _teamRequiredRoles = {
    MembershipRole.coach,
    MembershipRole.rower,
    MembershipRole.coxswain,
  };

  bool get _requiresTeam => _teamRequiredRoles.contains(_selectedRole);

  /// All roles available during join
  static const _allRoles = [
    MembershipRole.rower,
    MembershipRole.coxswain,
    MembershipRole.coach,
    MembershipRole.athlete,
    MembershipRole.boatman,
    MembershipRole.admin,
  ];

  void _onRoleChanged(MembershipRole? role) {
    if (role == null) return;
    setState(() {
      _selectedRole = role;
      // Clear team if the new role doesn't need one
      if (!_teamRequiredRoles.contains(role)) {
        _selectedTeam = null;
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    // Validate team selection for roles that require it
    if (_requiresTeam && _selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a team for this role.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.organization.requiresApproval) {
        await _joinRequestService.createJoinRequest(
          userId: widget.user.id,
          userName: widget.user.name,
          userEmail: widget.user.email,
          organizationId: widget.organization.id,
          teamId: _selectedTeam?.id,
          requestedRole: _selectedRole,
          message: _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : null,
        );

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Request Submitted'),
              content: Text(
                'Your request to join ${widget.organization.name} as '
                '${_roleDisplayName(_selectedRole).toLowerCase()}'
                '${_selectedTeam != null ? ' on ${_selectedTeam!.name}' : ''}'
                ' has been submitted.\n\nAn admin will review it shortly.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        final membership = await _membershipService.createMembership(
          userId: widget.user.id,
          organizationId: widget.organization.id,
          teamId: _selectedTeam?.id,
          role: _selectedRole,
        );

        await _userService.updateCurrentContext(
          widget.user.id,
          widget.organization.id,
          membership.id,
        );

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Organization')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Joining ${widget.organization.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your role. You can request additional roles later from the dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Role selection (first)
            const Text(
              'Role',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MembershipRole>(
              value: _selectedRole,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _allRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(_roleDisplayName(role)),
                );
              }).toList(),
              onChanged: _onRoleChanged,
            ),

            // Admin info banner
            if (_selectedRole == MembershipRole.admin) ...[
              const SizedBox(height: 12),
              _buildInfoBanner(
                icon: Icons.info_outline,
                color: Colors.amber,
                text: 'Admin requests require approval from a current admin.',
              ),
            ],

            const SizedBox(height: 24),

            // Team selection (only for team-specific roles)
            if (_requiresTeam) ...[
              const Text(
                'Team',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Team>>(
                stream: _teamService.getOrganizationTeams(
                  widget.organization.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final teams = snapshot.data ?? [];

                  if (teams.isEmpty) {
                    return _buildInfoBanner(
                      icon: Icons.info_outline,
                      color: Colors.grey,
                      text:
                          'No teams available yet. Ask an admin to create a team first.',
                    );
                  }

                  return DropdownButtonFormField<Team?>(
                    key: ValueKey('team-${_selectedRole.name}'),
                    value: _selectedTeam,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a team',
                    ),
                    items: teams.map((team) {
                      return DropdownMenuItem<Team?>(
                        value: team,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedTeam = value);
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Summary card
            _buildSummaryCard(),

            const SizedBox(height: 24),

            // Optional message
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message to Admin (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Introduce yourself or explain why you want to join',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.organization.requiresApproval
                          ? 'Submit Request'
                          : 'Join Now',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            Icons.business,
            'Organization',
            widget.organization.name,
          ),
          const SizedBox(height: 4),
          _buildSummaryRow(
            Icons.badge,
            'Role',
            _roleDisplayName(_selectedRole),
          ),
          if (_requiresTeam) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              Icons.groups,
              'Team',
              _selectedTeam?.name ?? 'Not selected',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _roleDisplayName(MembershipRole role) {
    switch (role) {
      case MembershipRole.admin:
        return 'Admin';
      case MembershipRole.coach:
        return 'Coach';
      case MembershipRole.rower:
        return 'Team Rower';
      case MembershipRole.coxswain:
        return 'Coxswain';
      case MembershipRole.athlete:
        return 'Individual Athlete';
      case MembershipRole.boatman:
        return 'Boatman';
    }
  }
}
