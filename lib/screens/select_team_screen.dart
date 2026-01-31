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

  Team? _selectedTeam;
  MembershipRole _selectedRole = MembershipRole.rower;
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);

    try {
      if (widget.organization.requiresApproval) {
        // Create join request
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
              content: const Text(
                'Your request to join has been submitted. An admin will review it shortly.',
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
        // Auto-approve - create membership directly
        final membership = await _membershipService.createMembership(
          userId: widget.user.id,
          organizationId: widget.organization.id,
          teamId: _selectedTeam?.id,
          role: _selectedRole,
        );

        // Update user's current context
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
            Text(
              'Joining ${widget.organization.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Team selection
            StreamBuilder<List<Team>>(
              stream: _teamService.getOrganizationTeams(widget.organization.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teams = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Team (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (teams.isEmpty)
                      const Text(
                        'No teams available yet. You can join as an individual member.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      DropdownButtonFormField<Team?>(
                        value: _selectedTeam,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'No team (individual member)',
                        ),
                        items: [
                          const DropdownMenuItem<Team?>(
                            value: null,
                            child: Text('No team (individual member)'),
                          ),
                          ...teams.map((team) {
                            return DropdownMenuItem<Team?>(
                              value: team,
                              child: Text(team.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedTeam = value);
                        },
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Role selection
            const Text(
              'Select Your Role',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MembershipRole>(
              value: _selectedRole,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                if (_selectedTeam != null) ...[
                  const DropdownMenuItem(
                    value: MembershipRole.coach,
                    child: Text('Coach'),
                  ),
                  const DropdownMenuItem(
                    value: MembershipRole.rower,
                    child: Text('Rower'),
                  ),
                  const DropdownMenuItem(
                    value: MembershipRole.coxswain,
                    child: Text('Coxswain'),
                  ),
                ],
                const DropdownMenuItem(
                  value: MembershipRole.athlete,
                  child: Text('Athlete (Individual)'),
                ),
                const DropdownMenuItem(
                  value: MembershipRole.boatman,
                  child: Text('Boatman'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),

            const SizedBox(height: 24),

            // Optional message
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message to Admin (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Introduce yourself or explain why you want to join',
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
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
}
