import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../models/team.dart';
import '../models/organization.dart';
import '../services/team_service.dart';
import '../widgets/team_header.dart';

class TeamSettingsScreen extends StatefulWidget {
  final Team team;
  final Organization? organization;

  const TeamSettingsScreen({super.key, required this.team, this.organization});

  @override
  State<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends State<TeamSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _teamNameController;
  final _teamService = TeamService();
  bool _isLoading = false;

  late Color _primaryColor;
  late Color _secondaryColor;

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController(text: widget.team.name);
    _primaryColor = widget.team.primaryColorObj;
    _secondaryColor = widget.team.secondaryColorObj;
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Color get _headerTextColor {
    return _primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _updateTeam() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedTeam = widget.team.copyWith(
          name: _teamNameController.text.trim(),
          primaryColor: _primaryColor.value,
          secondaryColor: _secondaryColor.value,
        );

        await _teamService.updateTeam(updatedTeam);

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

  Future<void> _pickColor({required bool isSecondary}) async {
    final currentColor = isSecondary ? _secondaryColor : _primaryColor;
    final colorBeforeDialog = currentColor;

    final picked =
        await ColorPicker(
          color: currentColor,
          onColorChanged: (Color color) {
            setState(() {
              if (isSecondary) {
                _secondaryColor = color;
              } else {
                _primaryColor = color;
              }
            });
          },
          width: 40,
          height: 40,
          borderRadius: 4,
          spacing: 5,
          runSpacing: 5,
          wheelDiameter: 155,
          heading: Text(
            isSecondary ? 'Select Secondary Color' : 'Select Primary Color',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subheading: Text(
            'Select color shade',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          wheelSubheading: Text(
            'Selected color and its shades',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          showMaterialName: true,
          showColorName: true,
          showColorCode: true,
          copyPasteBehavior: const ColorPickerCopyPasteBehavior(
            longPressMenu: true,
          ),
          materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
          colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
          colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
          pickersEnabled: const <ColorPickerType, bool>{
            ColorPickerType.both: false,
            ColorPickerType.primary: true,
            ColorPickerType.accent: false,
            ColorPickerType.bw: false,
            ColorPickerType.custom: false,
            ColorPickerType.wheel: true,
          },
        ).showPickerDialog(
          context,
          constraints: const BoxConstraints(
            minHeight: 460,
            minWidth: 300,
            maxWidth: 320,
          ),
        );

    if (!picked) {
      setState(() {
        if (isSecondary) {
          _secondaryColor = colorBeforeDialog;
        } else {
          _primaryColor = colorBeforeDialog;
        }
      });
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
            title: 'Team Settings',
            subtitle: 'Manage team name and colors',
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
                    // Team Name
                    _buildSectionHeader('Team Information'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _teamNameController,
                          decoration: const InputDecoration(
                            labelText: 'Team Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.groups),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a team name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Team Colors
                    _buildSectionHeader('Team Colors'),
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
                                  _teamNameController.text.isEmpty
                                      ? 'Your Team'
                                      : _teamNameController.text,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _headerTextColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Color pickers
                            Row(
                              children: [
                                Expanded(
                                  child: _buildColorPicker(
                                    label: 'Primary Color',
                                    color: _primaryColor,
                                    onTap: () => _pickColor(isSecondary: false),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildColorPicker(
                                    label: 'Secondary Color',
                                    color: _secondaryColor,
                                    onTap: () => _pickColor(isSecondary: true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateTeam,
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

                    const SizedBox(height: 24),
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
