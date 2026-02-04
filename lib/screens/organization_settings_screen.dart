import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/organization.dart';
import '../services/organization_service.dart';
import '../widgets/team_header.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  final Organization organization;

  const OrganizationSettingsScreen({super.key, required this.organization});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        // CHANGE FROM BODY TO COLUMN
        children: [
          TeamHeader(
            // REPLACE APPBAR
            organization: widget.organization,
            title: 'Organization Settings',
            subtitle: 'Manage your organization',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            // WRAP SCROLLVIEW IN EXPANDED
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Remove the organization icon section - it's in the header now

                    // Join Code Section
                    Card(
                      elevation: 2,
                      color: widget.organization.primaryColorObj.withOpacity(
                        0.05,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.vpn_key,
                                  color: widget.organization.primaryColorObj,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Join Code',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                                  color: widget.organization.primaryColorObj,
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

                    const SizedBox(height: 32),

                    const Text(
                      'Organization Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 32),

                    const Text(
                      'Organization Colors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

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
                            color: _primaryColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Primary Color',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final color = await showColorPickerDialog(
                                    context,
                                    _primaryColor,
                                    title: const Text('Select Primary Color'),
                                    pickersEnabled: const {
                                      ColorPickerType.wheel: true,
                                      ColorPickerType.primary: true,
                                      ColorPickerType.accent: false,
                                    },
                                  );
                                  setState(() => _primaryColor = color);
                                },
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Tap to change',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Secondary Color',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final color = await showColorPickerDialog(
                                    context,
                                    _secondaryColor,
                                    title: const Text('Select Secondary Color'),
                                    pickersEnabled: const {
                                      ColorPickerType.wheel: true,
                                      ColorPickerType.primary: true,
                                      ColorPickerType.accent: false,
                                    },
                                  );
                                  setState(() => _secondaryColor = color);
                                },
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _secondaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Tap to change',
                                      style: TextStyle(
                                        color:
                                            _secondaryColor.computeLuminance() >
                                                0.5
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    const SizedBox(height: 32),

                    const Text(
                      'Membership Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: widget
                            .organization
                            .primaryColorObj, // USE ORG COLOR
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    const Divider(),

                    const SizedBox(height: 24),

                    // Danger zone
                    const Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement regenerate join code
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Regenerate join code coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      label: const Text(
                        'Regenerate Join Code',
                        style: TextStyle(color: Colors.orange),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement delete organization
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Delete organization coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text(
                        'Delete Organization',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
