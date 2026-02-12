import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../models/team.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';
import '../services/team_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';

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

  late EquipmentType _selectedType;
  final _nameController = TextEditingController();
  late String _selectedManufacturer;
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _serialNumberController = TextEditingController();
  DateTime? _purchaseDate;
  final _purchasePriceController = TextEditingController();
  final _notesController = TextEditingController();
  late bool _availableToAllTeams;
  final Set<String> _selectedTeamIds = {};
  late EquipmentStatus _selectedStatus;
  ShellType? _selectedShellType;
  RiggingType? _selectedRiggingType;
  RiggingSetup? _riggingSetup;
  OarType? _selectedOarType;
  final _oarCountController = TextEditingController();
  String? _selectedBladeType;
  final _oarLengthController = TextEditingController();
  bool _microphoneIncluded = true;
  String _batteryStatus = 'Good';
  bool _gasTankAssigned = false;
  final _tankNumberController = TextEditingController();
  String _fuelType = 'Gas';
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
  void initState() {
    super.initState();
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
    _selectedShellType = eq.shellType;
    _selectedRiggingType = eq.riggingType;
    _riggingSetup = eq.riggingSetup;
    _selectedOarType = eq.oarType;
    _oarCountController.text = eq.oarCount?.toString() ?? '';
    _selectedBladeType = eq.bladeType;
    _oarLengthController.text = eq.oarLength?.toString() ?? '';
    _microphoneIncluded = eq.microphoneIncluded ?? true;
    _batteryStatus = eq.batteryStatus ?? 'Good';
    _gasTankAssigned = eq.gasTankAssigned ?? false;
    _tankNumberController.text = eq.tankNumber ?? '';
    _fuelType = eq.fuelType ?? 'Gas';
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

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == EquipmentType.shell && _selectedShellType == null) {
      _showError('Please select boat type');
      return;
    }
    if (_selectedType == EquipmentType.oar && _selectedOarType == null) {
      _showError('Please select oar type');
      return;
    }
    if (_selectedType == EquipmentType.oar &&
        _oarCountController.text.isEmpty) {
      _showError('Enter number of oars');
      return;
    }
    if (_selectedType == EquipmentType.erg && _ergIdController.text.isEmpty) {
      _showError('Enter erg ID');
      return;
    }
    if (!_availableToAllTeams && _selectedTeamIds.isEmpty) {
      _showError('Select at least one team');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final u = widget.equipment.copyWith(
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
        assignedTeamIds: _availableToAllTeams ? [] : _selectedTeamIds.toList(),
        status: _selectedStatus,
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
      await _equipmentService.updateEquipment(u);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Equipment?'),
        content: Text(
          'Delete "${widget.equipment.displayName}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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
          Navigator.pop(context);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
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
            organization: widget.team == null ? widget.organization : null,
            title: 'Edit Equipment',
            subtitle: widget.equipment.displayName,
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
                  BoathouseStyles.sectionLabel('Status'),
                  _buildStatusPicker(),
                  const SizedBox(height: 24),
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
                          onTap: _pickDate,
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
                  _buildTypeSpecificFields(),
                  const SizedBox(height: 24),
                  BoathouseStyles.sectionLabel('Team Assignment'),
                  const SizedBox(height: 8),
                  BoathouseStyles.switchCard(
                    primaryColor: primaryColor,
                    switches: [
                      SwitchTileData(
                        title: 'Available to All Teams',
                        subtitle: 'Any team can use this',
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
                        if (teams.isEmpty)
                          return Text(
                            'No teams.',
                            style: TextStyle(color: Colors.grey[500]),
                          );
                        return BoathouseStyles.card(
                          child: Column(
                            children: teams
                                .map(
                                  (t) => CheckboxListTile(
                                    title: Text(t.name),
                                    activeColor: primaryColor,
                                    value: _selectedTeamIds.contains(t.id),
                                    onChanged: (c) {
                                      setState(() {
                                        if (c == true)
                                          _selectedTeamIds.add(t.id);
                                        else
                                          _selectedTeamIds.remove(t.id);
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
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
                    label: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: _saveEquipment,
                  ),
                  const SizedBox(height: 12),
                  BoathouseStyles.destructiveButton(
                    label: 'Delete Equipment',
                    onPressed: _confirmDelete,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _purchaseDate = d);
  }

  Widget _buildStatusPicker() => _sheetPicker(
    icon: Icons.circle,
    label: _statusLabel(_selectedStatus),
    color: _statusColor(_selectedStatus),
    onTap: () {
      _showSheet(
        'Status',
        EquipmentStatus.values
            .map(
              (s) => _SheetOption(
                label: _statusLabel(s),
                leading: CircleAvatar(
                  backgroundColor: _statusColor(s),
                  radius: 8,
                ),
                isSelected: _selectedStatus == s,
                onTap: () => setState(() => _selectedStatus = s),
              ),
            )
            .toList(),
      );
    },
  );
  Color _statusColor(EquipmentStatus s) {
    switch (s) {
      case EquipmentStatus.available:
        return Colors.green;
      case EquipmentStatus.inUse:
        return Colors.blue;
      case EquipmentStatus.damaged:
        return Colors.red;
      case EquipmentStatus.maintenance:
        return Colors.orange;
    }
  }

  String _statusLabel(EquipmentStatus s) {
    switch (s) {
      case EquipmentStatus.available:
        return 'Available';
      case EquipmentStatus.inUse:
        return 'In Use';
      case EquipmentStatus.damaged:
        return 'Damaged';
      case EquipmentStatus.maintenance:
        return 'Maintenance';
    }
  }

  Widget _buildManufacturerPicker() => _sheetPicker(
    icon: Icons.business,
    label: _selectedManufacturer,
    onTap: () {
      _showSheet(
        'Manufacturer',
        _getManufacturerOptions()
            .map(
              (m) => _SheetOption(
                label: m,
                isSelected: _selectedManufacturer == m,
                onTap: () => setState(() {
                  _selectedManufacturer = m;
                  _selectedErgModel = null;
                }),
              ),
            )
            .toList(),
      );
    },
  );
  Widget _buildErgModelPicker() => _sheetPicker(
    icon: Icons.info_outline,
    label: _selectedErgModel ?? 'Select model',
    isPlaceholder: _selectedErgModel == null,
    onTap: () {
      _showSheet(
        'Model',
        _getErgModelOptions()
            .map(
              (m) => _SheetOption(
                label: m,
                isSelected: _selectedErgModel == m,
                onTap: () {
                  setState(() => _selectedErgModel = m);
                  _modelController.text = m;
                },
              ),
            )
            .toList(),
      );
    },
  );

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

  Widget _buildShellFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      BoathouseStyles.sectionLabel('Shell Details'),
      const SizedBox(height: 8),
      _sheetPicker(
        icon: Icons.rowing,
        label: _selectedShellType != null
            ? _shellTypeDisplay(_selectedShellType!)
            : 'Select boat class',
        isPlaceholder: _selectedShellType == null,
        onTap: () {
          _showSheet(
            'Boat Class',
            ShellType.values
                .map(
                  (t) => _SheetOption(
                    label: _shellTypeDisplay(t),
                    leadingText: _shellTypeShort(t),
                    isSelected: _selectedShellType == t,
                    onTap: () => setState(() {
                      _selectedShellType = t;
                      _riggingSetup = null;
                    }),
                  ),
                )
                .toList(),
          );
        },
      ),
      const SizedBox(height: 12),
      _sheetPicker(
        icon: Icons.settings,
        label: _selectedRiggingType != null
            ? _riggingTypeDisplay(_selectedRiggingType!)
            : 'Select rigging type',
        isPlaceholder: _selectedRiggingType == null,
        onTap: () {
          _showSheet(
            'Rigging Type',
            RiggingType.values
                .map(
                  (t) => _SheetOption(
                    label: _riggingTypeDisplay(t),
                    isSelected: _selectedRiggingType == t,
                    onTap: () => setState(() => _selectedRiggingType = t),
                  ),
                )
                .toList(),
          );
        },
      ),
      if (_isSweepShell) ...[
        const SizedBox(height: 16),
        _buildRiggingSetupSection(),
      ],
    ],
  );

  Widget _buildRiggingSetupSection() {
    final sc = _seatCountForShellType(_selectedShellType!);
    if (sc <= 1) return const SizedBox.shrink();
    final rig = _riggingSetup ?? RiggingPresets.standardPortStroke(sc);
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
                onPressed: () => _showRigPresets(sc),
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
          Row(
            children: rig.positions.reversed.map((p) {
              final t = rig.positions.length;
              final l = p.seat == t
                  ? 'S'
                  : p.seat == 1
                  ? 'B'
                  : '${p.seat}';
              final ip = p.side == RiggerSide.port;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: ip
                        ? Colors.red.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ip
                          ? Colors.red.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ip ? Colors.red[700] : Colors.green[700],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showRigPresets(int sc) {
    final presets = RiggingPresets.presetsForSeatCount(sc);
    _showSheet(
      'Rigging Preset',
      presets
          .map(
            (p) => _SheetOption(
              label: p.name,
              subtitle: p.positions.reversed
                  .map((r) {
                    final l = r.seat == sc
                        ? 'S'
                        : r.seat == 1
                        ? 'B'
                        : '${r.seat}';
                    return '$l:${r.side == RiggerSide.port ? 'P' : 'S'}';
                  })
                  .join('  '),
              isSelected: _riggingSetup?.name == p.name,
              onTap: () => setState(() => _riggingSetup = p),
            ),
          )
          .toList(),
    );
  }

  Widget _buildOarFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      BoathouseStyles.sectionLabel('Oar Details'),
      const SizedBox(height: 8),
      _sheetPicker(
        icon: Icons.sports_hockey,
        label: _selectedOarType != null
            ? (_selectedOarType == OarType.sweep ? 'Sweep' : 'Scull')
            : 'Select oar type',
        isPlaceholder: _selectedOarType == null,
        onTap: () {
          _showSheet(
            'Oar Type',
            OarType.values
                .map(
                  (t) => _SheetOption(
                    label: t == OarType.sweep ? 'Sweep' : 'Scull',
                    isSelected: _selectedOarType == t,
                    onTap: () => setState(() => _selectedOarType = t),
                  ),
                )
                .toList(),
          );
        },
      ),
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
      _sheetPicker(
        icon: Icons.palette,
        label: _selectedBladeType ?? 'Select blade type',
        isPlaceholder: _selectedBladeType == null,
        onTap: () {
          _showSheet(
            'Blade Type',
            _getBladeTypeOptions()
                .map(
                  (b) => _SheetOption(
                    label: b,
                    isSelected: _selectedBladeType == b,
                    onTap: () => setState(() => _selectedBladeType = b),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );

  Widget _buildCoxboxFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      BoathouseStyles.sectionLabel('Coxbox Details'),
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
      _sheetPicker(
        icon: Icons.battery_full,
        label: 'Battery: $_batteryStatus',
        onTap: () {
          _showSheet(
            'Battery Status',
            ['Good', 'Fair', 'Needs Replacement']
                .map(
                  (s) => _SheetOption(
                    label: s,
                    isSelected: _batteryStatus == s,
                    onTap: () => setState(() => _batteryStatus = s),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );

  Widget _buildLaunchFields() => Column(
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
      _sheetPicker(
        icon: Icons.local_gas_station,
        label: 'Fuel: $_fuelType',
        onTap: () {
          _showSheet(
            'Fuel Type',
            ['Gas', 'Diesel']
                .map(
                  (f) => _SheetOption(
                    label: f,
                    isSelected: _fuelType == f,
                    onTap: () => setState(() => _fuelType = f),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );

  Widget _buildErgFields() => Column(
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

  // ── Reusable bottom sheet picker row ──
  Widget _sheetPicker({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPlaceholder = false,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
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
            if (color != null)
              CircleAvatar(backgroundColor: color, radius: 6)
            else
              Icon(icon, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isPlaceholder ? Colors.grey[400] : Colors.grey[800],
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showSheet(String title, List<_SheetOption> options) {
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
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (o) => ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: o.isSelected ? primaryColor.withOpacity(0.08) : null,
                leading:
                    o.leading ??
                    (o.leadingText != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              o.leadingText!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : null),
                title: Text(o.label),
                subtitle: o.subtitle != null
                    ? Text(
                        o.subtitle!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      )
                    : null,
                trailing: o.isSelected
                    ? Icon(Icons.check_circle, color: primaryColor, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  o.onTap();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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

class _SheetOption {
  final String label;
  final String? subtitle;
  final String? leadingText;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback onTap;
  _SheetOption({
    required this.label,
    this.subtitle,
    this.leadingText,
    this.leading,
    required this.isSelected,
    required this.onTap,
  });
}
