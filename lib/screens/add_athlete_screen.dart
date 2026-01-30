import 'package:flutter/material.dart';
import '../models/athlete.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/athlete_service.dart';

class AddAthleteScreen extends StatefulWidget {
  final String teamId;

  const AddAthleteScreen({super.key, required this.teamId});

  @override
  State<AddAthleteScreen> createState() => _AddAthleteScreenState();
}

class _AddAthleteScreenState extends State<AddAthleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _wingspanController.dispose();
    _injuryDetailsController.dispose();
    super.dispose();
  }

  bool get _isCoxswain => _selectedRole == 'coxswain';
  bool get _isRower => _selectedRole == 'rower';

  Future<void> _addAthlete() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Generate a unique ID for the athlete (without creating auth account)
        final docRef = FirebaseFirestore.instance.collection('athletes').doc();

        // Create Athlete object WITH TEAM ID (no auth account yet)
        Athlete athlete = Athlete(
          id: docRef.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole,
          teamId: widget.teamId,
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
          createdAt: DateTime.now(),
        );

        // Save to Firestore (no auth account created)
        await _athleteService.addAthlete(athlete);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${athlete.name} added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Add Athlete')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
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
                    // Reset rowing-specific fields when changing role
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
                    // Reset weight class when gender changes
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
                  'Physical Stats (Optional)',
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
                  maxLines: 3,
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addAthlete,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Add Athlete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
