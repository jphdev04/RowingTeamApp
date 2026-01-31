import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/organization.dart';
import '../models/membership.dart';
import '../services/organization_service.dart';
import '../services/join_request_service.dart';
import '../services/membership_service.dart';
import '../services/user_service.dart';
import 'select_team_screen.dart';
import 'dashboard_screen.dart';

class JoinOrganizationScreen extends StatefulWidget {
  final AppUser user;

  const JoinOrganizationScreen({super.key, required this.user});

  @override
  State<JoinOrganizationScreen> createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _joinCodeController = TextEditingController();
  final _orgService = OrganizationService();
  final _joinRequestService = JoinRequestService();
  final _membershipService = MembershipService();
  final _userService = UserService();

  bool _isLoading = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinOrganization() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Find organization by join code
        final org = await _orgService.getOrganizationByJoinCode(
          _joinCodeController.text.trim(),
        );

        if (org == null) {
          throw 'Invalid join code. Please check and try again.';
        }

        if (mounted) {
          // Navigate to team/role selection
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  SelectTeamScreen(user: widget.user, organization: org),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Organization')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.vpn_key, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Enter Join Code',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ask your coach or team admin for the organization join code',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _joinCodeController,
                decoration: const InputDecoration(
                  labelText: 'Join Code',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., CRI2025',
                  prefixIcon: Icon(Icons.tag),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a join code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinOrganization,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
