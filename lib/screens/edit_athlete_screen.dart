import 'package:flutter/material.dart';
import '../models/athlete.dart';
import '../services/athlete_service.dart';

class EditAthleteScreen extends StatefulWidget {
  final Athlete athlete;

  const EditAthleteScreen({super.key, required this.athlete});

  @override
  State<EditAthleteScreen> createState() => _EditAthleteScreenState();
}

class _EditAthleteScreenState extends State<EditAthleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _wingspanController = TextEditingController();
  final _injuryDetailsController = TextEditingController();

  final _athleteService = AthleteService();

  String _selectedRole = 'rower';
  String? _selectedGender;
  String? _selectedSide;
  String? _selectedWeightClass;
  bool _isInjured = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing data
    _nameController.text = widget.athlete.name;
    _selectedRole = widget.athlete.role;
    _selectedGender = widget.athlete.gender;
    _selectedSide = widget.athlete.side;
    _selectedWeightClass = widget.athlete.weightClass;
    _heightController.text = widget.athlete.height?.toString() ?? '';
    _weightController.text = widget.athlete.weight?.toString() ?? '';
    _wingspanController.text = widget.athlete.wingspan?.toString() ?? '';
    _isInjured = widget.athlete.isInjured;
    _injuryDetailsController.text = widget.athlete.injuryDetails ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _wingspanController.dispose();
    _injuryDetailsController.dispose();
    super.dispose();
  }

  bool get _isCoxswain => _selectedRole == 'coxswain';
  bool get _isRower => _selectedRole == 'rower';

  Future<void> _updateAthlete() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Create updated athlete object
        Athlete updatedAthlete = widget.athlete.copyWith(
          name: _nameController.text.trim(),
          role: _selectedRole,
          gender: _selectedGender,
          side: _isRower ? _selectedSide : null,
          weightClass: _isRower ? _selectedWeightClass : null,
          height: !_isCoxswain && _heightController.text.isNotEmpty
              ? double.tryParse(_heightController.text)
              : null,
          weight: !_isCoxswain && _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text)
              : null,
          wingspan: !_isCoxswain && _wingspanController.text.isNotEmpty
              ? double.tryParse(_wingspanController.text)
              : null,
          isInjured: _isInjured,
          injuryDetails: _isInjured && _injuryDetailsController.text.isNotEmpty
              ? _injuryDetailsController.text.trim()
              : null,
        );

        // Update in Firestore
        await _athleteService.updateAthlete(updatedAthlete);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Athlete updated successfully!'),
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

  Future<void> _deleteAthlete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Athlete'),
        content: Text(
          'Are you sure you want to delete ${widget.athlete.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _athleteService.deleteAthlete(widget.athlete.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Athlete deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting athlete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Athlete'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteAthlete,
            tooltip: 'Delete Athlete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.athlete.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  enabled: false,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'coach', child: Text('Coach')),
                  DropdownMenuItem(value: 'coxswain', child: Text('Coxswain')),
                  DropdownMenuItem(value: 'rower', child: Text('Rower')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    if (!_isRower) {
                      _selectedSide = null;
                      _selectedWeightClass = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                    _selectedWeightClass = null;
                  });
                },
              ),

              // Rower-specific fields
              if (_isRower) ...[
                const SizedBox(height: 32),
                const Text(
                  'Rowing Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSide,
                  decoration: const InputDecoration(
                    labelText: 'Side',
                    border: OutlineInputBorder(),
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
                    ),
                    items: Athlete.getWeightClassOptions(_selectedGender)
                        .map(
                          (wc) => DropdownMenuItem(value: wc, child: Text(wc)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedWeightClass = value);
                    },
                  ),
              ],

              // Physical stats (not for coxswains)
              if (!_isCoxswain) ...[
                const SizedBox(height: 32),
                const Text(
                  'Physical Stats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height (inches)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight (lbs)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _wingspanController,
                  decoration: const InputDecoration(
                    labelText: 'Wingspan (inches)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
              ],

              // Injury section
              const SizedBox(height: 32),
              const Text(
                'Injury Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Currently Injured'),
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
                    hintText: 'Describe the injury and any limitations',
                  ),
                  maxLines: 4,
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateAthlete,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
