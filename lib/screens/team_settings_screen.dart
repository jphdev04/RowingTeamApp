import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../models/team.dart';
import '../services/team_service.dart';

class TeamSettingsScreen extends StatefulWidget {
  final Team team;

  const TeamSettingsScreen({super.key, required this.team});

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

  Future<void> _pickPrimaryColor() async {
    final Color colorBeforeDialog = _primaryColor;
    if (!(await colorPickerDialog())) {
      setState(() {
        _primaryColor = colorBeforeDialog;
      });
    }
  }

  Future<void> _pickSecondaryColor() async {
    final Color colorBeforeDialog = _secondaryColor;
    if (!(await colorPickerDialog(isSecondary: true))) {
      setState(() {
        _secondaryColor = colorBeforeDialog;
      });
    }
  }

  Future<bool> colorPickerDialog({bool isSecondary = false}) async {
    return ColorPicker(
      color: isSecondary ? _secondaryColor : _primaryColor,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Team Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
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
              const SizedBox(height: 32),
              const Text(
                'Team Colors',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    _teamNameController.text.isEmpty
                        ? 'Your Team'
                        : _teamNameController.text,
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
              const SizedBox(height: 24),

              // Custom color pickers
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Primary Color',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickPrimaryColor,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Text(
                                'Tap to change',
                                style: TextStyle(
                                  color: _primaryColor.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickSecondaryColor,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: _secondaryColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Text(
                                'Tap to change',
                                style: TextStyle(
                                  color:
                                      _secondaryColor.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
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
              ElevatedButton(
                onPressed: _isLoading ? null : _updateTeam,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _primaryColor,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
