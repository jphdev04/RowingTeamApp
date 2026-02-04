import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import '../models/team.dart';
import '../models/organization.dart';
import '../services/equipment_service.dart';

class ReportDamageScreen extends StatefulWidget {
  final String organizationId;
  final String userId;
  final String userName;
  final Team team;
  final Organization? organization;

  const ReportDamageScreen({
    super.key,
    required this.organizationId,
    required this.userId,
    required this.userName,
    required this.team,
    this.organization,
  });

  @override
  State<ReportDamageScreen> createState() => _ReportDamageScreenState();
}

class _ReportDamageScreenState extends State<ReportDamageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentService = EquipmentService();
  final _descriptionController = TextEditingController();

  Equipment? _selectedEquipment;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

        // Add damage report to equipment
        final updatedReports = List<DamageReport>.from(
          _selectedEquipment!.damageReports,
        )..add(damageReport);

        final updatedEquipment = _selectedEquipment!.copyWith(
          isDamaged: true,
          status: EquipmentStatus.damaged,
          damageReports: updatedReports,
        );

        await _equipmentService.updateEquipment(updatedEquipment);

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
    final primaryColor = widget.team.primaryColorObj;
    final secondaryColor = widget.team.secondaryColorObj;

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
                colors: [primaryColor, secondaryColor],
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
                  'Report Damage',
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
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Report Equipment Damage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help keep everyone safe by reporting damaged equipment',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    // Equipment Selector
                    const Text(
                      'Select Equipment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<List<Equipment>>(
                      stream: _equipmentService.getEquipmentByTeam(
                        widget.organizationId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        var equipment = snapshot.data ?? [];

                        // Filter by team
                        equipment = equipment.where((e) {
                          return e.availableToAllTeams ||
                              e.assignedTeamIds.contains(widget.team.id);
                        }).toList();

                        // Sort by type then name
                        equipment.sort((a, b) {
                          final typeCompare = a.type.name.compareTo(
                            b.type.name,
                          );
                          if (typeCompare != 0) return typeCompare;
                          return a.displayName.compareTo(b.displayName);
                        });

                        if (equipment.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No equipment available',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<Equipment>(
                          value: _selectedEquipment,
                          decoration: const InputDecoration(
                            labelText: 'Equipment *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.rowing),
                          ),
                          items: equipment.map((eq) {
                            return DropdownMenuItem(
                              value: eq,
                              child: Text(
                                '${_getTypeLabel(eq.type)} - ${eq.displayName}',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedEquipment = value);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Describe the Damage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                        hintText:
                            'e.g., Cracked rigger on starboard side, loose bolt on seat',
                        prefixIcon: Icon(Icons.description),
                      ),
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
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit Damage Report',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Info card
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Your report will notify coaches and boatmen immediately. The equipment will be marked as damaged until repaired.',
                                style: TextStyle(fontSize: 12),
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

  String _getTypeLabel(EquipmentType type) {
    switch (type) {
      case EquipmentType.shell:
        return 'Shell';
      case EquipmentType.oar:
        return 'Oar';
      case EquipmentType.coxbox:
        return 'Coxbox';
      case EquipmentType.launch:
        return 'Launch';
      case EquipmentType.erg:
        return 'Erg';
    }
  }
}
