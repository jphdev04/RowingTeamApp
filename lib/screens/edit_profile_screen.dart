import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/team.dart';
import '../services/user_service.dart';
import '../services/membership_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';
import '../models/organization.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  final Membership membership;
  final Team? team;
  final Organization? organization;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.membership,
    this.team,
    required this.organization,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _injuryDetailsController = TextEditingController();
  final _userService = UserService();
  final _membershipService = MembershipService();

  String? _selectedGender;
  String? _selectedSide;
  String? _selectedWeightClass;
  bool _hasInjury = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _phoneController.text = widget.user.phone ?? '';
    _emergencyContactController.text = widget.user.emergencyContact ?? '';
    _emergencyPhoneController.text = widget.user.emergencyPhone ?? '';
    _selectedGender = widget.user.gender;
    _hasInjury = widget.user.hasInjury;
    _injuryDetailsController.text = widget.user.injuryDetails ?? '';

    // Membership-specific fields
    _selectedSide = widget.membership.side;
    _selectedWeightClass = widget.membership.weightClass;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _injuryDetailsController.dispose();
    super.dispose();
  }

  bool get _isRower => widget.membership.role == MembershipRole.rower;
  bool get _isCoach => widget.membership.role == MembershipRole.coach;
  bool get _isAdmin => widget.membership.role == MembershipRole.admin;

  List<String> _getWeightClassOptions() {
    if (_selectedGender == null) return [];

    if (_selectedGender == 'male') {
      return ['Lightweight (<160 lbs)', 'Heavyweight (160+ lbs)', 'Openweight'];
    } else {
      return ['Lightweight (<130 lbs)', 'Heavyweight (130+ lbs)', 'Openweight'];
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedUser = widget.user.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          gender: _isCoach || _isAdmin ? widget.user.gender : _selectedGender,
          emergencyContact: _emergencyContactController.text.trim().isNotEmpty
              ? _emergencyContactController.text.trim()
              : null,
          emergencyPhone: _emergencyPhoneController.text.trim().isNotEmpty
              ? _emergencyPhoneController.text.trim()
              : null,
          hasInjury: _isCoach || _isAdmin ? false : _hasInjury,
          injuryDetails: _isCoach || _isAdmin
              ? null
              : (_hasInjury && _injuryDetailsController.text.trim().isNotEmpty
                    ? _injuryDetailsController.text.trim()
                    : null),
        );

        await _userService.updateUser(updatedUser);

        if (_isRower) {
          final updatedMembership = widget.membership.copyWith(
            side: _selectedSide,
            weightClass: _selectedWeightClass,
          );
          await _membershipService.updateMembership(updatedMembership);
        }

        if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TeamHeader(
            team: widget.team,
            organization: widget.organization,
            title: 'Edit Profile',
            subtitle: 'Update your information',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: primaryColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile picture
                    _buildProfileAvatar(),
                    const SizedBox(height: 32),

                    // ── Basic Information ──
                    BoathouseStyles.sectionLabel('Basic Information'),
                    const SizedBox(height: 8),
                    BoathouseStyles.textField(
                      primaryColor: primaryColor,
                      controller: _nameController,
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email (read-only)
                    TextFormField(
                      initialValue: widget.user.email,
                      enabled: false,
                      decoration: BoathouseStyles.inputDecoration(
                        primaryColor: primaryColor,
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    BoathouseStyles.textField(
                      primaryColor: primaryColor,
                      controller: _phoneController,
                      labelText: 'Phone Number (Optional)',
                      prefixIcon: const Icon(Icons.phone),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Gender (not for coaches/admins)
                    if (!_isCoach && !_isAdmin) ...[
                      BoathouseStyles.dropdown<String>(
                        primaryColor: primaryColor,
                        value: _selectedGender,
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.person_outline),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                            if (_isRower) {
                              _selectedWeightClass = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Rowing Details (rowers only) ──
                    if (_isRower) ...[
                      const SizedBox(height: 16),
                      BoathouseStyles.sectionLabel('Rowing Details'),
                      const SizedBox(height: 8),

                      BoathouseStyles.dropdown<String>(
                        primaryColor: primaryColor,
                        value: _selectedSide,
                        labelText: 'Side',
                        prefixIcon: const Icon(Icons.swap_horiz),
                        items: const [
                          DropdownMenuItem(value: 'port', child: Text('Port')),
                          DropdownMenuItem(
                            value: 'starboard',
                            child: Text('Starboard'),
                          ),
                          DropdownMenuItem(value: 'both', child: Text('Both')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedSide = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_selectedGender != null)
                        BoathouseStyles.dropdown<String>(
                          primaryColor: primaryColor,
                          value: _selectedWeightClass,
                          labelText: 'Weight Class',
                          prefixIcon: const Icon(Icons.monitor_weight),
                          items: _getWeightClassOptions()
                              .map(
                                (wc) => DropdownMenuItem(
                                  value: wc,
                                  child: Text(wc),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedWeightClass = value);
                          },
                        ),
                    ],

                    // ── Emergency Contact ──
                    const SizedBox(height: 32),
                    BoathouseStyles.sectionLabel('Emergency Contact'),
                    const SizedBox(height: 8),

                    BoathouseStyles.textField(
                      primaryColor: primaryColor,
                      controller: _emergencyContactController,
                      labelText: 'Emergency Contact Name',
                      prefixIcon: const Icon(Icons.contact_emergency),
                    ),
                    const SizedBox(height: 16),

                    BoathouseStyles.textField(
                      primaryColor: primaryColor,
                      controller: _emergencyPhoneController,
                      labelText: 'Emergency Contact Phone',
                      prefixIcon: const Icon(Icons.phone),
                      keyboardType: TextInputType.phone,
                    ),

                    // ── Injury Status (not for coaches/admins) ──
                    if (!_isCoach && !_isAdmin) ...[
                      const SizedBox(height: 32),
                      BoathouseStyles.sectionLabel('Injury Status'),
                      const SizedBox(height: 8),

                      BoathouseStyles.switchCard(
                        primaryColor: primaryColor,
                        switches: [
                          SwitchTileData(
                            title: 'Currently Injured',
                            subtitle: 'Toggle if you have an active injury',
                            value: _hasInjury,
                            onChanged: (value) {
                              setState(() => _hasInjury = value);
                            },
                          ),
                        ],
                      ),

                      if (_hasInjury) ...[
                        const SizedBox(height: 16),
                        BoathouseStyles.textField(
                          primaryColor: primaryColor,
                          controller: _injuryDetailsController,
                          labelText: 'Injury Details',
                          hintText: 'Describe your injury and any limitations',
                          prefixIcon: const Icon(Icons.healing),
                          maxLines: 4,
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),

                    // ── Save Button ──
                    BoathouseStyles.primaryButton(
                      primaryColor: primaryColor,
                      label: 'Save Changes',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveProfile,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization?.primaryColorObj ??
      Colors.blue;

  Widget _buildProfileAvatar() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: primaryColor,
            child: Text(
              widget.user.name.isNotEmpty
                  ? widget.user.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
