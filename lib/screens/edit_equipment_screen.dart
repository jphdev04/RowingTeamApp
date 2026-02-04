import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../models/team.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';
import '../services/team_service.dart';

class EditEquipmentScreen extends StatefulWidget {
  final Equipment equipment;
  final String organizationId;
  final Organization? organization;
  final Team? team;

  const EditEquipmentScreen({
    super.key,
    required this.equipment,
    required this.organizationId,
    this.organization,
    this.team,
  });

  @override
  State<EditEquipmentScreen> createState() => _EditEquipmentScreenState();
}

class _EditEquipmentScreenState extends State<EditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentService = EquipmentService();
  final _teamService = TeamService();

  // Common fields
  late EquipmentType _selectedType;
  final _nameController = TextEditingController();
  late String _selectedManufacturer;
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _serialNumberController = TextEditingController();
  DateTime? _purchaseDate;
  final _purchasePriceController = TextEditingController();
  final _notesController = TextEditingController();

  // Team assignment
  late bool _availableToAllTeams;
  final Set<String> _selectedTeamIds = {};

  // Status
  late EquipmentStatus _selectedStatus;

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
  void initState() {
    super.initState();
    _loadEquipmentData();
  }

  void _loadEquipmentData() {
    final eq = widget.equipment;

    _selectedType = eq.type;
    _nameController.text = eq.name ?? '';
    _selectedManufacturer = eq.manufacturer;
    _modelController.text = eq.model ?? '';
    _yearController.text = eq.year?.toString() ?? '';
    _serialNumberController.text = eq.serialNumber ?? '';
    _purchaseDate = eq.purchaseDate;
    _purchasePriceController.text = eq.purchasePrice?.toString() ?? '';
    _notesController.text = eq.notes ?? '';
    _availableToAllTeams = eq.availableToAllTeams;
    _selectedTeamIds.addAll(eq.assignedTeamIds);
    _selectedStatus = eq.status;

    // Shell-specific
    _selectedShellType = eq.shellType;
    _selectedRiggingType = eq.riggingType;
    _currentRiggingController.text = eq.currentRiggingSetup ?? '';

    // Oar-specific
    _selectedOarType = eq.oarType;
    _oarCountController.text = eq.oarCount?.toString() ?? '';
    _selectedBladeType = eq.bladeType;
    _oarLengthController.text = eq.oarLength?.toString() ?? '';

    // Coxbox-specific
    _microphoneIncluded = eq.microphoneIncluded ?? true;
    _batteryStatus = eq.batteryStatus ?? 'Good';

    // Launch-specific
    _gasTankAssigned = eq.gasTankAssigned ?? false;
    _tankNumberController.text = eq.tankNumber ?? '';
    _fuelType = eq.fuelType ?? 'Gas';

    // Erg-specific
    _ergIdController.text = eq.ergId ?? '';
    _selectedErgModel = eq.model;
  }

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

  List<String> _getBladeTypeOptions() {
    return ['Smoothie 2', 'Comp', 'Macon', 'Fat2', 'Hatchet', 'Other'];
  }

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
      // Validation
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
        final updatedEquipment = widget.equipment.copyWith(
          name: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          manufacturer: _selectedManufacturer,
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
          status: _selectedStatus,

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

        await _equipmentService.updateEquipment(updatedEquipment);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipment updated successfully!'),
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

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment?'),
        content: Text(
          'Are you sure you want to delete "${widget.equipment.displayName}"? This action cannot be undone.',
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
        await _equipmentService.deleteEquipment(widget.equipment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipment deleted'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
          Navigator.of(context).pop(); // Pop detail screen too
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.team?.primaryColorObj ??
        widget.organization?.primaryColorObj ??
        const Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 16,
              24,
              24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  widget.team?.secondaryColorObj ??
                      widget.organization?.secondaryColorObj ??
                      primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                  'Edit Equipment',
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

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status
                    DropdownButtonFormField<EquipmentStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: EquipmentStatus.values.map((status) {
                        String display =
                            status.name[0].toUpperCase() +
                            status.name.substring(1);
                        if (status == EquipmentStatus.inUse) display = 'In Use';
                        return DropdownMenuItem(
                          value: status,
                          child: Text(display),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                      },
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    if (_selectedType != EquipmentType.erg)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                      ),

                    if (_selectedType != EquipmentType.erg)
                      const SizedBox(height: 16),

                    // Manufacturer
                    DropdownButtonFormField<String>(
                      value: _selectedManufacturer,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer',
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
                          _selectedManufacturer = value!;
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
                          prefixIcon: Icon(Icons.info),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Year and Serial Number
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
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

                    // Purchase Date and Price
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
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Type-specific fields (same as add screen)
                    _buildTypeSpecificFields(),

                    const SizedBox(height: 24),

                    // Team Assignment
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
                      StreamBuilder<List<Team>>(
                        stream: _teamService.getOrganizationTeams(
                          widget.organizationId,
                        ),
                        builder: (context, snapshot) {
                          final teams = snapshot.data ?? [];
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Delete Button
                    OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text(
                        'Delete Equipment',
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

  // Type-specific fields (copy from add_equipment_screen.dart)
  Widget _buildTypeSpecificFields() {
    switch (_selectedType) {
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

  // Copy the _buildShellFields, _buildOarFields, etc. methods from add_equipment_screen.dart
  // They're identical, just paste them here

  Widget _buildShellFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shell Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<ShellType>(
          value: _selectedShellType,
          decoration: const InputDecoration(
            labelText: 'Boat Type',
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

        DropdownButtonFormField<OarType>(
          value: _selectedOarType,
          decoration: const InputDecoration(
            labelText: 'Oar Type',
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

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _oarCountController,
                decoration: const InputDecoration(
                  labelText: 'Number of Oars',
                  border: OutlineInputBorder(),
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
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

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
            labelText: 'Erg ID/Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.tag),
          ),
        ),
      ],
    );
  }
}
