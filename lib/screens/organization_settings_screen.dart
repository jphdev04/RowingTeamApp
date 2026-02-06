import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../models/organization.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../services/organization_service.dart';
import '../services/auth_service.dart';
import '../widgets/team_header.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  final Organization organization;
  final AppUser user;
  final Membership membership;

  const OrganizationSettingsScreen({
    super.key,
    required this.organization,
    required this.user,
    required this.membership,
  });

  @override
  State<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState
    extends State<OrganizationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _orgService = OrganizationService();

  bool _isLoading = false;
  bool _requiresApproval = true;
  bool _isPublic = false;
  late Color _primaryColor;
  late Color _secondaryColor;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.organization.name;
    _addressController.text = widget.organization.address ?? '';
    _websiteController.text = widget.organization.website ?? '';
    _requiresApproval = widget.organization.requiresApproval;
    _isPublic = widget.organization.isPublic;
    _primaryColor = widget.organization.primaryColorObj;
    _secondaryColor = widget.organization.secondaryColorObj;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Color get _headerTextColor {
    return _primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedOrg = widget.organization.copyWith(
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          website: _websiteController.text.trim().isNotEmpty
              ? _websiteController.text.trim()
              : null,
          requiresApproval: _requiresApproval,
          isPublic: _isPublic,
          primaryColor: _primaryColor.value,
          secondaryColor: _secondaryColor.value,
        );

        await _orgService.updateOrganization(updatedOrg);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Organization settings saved!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
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

  void _copyJoinCode() {
    Clipboard.setData(ClipboardData(text: widget.organization.joinCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Join code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showSignOutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TeamHeader(
            organization: widget.organization,
            title: 'Organization Settings',
            subtitle: 'Manage your organization',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: _headerTextColor,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Join Code Section
                    _buildSectionHeader('Join Code'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Share this code with members to join your organization',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.organization.joinCode,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: _copyJoinCode,
                                    tooltip: 'Copy',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Organization Information
                    _buildSectionHeader('Organization Information'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Organization Name',
                                border: OutlineInputBorder(),
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
                                prefixIcon: Icon(Icons.location_on),
                                hintText: 'Boathouse location',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _websiteController,
                              decoration: const InputDecoration(
                                labelText: 'Website (Optional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.language),
                                hintText: 'https://example.com',
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Organization Colors
                    _buildSectionHeader('Organization Colors'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Color preview
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [_primaryColor, _secondaryColor],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _nameController.text.isEmpty
                                      ? 'Organization'
                                      : _nameController.text,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _headerTextColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildColorPicker(
                                    label: 'Primary Color',
                                    color: _primaryColor,
                                    onTap: () async {
                                      final color = await showColorPickerDialog(
                                        context,
                                        _primaryColor,
                                        title: const Text(
                                          'Select Primary Color',
                                        ),
                                        pickersEnabled: const {
                                          ColorPickerType.wheel: true,
                                          ColorPickerType.primary: true,
                                          ColorPickerType.accent: false,
                                        },
                                      );
                                      setState(() => _primaryColor = color);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildColorPicker(
                                    label: 'Secondary Color',
                                    color: _secondaryColor,
                                    onTap: () async {
                                      final color = await showColorPickerDialog(
                                        context,
                                        _secondaryColor,
                                        title: const Text(
                                          'Select Secondary Color',
                                        ),
                                        pickersEnabled: const {
                                          ColorPickerType.wheel: true,
                                          ColorPickerType.primary: true,
                                          ColorPickerType.accent: false,
                                        },
                                      );
                                      setState(() => _secondaryColor = color);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Membership Settings
                    _buildSectionHeader('Membership Settings'),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Require Admin Approval'),
                            subtitle: const Text(
                              'New members must be approved before joining',
                            ),
                            value: _requiresApproval,
                            onChanged: (value) {
                              setState(() => _requiresApproval = value);
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Public Organization'),
                            subtitle: const Text(
                              'Show in public directory (coming soon)',
                            ),
                            value: _isPublic,
                            onChanged: (value) {
                              setState(() => _isPublic = value);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _primaryColor,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                color: _headerTextColor,
                              ),
                            ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(thickness: 2),
                    const SizedBox(height: 24),

                    // Danger Zone
                    _buildSectionHeader('Danger Zone'),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.refresh,
                              color: Colors.orange,
                            ),
                            title: const Text('Regenerate Join Code'),
                            subtitle: const Text(
                              'Invalidates the current code',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Implement regenerate join code
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Regenerate join code coming soon!',
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Delete Organization',
                              style: TextStyle(color: Colors.red),
                            ),
                            subtitle: const Text(
                              'This action cannot be undone',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Implement delete organization
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Delete organization coming soon!',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(thickness: 2),
                    const SizedBox(height: 24),

                    // Personal Settings
                    _buildSectionHeader('Personal'),
                    Card(
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
                                    team: null,
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
                    OutlinedButton.icon(
                      onPressed: _showSignOutDialog,
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

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildColorPicker({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                'Tap to change',
                style: TextStyle(
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
