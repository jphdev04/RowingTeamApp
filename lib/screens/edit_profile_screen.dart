import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/team.dart';
import '../services/user_service.dart';
import '../services/membership_service.dart';
import '../widgets/team_header.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  final Membership membership;
  final Team? team;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.membership,
    this.team,
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
        // Update user data
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

        // Update membership-specific fields (for rowers)
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
            title: 'Edit Profile',
            subtitle: 'Update your information',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color:
                      (widget.team?.primaryColorObj.computeLuminance() ?? 0) >
                          0.5
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
                    // Profile picture placeholder
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue,
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
                                color:
                                    widget.team?.primaryColorObj ?? Colors.blue,
                                shape: BoxShape.circle,
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
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: widget.user.email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Gender (not for coaches/admins)
                    if (!_isCoach && !_isAdmin) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
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

                    // Rower-specific fields
                    if (_isRower) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Rowing Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedSide,
                        decoration: const InputDecoration(
                          labelText: 'Side',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.swap_horiz),
                        ),
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
                        DropdownButtonFormField<String>(
                          value: _selectedWeightClass,
                          decoration: const InputDecoration(
                            labelText: 'Weight Class',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monitor_weight),
                          ),
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

                    // Emergency contact
                    const SizedBox(height: 32),
                    const Text(
                      'Emergency Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emergencyContactController,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.contact_emergency),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emergencyPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    // Injury section (not for coaches/admins)
                    if (!_isCoach && !_isAdmin) ...[
                      const SizedBox(height: 32),
                      const Text(
                        'Injury Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Currently Injured'),
                        subtitle: const Text(
                          'Toggle if you have an active injury',
                        ),
                        value: _hasInjury,
                        onChanged: (value) {
                          setState(() => _hasInjury = value);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (_hasInjury) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _injuryDetailsController,
                          decoration: const InputDecoration(
                            labelText: 'Injury Details',
                            border: OutlineInputBorder(),
                            hintText:
                                'Describe your injury and any limitations',
                            prefixIcon: Icon(Icons.healing),
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              widget.team?.primaryColorObj ?? Colors.blue,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
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
