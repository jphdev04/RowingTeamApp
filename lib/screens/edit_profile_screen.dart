import 'package:flutter/material.dart';
import '../models/athlete.dart';
import '../models/team.dart';
import '../services/athlete_service.dart';
import '../widgets/team_header.dart';

class EditProfileScreen extends StatefulWidget {
  final Athlete athlete;
  final Team? team;

  const EditProfileScreen({super.key, required this.athlete, this.team});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _injuryDetailsController = TextEditingController();
  final _athleteService = AthleteService();

  String? _selectedGender;
  String? _selectedSide;
  String? _selectedWeightClass;
  bool _isInjured = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    _nameController.text = widget.athlete.name;
    _selectedGender = widget.athlete.gender;
    _selectedSide = widget.athlete.side;
    _selectedWeightClass = widget.athlete.weightClass;
    _isInjured = widget.athlete.isInjured;
    _injuryDetailsController.text = widget.athlete.injuryDetails ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _injuryDetailsController.dispose();
    super.dispose();
  }

  bool get _isRower => widget.athlete.role == 'rower';

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedAthlete = widget.athlete.copyWith(
          name: _nameController.text.trim(),
          gender: widget.athlete.role != 'coach'
              ? _selectedGender
              : widget.athlete.gender,
          side: _isRower ? _selectedSide : null,
          weightClass: _isRower ? _selectedWeightClass : null,
          // Only update injury status for non-coaches
          isInjured: widget.athlete.role != 'coach'
              ? _isInjured
              : widget.athlete.isInjured,
          injuryDetails:
              widget.athlete.role != 'coach' &&
                  _isInjured &&
                  _injuryDetailsController.text.isNotEmpty
              ? _injuryDetailsController.text.trim()
              : widget.athlete.injuryDetails,
        );

        await _athleteService.updateAthlete(updatedAthlete);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
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
                              widget.athlete.name.isNotEmpty
                                  ? widget.athlete.name[0].toUpperCase()
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

                    // Email (read-only)
                    TextFormField(
                      initialValue: widget.athlete.email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role (read-only)
                    TextFormField(
                      initialValue: widget.athlete.role.toUpperCase(),
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (widget.athlete.role != 'coach') ...[
                      const SizedBox(height: 16),
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
                            // Reset weight class when gender changes
                            if (_isRower) {
                              _selectedWeightClass = null;
                            }
                          });
                        },
                      ),
                    ],

                    // Rower-specific fields
                    if (_isRower) ...[
                      const SizedBox(height: 32),
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
                          items: Athlete.getWeightClassOptions(_selectedGender)
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

                    // Injury section
                    if (widget.athlete.role != 'coach') ...[
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
                        value: _isInjured,
                        onChanged: (value) {
                          setState(() => _isInjured = value);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (_isInjured) ...[
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

                    // Physical stats info (read-only for athletes)
                    if (widget.athlete.role != 'coach' &&
                        (widget.athlete.height != null ||
                            widget.athlete.weight != null ||
                            widget.athlete.wingspan != null)) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Physical Stats',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your physical stats (height, weight, wingspan) can only be updated by your coach.',
                              style: TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            if (widget.athlete.height != null)
                              Text('Height: ${widget.athlete.height}"'),
                            if (widget.athlete.weight != null)
                              Text('Weight: ${widget.athlete.weight} lbs'),
                            if (widget.athlete.wingspan != null)
                              Text('Wingspan: ${widget.athlete.wingspan}"'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

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
