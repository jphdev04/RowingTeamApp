import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/organization.dart';
import '../models/membership.dart';
import '../services/organization_service.dart';
import '../services/membership_service.dart';
import '../services/user_service.dart';
import 'create_team_screen.dart';

class CreateOrganizationScreen extends StatefulWidget {
  final AppUser user;

  const CreateOrganizationScreen({super.key, required this.user});

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _orgService = OrganizationService();
  final _membershipService = MembershipService();
  final _userService = UserService();

  bool _isLoading = false;
  bool _requiresApproval = true;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _createOrganization() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Create organization
        final org = await _orgService.createOrganization(
          _nameController.text.trim(),
          widget.user.id,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          website: _websiteController.text.trim().isNotEmpty
              ? _websiteController.text.trim()
              : null,
          requiresApproval: _requiresApproval,
        );

        // Create admin membership for creator
        final membership = await _membershipService.createMembership(
          userId: widget.user.id,
          organizationId: org.id,
          role: MembershipRole.admin,
        );

        // Update user's current context
        await _userService.updateCurrentContext(
          widget.user.id,
          org.id,
          membership.id,
        );

        if (mounted) {
          // Show join code and navigate to create team
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Organization Created!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your organization has been created. Share this code with members:',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: SelectableText(
                      org.joinCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You can find this code later in Organization Settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => CreateTeamScreen(
                          user: widget.user,
                          organization: org,
                          membership: membership,
                        ),
                      ),
                    );
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Organization')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.business, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Create Your Organization',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Set up your rowing club or boathouse',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Organization Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Community Rowing Inc',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an organization name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Boathouse location',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com',
                  prefixIcon: Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Require Approval for New Members'),
                subtitle: const Text(
                  'Admin must approve join requests',
                  style: TextStyle(fontSize: 12),
                ),
                value: _requiresApproval,
                onChanged: (value) {
                  setState(() => _requiresApproval = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _createOrganization,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Organization',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
