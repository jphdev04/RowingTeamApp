import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../models/team.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';
import '../services/team_service.dart';

class AddEquipmentScreen extends StatefulWidget {
  final String organizationId;
  final Organization? organization;

  const AddEquipmentScreen({
    super.key,
    required this.organizationId,
    this.organization,
  });

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentService = EquipmentService();
  final _teamService = TeamService();

  // Common fields
  EquipmentType? _selectedType;
  final _nameController = TextEditingController();
  String? _selectedManufacturer;
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _serialNumberController = TextEditingController();
  DateTime? _purchaseDate;
  final _purchasePriceController = TextEditingController();
  final _notesController = TextEditingController();

  // Team assignment
  bool _availableToAllTeams = true;
  final Set<String> _selectedTeamIds = {};

  // Shell-specific
  ShellType? _selectedShellType;
  RiggingType? _selectedRiggingType;
  final _currentRiggingController = TextEditingController();

  // Oar-specific
  OarType? _selectedOarType;
  final _oarCountController = TextEditingController();
  String? _selectedBladeType;
  final _oarLengthController = TextEditingController();

  // Coxbox-specific
  bool _microphoneIncluded = true;
  String _batteryStatus = 'Good';

  // Launch-specific
  bool _gasTankAssigned = false;
  final _tankNumberController = TextEditingController();
  String _fuelType = 'Gas';

  // Erg-specific
  final _ergIdController = TextEditingController();
  String? _selectedErgModel;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _serialNumberController.dispose();
    _purchasePriceController.dispose();
    _notesController.dispose();
    _currentRiggingController.dispose();
    _oarCountController.dispose();
    _oarLengthController.dispose();
    _tankNumberController.dispose();
    _ergIdController.dispose();
    super.dispose();
  }

  // Manufacturer options based on equipment type
  List<String> _getManufacturerOptions() {
    switch (_selectedType) {
      case EquipmentType.shell:
        return [
          'Vespoli',
          'Hudson',
          'Empacher',
          'Filippi',
          'Resolute',
          'Wintech',
          'Pocock',
          'Other',
        ];
      case EquipmentType.oar:
        return ['Concept2', 'Croker', 'Dreissigacker', 'Durham', 'Other'];
      case EquipmentType.coxbox:
        return ['NK', 'Cox Orb', 'SpeedCoach', 'Other'];
      case EquipmentType.launch:
        return ['Boston Whaler', 'Zodiac', 'Walker Bay', 'Other'];
      case EquipmentType.erg:
        return ['Concept2', 'RowPerfect', 'WaterRower', 'Other'];
      default:
        return ['Other'];
    }
  }

  // Blade type options for oars
  List<String> _getBladeTypeOptions() {
    return ['Smoothie 2', 'Comp', 'Macon', 'Fat2', 'Hatchet', 'Other'];
  }

  // Model options based on erg manufacturer
  List<String> _getErgModelOptions() {
    if (_selectedManufacturer == 'Concept2') {
      return ['Model D', 'Model E', 'RowErg', 'BikeErg', 'SkiErg'];
    } else if (_selectedManufacturer == 'RowPerfect') {
      return ['RP3', 'RP Dynamic'];
    } else if (_selectedManufacturer == 'WaterRower') {
      return ['Classic', 'Performance', 'Natural'];
    }
    return [];
  }

  Future<void> _saveEquipment() async {
    if (_formKey.currentState!.validate()) {
      // Validate type-specific required fields
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select equipment type')),
        );
        return;
      }

      if (_selectedManufacturer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select manufacturer')),
        );
        return;
      }

      // Type-specific validation
      if (_selectedType == EquipmentType.shell && _selectedShellType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select boat type')),
        );
        return;
      }

      if (_selectedType == EquipmentType.oar) {
        if (_selectedOarType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select oar type')),
          );
          return;
        }
        if (_oarCountController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter number of oars')),
          );
          return;
        }
      }

      if (_selectedType == EquipmentType.erg && _ergIdController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter erg ID')));
        return;
      }

      if (!_availableToAllTeams && _selectedTeamIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select at least one team or choose "All Teams"',
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final equipment = Equipment(
          id: '', // Will be set by service
          organizationId: widget.organizationId,
          type: _selectedType!,
          name: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          manufacturer: _selectedManufacturer!,
          model: _modelController.text.trim().isNotEmpty
              ? _modelController.text.trim()
              : null,
          year: _yearController.text.isNotEmpty
              ? int.tryParse(_yearController.text)
              : null,
          serialNumber: _serialNumberController.text.trim().isNotEmpty
              ? _serialNumberController.text.trim()
              : null,
          purchaseDate: _purchaseDate,
          purchasePrice: _purchasePriceController.text.isNotEmpty
              ? double.tryParse(_purchasePriceController.text)
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          availableToAllTeams: _availableToAllTeams,
          assignedTeamIds: _availableToAllTeams
              ? []
              : _selectedTeamIds.toList(),
          createdAt: DateTime.now(),

          // Shell-specific
          shellType: _selectedType == EquipmentType.shell
              ? _selectedShellType
              : null,
          riggingType: _selectedType == EquipmentType.shell
              ? _selectedRiggingType
              : null,
          currentRiggingSetup:
              _selectedType == EquipmentType.shell &&
                  _selectedRiggingType == RiggingType.dualRigged
              ? _currentRiggingController.text.trim()
              : null,

          // Oar-specific
          oarType: _selectedType == EquipmentType.oar ? _selectedOarType : null,
          oarCount:
              _selectedType == EquipmentType.oar &&
                  _oarCountController.text.isNotEmpty
              ? int.tryParse(_oarCountController.text)
              : null,
          bladeType: _selectedType == EquipmentType.oar
              ? _selectedBladeType
              : null,
          oarLength:
              _selectedType == EquipmentType.oar &&
                  _oarLengthController.text.isNotEmpty
              ? double.tryParse(_oarLengthController.text)
              : null,

          // Coxbox-specific
          microphoneIncluded: _selectedType == EquipmentType.coxbox
              ? _microphoneIncluded
              : null,
          batteryStatus: _selectedType == EquipmentType.coxbox
              ? _batteryStatus
              : null,

          // Launch-specific
          gasTankAssigned: _selectedType == EquipmentType.launch
              ? _gasTankAssigned
              : null,
          tankNumber: _selectedType == EquipmentType.launch && _gasTankAssigned
              ? _tankNumberController.text.trim()
              : null,
          fuelType: _selectedType == EquipmentType.launch ? _fuelType : null,

          // Erg-specific
          ergId: _selectedType == EquipmentType.erg
              ? _ergIdController.text.trim()
              : null,
        );

        await _equipmentService.addEquipment(equipment);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipment added successfully!'),
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
    final primaryColor =
        widget.organization?.primaryColorObj ?? const Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Add TeamHeader
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 16,
              24,
              24, // Smaller bottom padding
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: primaryColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Equipment',
                  style: TextStyle(
                    color: primaryColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Wrap the Form in Expanded
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Equipment Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Equipment Type
                    DropdownButtonFormField<EquipmentType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Equipment Type *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: EquipmentType.values.map((type) {
                        String displayName =
                            type.name[0].toUpperCase() + type.name.substring(1);
                        if (type == EquipmentType.oar) displayName = 'Oars';
                        if (type == EquipmentType.coxbox)
                          displayName = 'Coxbox';
                        if (type == EquipmentType.erg) displayName = 'Erg';

                        return DropdownMenuItem(
                          value: type,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                          _selectedManufacturer = null;
                          _selectedErgModel = null;
                        });
                      },
                    ),

                    if (_selectedType != null) ...[
                      const SizedBox(height: 16),

                      // Name (optional for most, hidden for ergs)
                      if (_selectedType != EquipmentType.erg)
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name (Optional)',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., "Blue Boat", "Fast Eight"',
                            prefixIcon: Icon(Icons.label),
                          ),
                        ),

                      if (_selectedType != EquipmentType.erg)
                        const SizedBox(height: 16),

                      // Manufacturer
                      DropdownButtonFormField<String>(
                        value: _selectedManufacturer,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: _getManufacturerOptions().map((manufacturer) {
                          return DropdownMenuItem(
                            value: manufacturer,
                            child: Text(manufacturer),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedManufacturer = value;
                            _selectedErgModel = null;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Model
                      if (_selectedType == EquipmentType.erg &&
                          _getErgModelOptions().isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: _selectedErgModel,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info),
                          ),
                          items: _getErgModelOptions().map((model) {
                            return DropdownMenuItem(
                              value: model,
                              child: Text(model),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedErgModel = value);
                            _modelController.text = value ?? '';
                          },
                        )
                      else
                        TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model (Optional)',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., "Club", "Elite"',
                            prefixIcon: Icon(Icons.info),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Year and Serial Number row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                border: OutlineInputBorder(),
                                hintText: '2020',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _serialNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Serial #',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.tag),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Purchase Date and Price row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _purchaseDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _purchaseDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Purchase Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                                child: Text(
                                  _purchaseDate != null
                                      ? DateFormat(
                                          'MM/dd/yyyy',
                                        ).format(_purchaseDate!)
                                      : 'Tap to select',
                                  style: TextStyle(
                                    color: _purchaseDate != null
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _purchasePriceController,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                                hintText: '5000',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // TYPE-SPECIFIC FIELDS
                      _buildTypeSpecificFields(),

                      const SizedBox(height: 24),

                      // TEAM ASSIGNMENT
                      const Text(
                        'Team Assignment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Available to All Teams'),
                        subtitle: const Text(
                          'Any team in the organization can use this equipment',
                        ),
                        value: _availableToAllTeams,
                        onChanged: (value) {
                          setState(() {
                            _availableToAllTeams = value;
                            if (value) _selectedTeamIds.clear();
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (!_availableToAllTeams) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Select Teams:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<List<Team>>(
                          stream: _teamService.getOrganizationTeams(
                            widget.organizationId,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            final teams = snapshot.data ?? [];

                            if (teams.isEmpty) {
                              return const Text(
                                'No teams available. Equipment will be organization-wide.',
                                style: TextStyle(color: Colors.grey),
                              );
                            }

                            return Card(
                              child: Column(
                                children: teams.map((team) {
                                  return CheckboxListTile(
                                    title: Text(team.name),
                                    value: _selectedTeamIds.contains(team.id),
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedTeamIds.add(team.id);
                                        } else {
                                          _selectedTeamIds.remove(team.id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Any additional information',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 4,
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveEquipment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: primaryColor,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save Equipment',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedType!) {
      case EquipmentType.shell:
        return _buildShellFields();
      case EquipmentType.oar:
        return _buildOarFields();
      case EquipmentType.coxbox:
        return _buildCoxboxFields();
      case EquipmentType.launch:
        return _buildLaunchFields();
      case EquipmentType.erg:
        return _buildErgFields();
    }
  }

  Widget _buildShellFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shell Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Boat Type
        DropdownButtonFormField<ShellType>(
          value: _selectedShellType,
          decoration: const InputDecoration(
            labelText: 'Boat Type *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.rowing),
          ),
          items: ShellType.values.map((type) {
            String display = '';
            switch (type) {
              case ShellType.eight:
                display = '8+ (Eight)';
                break;
              case ShellType.coxedFour:
                display = '4+ (Coxed Four)';
                break;
              case ShellType.four:
                display = '4- (Coxless Four)';
                break;
              case ShellType.quad:
                display = '4x (Quad)';
                break;
              case ShellType.coxedQuad:
                display = '4x+ (Coxed Quad)';
                break;
              case ShellType.pair:
                display = '2- (Pair)';
                break;
              case ShellType.double:
                display = '2x (Double)';
                break;
              case ShellType.single:
                display = '1x (Single)';
                break;
            }
            return DropdownMenuItem(value: type, child: Text(display));
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedShellType = value);
          },
        ),

        const SizedBox(height: 16),

        // Rigging Type
        DropdownButtonFormField<RiggingType>(
          value: _selectedRiggingType,
          decoration: const InputDecoration(
            labelText: 'Rigging',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.settings),
          ),
          items: RiggingType.values.map((type) {
            String display = '';
            switch (type) {
              case RiggingType.sweep:
                display = 'Sweep Only';
                break;
              case RiggingType.scull:
                display = 'Scull Only';
                break;
              case RiggingType.dualRigged:
                display = 'Dual-Rigged (Both)';
                break;
            }
            return DropdownMenuItem(value: type, child: Text(display));
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedRiggingType = value);
          },
        ),

        if (_selectedRiggingType == RiggingType.dualRigged) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _currentRiggingController,
            decoration: const InputDecoration(
              labelText: 'Current Setup',
              border: OutlineInputBorder(),
              hintText: 'e.g., Currently rigged for sweep',
              prefixIcon: Icon(Icons.info_outline),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOarFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Oar Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Oar Type
        DropdownButtonFormField<OarType>(
          value: _selectedOarType,
          decoration: const InputDecoration(
            labelText: 'Oar Type *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.sports),
          ),
          items: OarType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type == OarType.sweep ? 'Sweep' : 'Scull'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedOarType = value);
          },
        ),

        const SizedBox(height: 16),

        // Number of oars and length
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _oarCountController,
                decoration: const InputDecoration(
                  labelText: 'Number of Oars *',
                  border: OutlineInputBorder(),
                  hintText: '8',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _oarLengthController,
                decoration: const InputDecoration(
                  labelText: 'Length (cm)',
                  border: OutlineInputBorder(),
                  hintText: '370',
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Blade Type
        DropdownButtonFormField<String>(
          value: _selectedBladeType,
          decoration: const InputDecoration(
            labelText: 'Blade Type',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.palette),
          ),
          items: _getBladeTypeOptions().map((blade) {
            return DropdownMenuItem(value: blade, child: Text(blade));
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedBladeType = value);
          },
        ),
      ],
    );
  }

  Widget _buildCoxboxFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coxbox Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        SwitchListTile(
          title: const Text('Microphone Included'),
          value: _microphoneIncluded,
          onChanged: (value) {
            setState(() => _microphoneIncluded = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _batteryStatus,
          decoration: const InputDecoration(
            labelText: 'Battery Status',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.battery_full),
          ),
          items: ['Good', 'Fair', 'Needs Replacement'].map((status) {
            return DropdownMenuItem(value: status, child: Text(status));
          }).toList(),
          onChanged: (value) {
            setState(() => _batteryStatus = value!);
          },
        ),
      ],
    );
  }

  Widget _buildLaunchFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Launch Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        SwitchListTile(
          title: const Text('Gas Tank Assigned'),
          value: _gasTankAssigned,
          onChanged: (value) {
            setState(() => _gasTankAssigned = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        if (_gasTankAssigned) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _tankNumberController,
            decoration: const InputDecoration(
              labelText: 'Tank Number',
              border: OutlineInputBorder(),
              hintText: 'e.g., Tank #3',
              prefixIcon: Icon(Icons.local_gas_station),
            ),
          ),
        ],

        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _fuelType,
          decoration: const InputDecoration(
            labelText: 'Fuel Type',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_gas_station),
          ),
          items: ['Gas', 'Diesel'].map((fuel) {
            return DropdownMenuItem(value: fuel, child: Text(fuel));
          }).toList(),
          onChanged: (value) {
            setState(() => _fuelType = value!);
          },
        ),
      ],
    );
  }

  Widget _buildErgFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Erg Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _ergIdController,
          decoration: const InputDecoration(
            labelText: 'Erg ID/Number *',
            border: OutlineInputBorder(),
            hintText: 'e.g., Erg #12 or "Back Left"',
            prefixIcon: Icon(Icons.tag),
          ),
        ),
      ],
    );
  }
}
