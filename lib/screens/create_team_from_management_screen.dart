import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../models/organization.dart';
import '../services/team_service.dart';
import '../services/auth_service.dart';

class CreateTeamFromManagementScreen extends StatefulWidget {
  final Organization organization;

  const CreateTeamFromManagementScreen({super.key, required this.organization});

  @override
  State<CreateTeamFromManagementScreen> createState() =>
      _CreateTeamFromManagementScreenState();
}

class _CreateTeamFromManagementScreenState
    extends State<CreateTeamFromManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _seasonController = TextEditingController();
  final _teamService = TeamService();
  final _authService = AuthService();

  bool _isLoading = false;
  Color _primaryColor = const Color(0xFF1976D2);
  Color _secondaryColor = const Color(0xFFFFFFFF);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _teamService.createTeamWithColors(
          widget.organization.id,
          _nameController.text.trim(),
          _authService.currentUser!.uid,
          _primaryColor.value,
          _secondaryColor.value,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          season: _seasonController.text.trim().isNotEmpty
              ? _seasonController.text.trim()
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team created successfully!'),
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
      appBar: AppBar(title: const Text('Create New Team')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.groups, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Create New Team',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'for ${widget.organization.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Varsity Men, Masters A',
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a team name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Brief description of the team',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seasonController,
                decoration: const InputDecoration(
                  labelText: 'Season (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Fall 2025, Spring 2026',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Team Colors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
                        ? 'Team Preview'
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
                            height: 50,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
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
                            height: 50,
                            decoration: BoxDecoration(
                              color: _secondaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _createTeam,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _primaryColor,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Team',
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
