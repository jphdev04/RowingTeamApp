import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../models/team.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';
import '../services/team_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';
import '../services/membership_service.dart';
import '../models/membership.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class AddEquipmentScreen extends StatefulWidget {
  final String organizationId;
  final Organization? organization;
  final Team? team;

  const AddEquipmentScreen({
    super.key,
    required this.organizationId,
    this.organization,
    this.team,
  });

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentService = EquipmentService();
  final _teamService = TeamService();

  EquipmentType? _selectedType;
  final _nameController = TextEditingController();
  String? _selectedManufacturer;
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _serialNumberController = TextEditingController();
  DateTime? _purchaseDate;
  final _purchasePriceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _availableToAllTeams = true;
  final Set<String> _selectedTeamIds = {};

  // Shell-specific
  ShellType? _selectedShellType;
  RiggingType? _selectedRiggingType;
  RiggingSetup? _riggingSetup;

  // Oar-specific
  OarType? _selectedOarType;
  final _oarCountController = TextEditingController();
  String? _selectedBladeType;
  final _oarLengthController = TextEditingController();

  // Coxbox-specific
  bool _microphoneIncluded = true;
  String _batteryStatus = 'Good';
  CoxboxType? _selectedCoxboxType;
  String? _assignedToId;
  String? _assignedToName;

  // Launch-specific
  bool _gasTankAssigned = false;
  final _tankNumberController = TextEditingController();
  String _fuelType = 'Gas';

  // Erg-specific
  final _ergIdController = TextEditingController();
  String? _selectedErgModel;

  bool _isLoading = false;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization?.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  bool get _isSweepShell =>
      _selectedType == EquipmentType.shell &&
      _selectedShellType != null &&
      _selectedRiggingType != RiggingType.scull &&
      !_isScullShellType(_selectedShellType!);

  bool _isScullShellType(ShellType st) =>
      st == ShellType.single ||
      st == ShellType.double ||
      st == ShellType.quad ||
      st == ShellType.coxedQuad;

  int _seatCountForShellType(ShellType st) {
    switch (st) {
      case ShellType.eight:
        return 8;
      case ShellType.coxedFour:
      case ShellType.four:
      case ShellType.quad:
      case ShellType.coxedQuad:
        return 4;
      case ShellType.pair:
      case ShellType.double:
        return 2;
      case ShellType.single:
        return 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _serialNumberController.dispose();
    _purchasePriceController.dispose();
    _notesController.dispose();
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

  List<String> _getBladeTypeOptions() => [
    'Smoothie 2',
    'Comp',
    'Macon',
    'Fat2',
    'Hatchet',
    'Other',
  ];

  List<String> _getErgModelOptions() {
    if (_selectedManufacturer == 'Concept2')
      return ['Model D', 'Model E', 'RowErg', 'BikeErg', 'SkiErg'];
    if (_selectedManufacturer == 'RowPerfect') return ['RP3', 'RP Dynamic'];
    if (_selectedManufacturer == 'WaterRower')
      return ['Classic', 'Performance', 'Natural'];
    return [];
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null) {
      _showError('Please select equipment type');
      return;
    }
    if (_selectedManufacturer == null) {
      _showError('Please select manufacturer');
      return;
    }
    if (_selectedType == EquipmentType.shell && _selectedShellType == null) {
      _showError('Please select boat type');
      return;
    }
    if (_selectedType == EquipmentType.oar) {
      if (_selectedOarType == null) {
        _showError('Please select oar type');
        return;
      }
      if (_oarCountController.text.isEmpty) {
        _showError('Please enter number of oars');
        return;
      }
    }
    if (_selectedType == EquipmentType.erg && _ergIdController.text.isEmpty) {
      _showError('Please enter erg ID');
      return;
    }
    if (!_availableToAllTeams && _selectedTeamIds.isEmpty) {
      _showError('Please select at least one team or choose "All Teams"');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final equipment = Equipment(
        id: '',
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
        assignedTeamIds: _availableToAllTeams ? [] : _selectedTeamIds.toList(),
        createdAt: DateTime.now(),
        shellType: _selectedType == EquipmentType.shell
            ? _selectedShellType
            : null,
        riggingType: _selectedType == EquipmentType.shell
            ? _selectedRiggingType
            : null,
        riggingSetup: _selectedType == EquipmentType.shell
            ? _riggingSetup
            : null,
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
        microphoneIncluded: _selectedType == EquipmentType.coxbox
            ? _microphoneIncluded
            : null,
        batteryStatus: _selectedType == EquipmentType.coxbox
            ? _batteryStatus
            : null,
        coxboxType: _selectedType == EquipmentType.coxbox
            ? _selectedCoxboxType
            : null,
        assignedToId: _selectedType == EquipmentType.coxbox
            ? _assignedToId
            : null,
        assignedToName: _selectedType == EquipmentType.coxbox
            ? _assignedToName
            : null,
        gasTankAssigned: _selectedType == EquipmentType.launch
            ? _gasTankAssigned
            : null,
        tankNumber: _selectedType == EquipmentType.launch && _gasTankAssigned
            ? _tankNumberController.text.trim()
            : null,
        fuelType: _selectedType == EquipmentType.launch ? _fuelType : null,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TeamHeader(
            team: widget.team,
            organization: widget.team == null ? widget.organization : null,
            title: 'Add Equipment',
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Equipment Type ──
                  BoathouseStyles.sectionLabel('Equipment Type'),
                  _buildTypePicker(),
                  if (_selectedType != null) ...[
                    const SizedBox(height: 24),

                    // ── Basic Info ──
                    BoathouseStyles.sectionLabel('Basic Information'),
                    const SizedBox(height: 8),
                    if (_selectedType != EquipmentType.erg) ...[
                      BoathouseStyles.textField(
                        primaryColor: primaryColor,
                        controller: _nameController,
                        hintText: 'Name (optional)',
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildManufacturerPicker(),
                    const SizedBox(height: 12),
                    if (_selectedType == EquipmentType.erg &&
                        _getErgModelOptions().isNotEmpty)
                      _buildErgModelPicker()
                    else
                      BoathouseStyles.textField(
                        primaryColor: primaryColor,
                        controller: _modelController,
                        hintText: 'Model (optional)',
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: BoathouseStyles.textField(
                            primaryColor: primaryColor,
                            controller: _yearController,
                            hintText: 'Year',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BoathouseStyles.textField(
                            primaryColor: primaryColor,
                            controller: _serialNumberController,
                            hintText: 'Serial #',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickPurchaseDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 18,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _purchaseDate != null
                                        ? DateFormat(
                                            'MM/dd/yyyy',
                                          ).format(_purchaseDate!)
                                        : 'Purchase date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _purchaseDate != null
                                          ? Colors.grey[800]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BoathouseStyles.textField(
                            primaryColor: primaryColor,
                            controller: _purchasePriceController,
                            hintText: 'Price (\$)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Type-specific ──
                    _buildTypeSpecificFields(),

                    const SizedBox(height: 24),

                    // ── Team Assignment ──
                    BoathouseStyles.sectionLabel('Team Assignment'),
                    const SizedBox(height: 8),
                    BoathouseStyles.switchCard(
                      primaryColor: primaryColor,
                      switches: [
                        SwitchTileData(
                          title: 'Available to All Teams',
                          subtitle: 'Any team in the organization can use this',
                          value: _availableToAllTeams,
                          onChanged: (v) {
                            setState(() {
                              _availableToAllTeams = v;
                              if (v) _selectedTeamIds.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    if (!_availableToAllTeams) ...[
                      const SizedBox(height: 12),
                      StreamBuilder<List<Team>>(
                        stream: _teamService.getOrganizationTeams(
                          widget.organizationId,
                        ),
                        builder: (context, snapshot) {
                          final teams = snapshot.data ?? [];
                          if (teams.isEmpty) {
                            return Text(
                              'No teams available.',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            );
                          }
                          return BoathouseStyles.card(
                            child: Column(
                              children: teams.map((team) {
                                return CheckboxListTile(
                                  title: Text(team.name),
                                  activeColor: primaryColor,
                                  value: _selectedTeamIds.contains(team.id),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true)
                                        _selectedTeamIds.add(team.id);
                                      else
                                        _selectedTeamIds.remove(team.id);
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

                    // ── Notes ──
                    BoathouseStyles.sectionLabel('Notes'),
                    const SizedBox(height: 8),
                    BoathouseStyles.textField(
                      primaryColor: primaryColor,
                      controller: _notesController,
                      hintText: 'Optional notes...',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),
                    BoathouseStyles.primaryButton(
                      primaryColor: primaryColor,
                      label: 'Save Equipment',
                      isLoading: _isLoading,
                      onPressed: _saveEquipment,
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // TYPE PICKER (toggle chips)
  // ════════════════════════════════════════════════════════════

  Widget _buildTypePicker() {
    final types = EquipmentType.values;
    final labels = types.map((t) {
      switch (t) {
        case EquipmentType.shell:
          return 'Shell';
        case EquipmentType.oar:
          return 'Oars';
        case EquipmentType.coxbox:
          return 'Coxbox';
        case EquipmentType.launch:
          return 'Launch';
        case EquipmentType.erg:
          return 'Erg';
      }
    }).toList();
    final icons = [
      Icons.directions_boat,
      Icons.sports_hockey,
      Icons.headset_mic,
      Icons.speed,
      Icons.fitness_center,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(types.length, (i) {
        final isSelected = _selectedType == types[i];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = types[i];
              _selectedManufacturer = null;
              _selectedErgModel = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icons[i],
                  size: 18,
                  color: isSelected ? primaryColor : Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? primaryColor : Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ════════════════════════════════════════════════════════════
  // MANUFACTURER (bottom sheet)
  // ════════════════════════════════════════════════════════════

  Widget _buildManufacturerPicker() {
    return InkWell(
      onTap: _showManufacturerPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.business, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedManufacturer ?? 'Select manufacturer',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedManufacturer != null
                      ? Colors.grey[800]
                      : Colors.grey[400],
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showManufacturerPicker() {
    final options = _getManufacturerOptions();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manufacturer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (m) => ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: _selectedManufacturer == m
                    ? primaryColor.withOpacity(0.08)
                    : null,
                title: Text(m),
                trailing: _selectedManufacturer == m
                    ? Icon(Icons.check_circle, color: primaryColor, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedManufacturer = m;
                    _selectedErgModel = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildErgModelPicker() {
    return InkWell(
      onTap: _showErgModelPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Text(
              _selectedErgModel ?? 'Select model',
              style: TextStyle(
                fontSize: 14,
                color: _selectedErgModel != null
                    ? Colors.grey[800]
                    : Colors.grey[400],
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showErgModelPicker() {
    final options = _getErgModelOptions();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (m) => ListTile(
                title: Text(m),
                trailing: _selectedErgModel == m
                    ? Icon(Icons.check_circle, color: primaryColor, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedErgModel = m);
                  _modelController.text = m;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _purchaseDate = date);
  }

  // ════════════════════════════════════════════════════════════
  // TYPE-SPECIFIC FIELDS
  // ════════════════════════════════════════════════════════════

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
        BoathouseStyles.sectionLabel('Shell Details'),
        const SizedBox(height: 8),
        _buildShellTypePicker(),
        const SizedBox(height: 12),
        _buildRiggingTypePicker(),
        if (_isSweepShell) ...[
          const SizedBox(height: 16),
          _buildRiggingSetupSection(),
        ],
      ],
    );
  }

  Widget _buildShellTypePicker() {
    final display = _selectedShellType != null
        ? _shellTypeDisplay(_selectedShellType!)
        : null;
    return InkWell(
      onTap: _showShellTypePicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.rowing, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Text(
              display ?? 'Select boat class',
              style: TextStyle(
                fontSize: 14,
                color: display != null ? Colors.grey[800] : Colors.grey[400],
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showShellTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Boat Class',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...ShellType.values.map((t) {
              final isSelected = _selectedShellType == t;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: isSelected ? primaryColor.withOpacity(0.08) : null,
                leading: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _shellTypeShort(t),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(_shellTypeDisplay(t)),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: primaryColor, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedShellType = t;
                    _riggingSetup = null; // reset rig when boat class changes
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRiggingTypePicker() {
    final display = _selectedRiggingType != null
        ? _riggingTypeDisplay(_selectedRiggingType!)
        : null;
    return InkWell(
      onTap: _showRiggingTypePicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.settings, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Text(
              display ?? 'Select rigging type',
              style: TextStyle(
                fontSize: 14,
                color: display != null ? Colors.grey[800] : Colors.grey[400],
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showRiggingTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rigging Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...RiggingType.values.map(
              (t) => ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: _selectedRiggingType == t
                    ? primaryColor.withOpacity(0.08)
                    : null,
                title: Text(_riggingTypeDisplay(t)),
                trailing: _selectedRiggingType == t
                    ? Icon(Icons.check_circle, color: primaryColor, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedRiggingType = t);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rigging Setup (inline preset picker + mini diagram) ──

  Widget _buildRiggingSetupSection() {
    final seatCount = _seatCountForShellType(_selectedShellType!);
    if (seatCount <= 1) return const SizedBox.shrink();

    final rig = _riggingSetup ?? RiggingPresets.standardPortStroke(seatCount);

    return BoathouseStyles.card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Rigging Setup',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showRiggingPresetPicker(seatCount),
                child: Text(
                  _riggingSetup != null ? 'Change' : 'Set Up',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rig.description,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          _buildMiniRiggingPreview(rig),
        ],
      ),
    );
  }

  Widget _buildMiniRiggingPreview(RiggingSetup rig) {
    return Row(
      children: rig.positions.reversed.map((p) {
        final total = rig.positions.length;
        final label = p.seat == total
            ? 'S'
            : p.seat == 1
            ? 'B'
            : '${p.seat}';
        final isPort = p.side == RiggerSide.port;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isPort
                  ? Colors.red.withOpacity(0.15)
                  : Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isPort
                    ? Colors.red.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isPort ? Colors.red[700] : Colors.green[700],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showRiggingPresetPicker(int seatCount) {
    final presets = RiggingPresets.presetsForSeatCount(seatCount);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rigging Preset',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              'You can customize further after saving',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            ...presets.map((preset) {
              final isCurrent = _riggingSetup?.name == preset.name;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: isCurrent ? primaryColor.withOpacity(0.08) : null,
                title: Text(
                  preset.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  preset.positions.reversed
                      .map((p) {
                        final l = p.seat == seatCount
                            ? 'S'
                            : p.seat == 1
                            ? 'B'
                            : '${p.seat}';
                        return '$l:${p.side == RiggerSide.port ? 'P' : 'S'}';
                      })
                      .join('  '),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                trailing: isCurrent
                    ? Icon(Icons.check_circle, color: primaryColor, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _riggingSetup = preset);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOarFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('Oar Details'),
        const SizedBox(height: 8),
        _buildOarTypePicker(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BoathouseStyles.textField(
                primaryColor: primaryColor,
                controller: _oarCountController,
                hintText: 'Number of oars',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BoathouseStyles.textField(
                primaryColor: primaryColor,
                controller: _oarLengthController,
                hintText: 'Length (cm)',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBladeTypePicker(),
      ],
    );
  }

  Widget _buildOarTypePicker() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: OarType.values
                  .map(
                    (t) => ListTile(
                      title: Text(t == OarType.sweep ? 'Sweep' : 'Scull'),
                      trailing: _selectedOarType == t
                          ? Icon(
                              Icons.check_circle,
                              color: primaryColor,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedOarType = t);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.sports_hockey, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Text(
              _selectedOarType != null
                  ? (_selectedOarType == OarType.sweep ? 'Sweep' : 'Scull')
                  : 'Select oar type',
              style: TextStyle(
                fontSize: 14,
                color: _selectedOarType != null
                    ? Colors.grey[800]
                    : Colors.grey[400],
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildBladeTypePicker() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _getBladeTypeOptions()
                  .map(
                    (b) => ListTile(
                      title: Text(b),
                      trailing: _selectedBladeType == b
                          ? Icon(
                              Icons.check_circle,
                              color: primaryColor,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedBladeType = b);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.palette, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Text(
              _selectedBladeType ?? 'Select blade type',
              style: TextStyle(
                fontSize: 14,
                color: _selectedBladeType != null
                    ? Colors.grey[800]
                    : Colors.grey[400],
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildCoxboxFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('Electronics Type'),
        const SizedBox(height: 8),

        // ── Coxbox vs SpeedCoach toggle ──
        BoathouseStyles.toggleChipRow(
          primaryColor: primaryColor,
          labels: ['Coxbox', 'SpeedCoach'],
          icons: [Icons.speaker, Icons.speed],
          selectedIndex: _selectedCoxboxType == CoxboxType.speedcoach ? 1 : 0,
          onSelected: (i) {
            setState(() {
              _selectedCoxboxType = i == 0
                  ? CoxboxType.coxbox
                  : CoxboxType.speedcoach;
              // Clear assignment when switching type
              _assignedToId = null;
              _assignedToName = null;
            });
          },
        ),
        const SizedBox(height: 16),

        BoathouseStyles.sectionLabel(
          _selectedCoxboxType == CoxboxType.speedcoach
              ? 'SpeedCoach Details'
              : 'Coxbox Details',
        ),
        const SizedBox(height: 8),

        BoathouseStyles.switchCard(
          primaryColor: primaryColor,
          switches: [
            SwitchTileData(
              title: 'Microphone Included',
              value: _microphoneIncluded,
              onChanged: (v) => setState(() => _microphoneIncluded = v),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Battery status picker (existing — keep as-is)
        _buildBatteryStatusPicker(),

        const SizedBox(height: 16),

        // ── Assignment Section ──
        BoathouseStyles.sectionLabel(
          _selectedCoxboxType == CoxboxType.speedcoach
              ? 'Assign to Shell (Optional)'
              : 'Assign to Coxswain (Optional)',
        ),
        const SizedBox(height: 8),
        _buildAssignmentPicker(),
      ],
    );
  }

  Widget _buildBatteryStatusPicker() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Battery Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ...['Good', 'Fair', 'Needs Replacement'].map(
                  (s) => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: _batteryStatus == s
                        ? primaryColor.withOpacity(0.08)
                        : null,
                    title: Text(s),
                    trailing: _batteryStatus == s
                        ? Icon(
                            Icons.check_circle,
                            color: primaryColor,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _batteryStatus = s);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.battery_full, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Text(
              'Battery: $_batteryStatus',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentPicker() {
    return InkWell(
      onTap: () => _showAssignmentSheet(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _assignedToId != null
                ? primaryColor.withOpacity(0.5)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedCoxboxType == CoxboxType.speedcoach
                  ? Icons.rowing
                  : Icons.person,
              size: 18,
              color: _assignedToId != null ? primaryColor : Colors.grey[400],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _assignedToName ?? 'Tap to assign...',
                style: TextStyle(
                  fontSize: 14,
                  color: _assignedToName != null
                      ? Colors.grey[800]
                      : Colors.grey[400],
                ),
              ),
            ),
            if (_assignedToId != null)
              GestureDetector(
                onTap: () => setState(() {
                  _assignedToId = null;
                  _assignedToName = null;
                }),
                child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showAssignmentSheet() {
    if (_selectedCoxboxType == CoxboxType.speedcoach) {
      _showShellAssignmentSheet();
    } else {
      _showCoxswainAssignmentSheet();
    }
  }

  void _showCoxswainAssignmentSheet() {
    final membershipService = MembershipService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          expand: false,
          builder: (ctx, scrollController) {
            return StreamBuilder<List<Membership>>(
              stream: membershipService.getOrganizationMemberships(
                widget.organizationId,
              ),
              builder: (ctx, snapshot) {
                final members = (snapshot.data ?? [])
                    .where((m) => m.role == MembershipRole.coxswain)
                    .toList();

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assign to Coxswain',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (_assignedToId != null)
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _assignedToId = null;
                                  _assignedToName = null;
                                });
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (members.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No coxswains found',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: members.length,
                            itemBuilder: (ctx, i) {
                              final m = members[i];
                              final isSelected = m.userId == _assignedToId;
                              return FutureBuilder<AppUser?>(
                                future: UserService().getUser(m.userId),
                                builder: (ctx, userSnap) {
                                  final userName =
                                      userSnap.data?.name ?? 'Loading...';
                                  if (userSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey.shade200,
                                        radius: 18,
                                      ),
                                      title: Text(
                                        'Loading...',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    );
                                  }
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? primaryColor
                                          : Colors.grey.shade200,
                                      radius: 18,
                                      child: Text(
                                        userName.isNotEmpty
                                            ? userName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(userName),
                                    subtitle: Text(
                                      m.role.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle,
                                            color: primaryColor,
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      setState(() {
                                        _assignedToId = m.userId;
                                        _assignedToName = userName;
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Bottom sheet to pick a shell to assign a speedcoach to.
  void _showShellAssignmentSheet() {
    final equipmentService = EquipmentService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          expand: false,
          builder: (ctx, scrollController) {
            return StreamBuilder<List<Equipment>>(
              stream: equipmentService.getEquipmentByTeam(
                widget.organizationId,
              ),
              builder: (ctx, snapshot) {
                final shells =
                    (snapshot.data ?? [])
                        .where((e) => e.type == EquipmentType.shell)
                        .toList()
                      ..sort((a, b) => a.displayName.compareTo(b.displayName));

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assign to Shell',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (_assignedToId != null)
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _assignedToId = null;
                                  _assignedToName = null;
                                });
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (shells.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No shells found',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: shells.length,
                            itemBuilder: (ctx, i) {
                              final shell = shells[i];
                              final isSelected = shell.id == _assignedToId;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? primaryColor
                                      : Colors.grey.shade200,
                                  radius: 18,
                                  child: Icon(
                                    Icons.rowing,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                                title: Text(shell.displayName),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: primaryColor,
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _assignedToId = shell.id;
                                    _assignedToName = shell.displayName;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLaunchFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('Launch Details'),
        const SizedBox(height: 8),
        BoathouseStyles.switchCard(
          primaryColor: primaryColor,
          switches: [
            SwitchTileData(
              title: 'Gas Tank Assigned',
              value: _gasTankAssigned,
              onChanged: (v) => setState(() => _gasTankAssigned = v),
            ),
          ],
        ),
        if (_gasTankAssigned) ...[
          const SizedBox(height: 12),
          BoathouseStyles.textField(
            primaryColor: primaryColor,
            controller: _tankNumberController,
            hintText: 'Tank number',
          ),
        ],
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Gas', 'Diesel']
                      .map(
                        (f) => ListTile(
                          title: Text(f),
                          trailing: _fuelType == f
                              ? Icon(
                                  Icons.check_circle,
                                  color: primaryColor,
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _fuelType = f);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_gas_station,
                  size: 18,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 10),
                Text(
                  'Fuel: $_fuelType',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErgFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('Erg Details'),
        const SizedBox(height: 8),
        BoathouseStyles.textField(
          primaryColor: primaryColor,
          controller: _ergIdController,
          hintText: 'Erg ID / Number',
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // DISPLAY HELPERS
  // ════════════════════════════════════════════════════════════

  String _shellTypeDisplay(ShellType t) {
    switch (t) {
      case ShellType.eight:
        return '8+ (Eight)';
      case ShellType.coxedFour:
        return '4+ (Coxed Four)';
      case ShellType.four:
        return '4- (Coxless Four)';
      case ShellType.quad:
        return '4x (Quad)';
      case ShellType.coxedQuad:
        return '4x+ (Coxed Quad)';
      case ShellType.pair:
        return '2- (Pair)';
      case ShellType.double:
        return '2x (Double)';
      case ShellType.single:
        return '1x (Single)';
    }
  }

  String _shellTypeShort(ShellType t) {
    switch (t) {
      case ShellType.eight:
        return '8+';
      case ShellType.coxedFour:
        return '4+';
      case ShellType.four:
        return '4-';
      case ShellType.quad:
        return '4x';
      case ShellType.coxedQuad:
        return '4x+';
      case ShellType.pair:
        return '2-';
      case ShellType.double:
        return '2x';
      case ShellType.single:
        return '1x';
    }
  }

  String _riggingTypeDisplay(RiggingType t) {
    switch (t) {
      case RiggingType.sweep:
        return 'Sweep Only';
      case RiggingType.scull:
        return 'Scull Only';
      case RiggingType.dualRigged:
        return 'Dual-Rigged (Both)';
    }
  }
}
