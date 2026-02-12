import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import '../models/team.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';

class ReportDamageScreen extends StatefulWidget {
  final String organizationId;
  final String userId;
  final String userName;
  final Organization? organization;
  final Team? team;

  const ReportDamageScreen({
    super.key,
    required this.organizationId,
    required this.userId,
    required this.userName,
    this.organization,
    this.team,
  });

  @override
  State<ReportDamageScreen> createState() => _ReportDamageScreenState();
}

class _ReportDamageScreenState extends State<ReportDamageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentService = EquipmentService();
  final _descriptionController = TextEditingController();

  Equipment? _selectedEquipment;
  List<Equipment> _equipmentList = [];
  bool _isLoading = false;
  bool _isLoadingEquipment = true;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization?.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadEquipment() {
    _equipmentService.getEquipmentByTeam(widget.organizationId).listen((
      equipment,
    ) {
      if (mounted) {
        // Sort by type then name
        equipment.sort((a, b) {
          final typeCompare = a.type.name.compareTo(b.type.name);
          if (typeCompare != 0) return typeCompare;
          return a.displayName.compareTo(b.displayName);
        });
        setState(() {
          _equipmentList = equipment;
          _isLoadingEquipment = false;
          // Re-match selected equipment by ID after stream rebuild
          if (_selectedEquipment != null) {
            _selectedEquipment = equipment
                .where((e) => e.id == _selectedEquipment!.id)
                .firstOrNull;
          }
        });
      }
    });
  }

  void _showEquipmentPicker() {
    if (_equipmentList.isEmpty) return;

    // Group equipment by type
    final grouped = <EquipmentType, List<Equipment>>{};
    for (final eq in _equipmentList) {
      grouped.putIfAbsent(eq.type, () => []).add(eq);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Equipment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (_selectedEquipment != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedEquipment = null);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _equipmentList.length,
                      itemBuilder: (ctx, i) {
                        final eq = _equipmentList[i];
                        final isSelected = _selectedEquipment?.id == eq.id;

                        // Show type header before first item of each type
                        final showHeader =
                            i == 0 || _equipmentList[i - 1].type != eq.type;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showHeader) ...[
                              if (i > 0) const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 6,
                                ),
                                child: Text(
                                  _getTypeLabelPlural(eq.type),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? primaryColor
                                    : Colors.grey.shade200,
                                radius: 18,
                                child: Icon(
                                  _getTypeIcon(eq.type),
                                  size: 18,
                                  color: isSelected
                                      ? _onPrimary
                                      : Colors.grey[600],
                                ),
                              ),
                              title: Text(eq.displayName),
                              subtitle: eq.isDamaged
                                  ? const Text(
                                      'Already has damage reported',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: primaryColor,
                                    )
                                  : null,
                              onTap: () {
                                Navigator.pop(ctx);
                                setState(() => _selectedEquipment = eq);
                              },
                            ),
                          ],
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
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedEquipment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select equipment')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final damageReport = DamageReport(
          id: const Uuid().v4(),
          reportedBy: widget.userId,
          reportedByName: widget.userName,
          reportedAt: DateTime.now(),
          description: _descriptionController.text.trim(),
          isResolved: false,
        );

        await _equipmentService.addDamageReport(
          _selectedEquipment!.id,
          damageReport,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Damage report submitted successfully!'),
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
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          TeamHeader(
            team: widget.team,
            organization: widget.organization,
            title: 'Report Damage',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: _onPrimary,
              onPressed: () => Navigator.of(context).pop(),
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
                    // Icon + title
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Report Equipment Damage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Help keep everyone safe by reporting damaged equipment',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 28),

                    // Equipment Selector
                    BoathouseStyles.sectionLabel('Select Equipment'),
                    const SizedBox(height: 8),

                    if (_isLoadingEquipment)
                      const Center(child: CircularProgressIndicator())
                    else if (_equipmentList.isEmpty)
                      BoathouseStyles.card(
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No equipment available',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _showEquipmentPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedEquipment != null
                                  ? primaryColor.withOpacity(0.5)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedEquipment != null
                                    ? _getTypeIcon(_selectedEquipment!.type)
                                    : Icons.rowing,
                                color: _selectedEquipment != null
                                    ? primaryColor
                                    : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedEquipment?.displayName ??
                                      'Tap to select equipment...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _selectedEquipment != null
                                        ? Colors.grey[800]
                                        : Colors.grey[500],
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Description
                    BoathouseStyles.sectionLabel('Describe the Damage'),
                    const SizedBox(height: 8),

                    BoathouseStyles.textField(
                      primaryColor: primaryColor,
                      controller: _descriptionController,
                      hintText:
                          'e.g., Cracked rigger on starboard side, loose bolt on seat',
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe the damage';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    BoathouseStyles.primaryButton(
                      primaryColor: Colors.red,
                      label: 'Submit Damage Report',
                      icon: Icons.report_outlined,
                      isLoading: _isLoading,
                      onPressed: _submitReport,
                    ),

                    const SizedBox(height: 16),

                    // Info card
                    BoathouseStyles.card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your report will notify coaches and boatmen immediately. The equipment will be marked as damaged until repaired.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
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

  IconData _getTypeIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.shell:
        return Icons.rowing;
      case EquipmentType.oar:
        return Icons.sports_kabaddi;
      case EquipmentType.coxbox:
        return Icons.speaker;
      case EquipmentType.launch:
        return Icons.directions_boat;
      case EquipmentType.erg:
        return Icons.fitness_center;
    }
  }

  String _getTypeLabelPlural(EquipmentType type) {
    switch (type) {
      case EquipmentType.shell:
        return 'SHELLS';
      case EquipmentType.oar:
        return 'OARS';
      case EquipmentType.coxbox:
        return 'COXBOXES';
      case EquipmentType.launch:
        return 'LAUNCHES';
      case EquipmentType.erg:
        return 'ERGS';
    }
  }
}
