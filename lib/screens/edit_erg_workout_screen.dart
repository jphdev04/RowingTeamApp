import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../services/workout_service.dart';
import '../services/calendar_service.dart';
import '../widgets/team_header.dart';

/// Edit screen for erg workouts. Mirrors CreateErgWorkoutScreen but
/// pre-fills all fields from an existing template + session.
///
/// When other workout types are built (lift, water, circuit, race),
/// create corresponding EditLiftWorkoutScreen, etc. following this pattern.
class EditErgWorkoutScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final WorkoutTemplate existingTemplate;
  final WorkoutSession existingSession;

  const EditErgWorkoutScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    required this.existingTemplate,
    required this.existingSession,
  });

  @override
  State<EditErgWorkoutScreen> createState() => _EditErgWorkoutScreenState();
}

class _EditErgWorkoutScreenState extends State<EditErgWorkoutScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final CalendarService _calendarService = CalendarService();

  // ── Form state (mirrors CreateErgWorkoutScreen) ──
  late ErgType _ergType;
  late ErgFormat _ergFormat;
  late bool _isBenchmark;
  late bool _hideUntilStart;
  late bool _athletesCanSeeResults;
  bool _isSaving = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  // Single piece
  late TextEditingController _singleDistanceController;
  late TextEditingController _singleTimeMinController;
  late TextEditingController _singleTimeSecController;

  // Standard intervals
  late TextEditingController _intervalCountController;
  late TextEditingController _intervalDistanceController;
  late TextEditingController _intervalTimeMinController;
  late TextEditingController _intervalTimeSecController;
  late TextEditingController _restMinController;
  late TextEditingController _restSecController;

  // Variable intervals
  List<_VariableIntervalEntry> _variableIntervals = [];

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  void initState() {
    super.initState();
    _initFromExisting();
  }

  void _initFromExisting() {
    final t = widget.existingTemplate;
    final s = widget.existingSession;

    _ergType = t.ergType ?? ErgType.single;
    _ergFormat = t.ergFormat ?? ErgFormat.distance;
    _isBenchmark = t.isBenchmark;
    _hideUntilStart = s.hideUntilStart;
    _athletesCanSeeResults = s.athletesCanSeeResults;

    _nameController = TextEditingController(text: t.name);
    _descriptionController = TextEditingController(text: t.description ?? '');

    // Single piece
    _singleDistanceController = TextEditingController(
      text: t.targetDistance?.toString() ?? '',
    );
    if (t.targetTime != null) {
      _singleTimeMinController = TextEditingController(
        text: (t.targetTime! ~/ 60).toString(),
      );
      _singleTimeSecController = TextEditingController(
        text: (t.targetTime! % 60).toString().padLeft(2, '0'),
      );
    } else {
      _singleTimeMinController = TextEditingController();
      _singleTimeSecController = TextEditingController();
    }

    // Standard intervals
    _intervalCountController = TextEditingController(
      text: t.intervalCount?.toString() ?? '',
    );
    _intervalDistanceController = TextEditingController(
      text: t.intervalDistance?.toString() ?? '',
    );
    if (t.intervalTime != null) {
      _intervalTimeMinController = TextEditingController(
        text: (t.intervalTime! ~/ 60).toString(),
      );
      _intervalTimeSecController = TextEditingController(
        text: (t.intervalTime! % 60).toString().padLeft(2, '0'),
      );
    } else {
      _intervalTimeMinController = TextEditingController();
      _intervalTimeSecController = TextEditingController();
    }
    if (t.restSeconds != null) {
      _restMinController = TextEditingController(
        text: (t.restSeconds! ~/ 60).toString(),
      );
      _restSecController = TextEditingController(
        text: (t.restSeconds! % 60).toString().padLeft(2, '0'),
      );
    } else {
      _restMinController = TextEditingController();
      _restSecController = TextEditingController();
    }

    // Variable intervals
    if (t.variableIntervals != null) {
      _variableIntervals = t.variableIntervals!.map((vi) {
        final entry = _VariableIntervalEntry();
        if (vi.distance != null) {
          entry.valueController.text = vi.distance.toString();
        } else if (vi.time != null) {
          entry.valueController.text = vi.time.toString();
        }
        if (vi.restSeconds > 0) {
          entry.restMinController.text = (vi.restSeconds ~/ 60).toString();
          entry.restSecController.text = (vi.restSeconds % 60)
              .toString()
              .padLeft(2, '0');
        }
        return entry;
      }).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _singleDistanceController.dispose();
    _singleTimeMinController.dispose();
    _singleTimeSecController.dispose();
    _intervalCountController.dispose();
    _intervalDistanceController.dispose();
    _intervalTimeMinController.dispose();
    _intervalTimeSecController.dispose();
    _restMinController.dispose();
    _restSecController.dispose();
    for (final entry in _variableIntervals) {
      entry.dispose();
    }
    super.dispose();
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
            title: 'Edit Erg Workout',
            subtitle: widget.existingTemplate.name,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Workout Name ──
                _buildSectionLabel('Workout Name'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: 'e.g., 6x1000m',
                ),
                const SizedBox(height: 20),

                // ── Erg Type ──
                _buildSectionLabel('Erg Type'),
                const SizedBox(height: 8),
                _buildErgTypeChips(),
                const SizedBox(height: 20),

                // ── Format Toggle ──
                _buildSectionLabel('Format'),
                const SizedBox(height: 8),
                _buildFormatToggle(),
                const SizedBox(height: 20),

                // ── Dynamic Fields ──
                _buildDynamicFields(),
                const SizedBox(height: 20),

                // ── Description ──
                _buildSectionLabel('Notes (optional)'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _descriptionController,
                  hint: 'Any notes for athletes...',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // ── Options ──
                _buildOptionsCard(),
                const SizedBox(height: 32),

                // ── Save Button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: _onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _onPrimary,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Delete Button ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Remove Workout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FORM WIDGETS (mirror CreateErgWorkoutScreen)
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildErgTypeChips() {
    return Row(
      children: ErgType.values.map((type) {
        final isSelected = _ergType == type;
        String label;
        switch (type) {
          case ErgType.single:
            label = 'Single';
            break;
          case ErgType.standardIntervals:
            label = 'Intervals';
            break;
          case ErgType.variableIntervals:
            label = 'Variable';
            break;
        }
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type != ErgType.variableIntervals ? 8 : 0,
            ),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _ergType = type),
              selectedColor: primaryColor.withOpacity(0.15),
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
              showCheckmark: false,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatToggle() {
    return Row(
      children: [
        _buildFormatButton(ErgFormat.distance, Icons.straighten, 'Distance'),
        const SizedBox(width: 10),
        _buildFormatButton(ErgFormat.time, Icons.timer_outlined, 'Time'),
      ],
    );
  }

  Widget _buildFormatButton(ErgFormat format, IconData icon, String label) {
    final isSelected = _ergFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _ergFormat = format),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? primaryColor : Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? primaryColor : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFields() {
    switch (_ergType) {
      case ErgType.single:
        return _buildSingleFields();
      case ErgType.standardIntervals:
        return _buildStandardIntervalFields();
      case ErgType.variableIntervals:
        return _buildVariableIntervalFields();
    }
  }

  Widget _buildSingleFields() {
    if (_ergFormat == ErgFormat.distance) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Distance'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _singleDistanceController,
            hint: 'e.g., 2000',
            keyboardType: TextInputType.number,
            suffix: 'm',
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Time'),
          const SizedBox(height: 8),
          _buildTimeRow(_singleTimeMinController, _singleTimeSecController),
        ],
      );
    }
  }

  Widget _buildStandardIntervalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Number of Intervals'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _intervalCountController,
          hint: 'e.g., 6',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildSectionLabel(
          _ergFormat == ErgFormat.distance
              ? 'Distance per Interval'
              : 'Time per Interval',
        ),
        const SizedBox(height: 8),
        if (_ergFormat == ErgFormat.distance)
          _buildTextField(
            controller: _intervalDistanceController,
            hint: 'e.g., 1000',
            keyboardType: TextInputType.number,
            suffix: 'm',
          )
        else
          _buildTimeRow(_intervalTimeMinController, _intervalTimeSecController),
        const SizedBox(height: 16),
        _buildSectionLabel('Rest Between'),
        const SizedBox(height: 8),
        _buildTimeRow(_restMinController, _restSecController),
      ],
    );
  }

  Widget _buildVariableIntervalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Intervals'),
            TextButton.icon(
              onPressed: _addVariableInterval,
              icon: Icon(Icons.add, size: 18, color: primaryColor),
              label: Text('Add', style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_variableIntervals.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              'Tap "Add" to create intervals',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          )
        else
          ..._variableIntervals.asMap().entries.map((entry) {
            final i = entry.key;
            final vi = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Interval ${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            setState(() => _variableIntervals.removeAt(i)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: vi.valueController,
                    hint: _ergFormat == ErgFormat.distance
                        ? 'Distance (m)'
                        : 'Time (sec)',
                    keyboardType: TextInputType.number,
                    suffix: _ergFormat == ErgFormat.distance ? 'm' : 's',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rest after',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  _buildTimeRow(vi.restMinController, vi.restSecController),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTimeRow(
    TextEditingController minCtrl,
    TextEditingController secCtrl,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: minCtrl,
            hint: 'min',
            keyboardType: TextInputType.number,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: TextStyle(fontSize: 20, color: Colors.grey[400]),
          ),
        ),
        Expanded(
          child: _buildTextField(
            controller: secCtrl,
            hint: 'sec',
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  void _addVariableInterval() {
    setState(() => _variableIntervals.add(_VariableIntervalEntry()));
  }

  Widget _buildOptionsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text(
                'Benchmark Test',
                style: TextStyle(fontSize: 15),
              ),
              subtitle: Text(
                'Track as official test piece',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              value: _isBenchmark,
              onChanged: (v) => setState(() => _isBenchmark = v),
              activeColor: primaryColor,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              title: const Text(
                'Hide Until Practice',
                style: TextStyle(fontSize: 15),
              ),
              subtitle: Text(
                'Athletes can\'t see until start time',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              value: _hideUntilStart,
              onChanged: (v) => setState(() => _hideUntilStart = v),
              activeColor: primaryColor,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              title: const Text(
                'Athletes See Results',
                style: TextStyle(fontSize: 15),
              ),
              subtitle: Text(
                'Athletes can view each other\'s results',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              value: _athletesCanSeeResults,
              onChanged: (v) => setState(() => _athletesCanSeeResults = v),
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SAVE / DELETE
  // ═══════════════════════════════════════════════════════════

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a workout name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_validateFields()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final updatedTemplate = _buildUpdatedTemplate(now);
      final updatedSession = _buildUpdatedSession();

      // Update template
      await _workoutService.updateTemplate(updatedTemplate);

      // Update session
      await _workoutService.updateSession(updatedSession);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Workout'),
        content: const Text(
          'This will remove the workout from this practice. '
          'The template will still be available for future use.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        // Unlink from calendar event
        if (widget.existingSession.calendarEventId != null) {
          await _calendarService.unlinkWorkoutFromEvent(
            widget.existingSession.calendarEventId!,
            widget.existingSession.id,
          );
        }

        // Delete the session (keep template for reuse)
        await _workoutService.deleteSession(
          widget.organization.id,
          widget.existingSession.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout removed'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  bool _validateFields() {
    String? error;
    switch (_ergType) {
      case ErgType.single:
        if (_ergFormat == ErgFormat.distance &&
            _singleDistanceController.text.isEmpty) {
          error = 'Enter a distance';
        } else if (_ergFormat == ErgFormat.time &&
            _singleTimeMinController.text.isEmpty &&
            _singleTimeSecController.text.isEmpty) {
          error = 'Enter a time';
        }
        break;
      case ErgType.standardIntervals:
        if (_intervalCountController.text.isEmpty) {
          error = 'Enter number of intervals';
        } else if (_ergFormat == ErgFormat.distance &&
            _intervalDistanceController.text.isEmpty) {
          error = 'Enter distance per interval';
        } else if (_ergFormat == ErgFormat.time &&
            _intervalTimeMinController.text.isEmpty &&
            _intervalTimeSecController.text.isEmpty) {
          error = 'Enter time per interval';
        }
        break;
      case ErgType.variableIntervals:
        if (_variableIntervals.isEmpty) {
          error = 'Add at least one interval';
        } else {
          for (int i = 0; i < _variableIntervals.length; i++) {
            if (_variableIntervals[i].valueController.text.isEmpty) {
              error = 'Enter value for interval ${i + 1}';
              break;
            }
          }
        }
        break;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange),
      );
      return false;
    }
    return true;
  }

  WorkoutTemplate _buildUpdatedTemplate(DateTime now) {
    int? targetDistance;
    int? targetTime;
    int? intervalCount;
    int? intervalDistance;
    int? intervalTime;
    int? restSeconds;
    List<VariableInterval>? variableIntervals;

    switch (_ergType) {
      case ErgType.single:
        if (_ergFormat == ErgFormat.distance) {
          targetDistance = int.tryParse(_singleDistanceController.text);
        } else {
          final min = int.tryParse(_singleTimeMinController.text) ?? 0;
          final sec = int.tryParse(_singleTimeSecController.text) ?? 0;
          targetTime = min * 60 + sec;
        }
        break;
      case ErgType.standardIntervals:
        intervalCount = int.tryParse(_intervalCountController.text);
        if (_ergFormat == ErgFormat.distance) {
          intervalDistance = int.tryParse(_intervalDistanceController.text);
        } else {
          final min = int.tryParse(_intervalTimeMinController.text) ?? 0;
          final sec = int.tryParse(_intervalTimeSecController.text) ?? 0;
          intervalTime = min * 60 + sec;
        }
        final rMin = int.tryParse(_restMinController.text) ?? 0;
        final rSec = int.tryParse(_restSecController.text) ?? 0;
        restSeconds = rMin * 60 + rSec;
        break;
      case ErgType.variableIntervals:
        variableIntervals = _variableIntervals.map((entry) {
          final val = int.tryParse(entry.valueController.text) ?? 0;
          final rMin = int.tryParse(entry.restMinController.text) ?? 0;
          final rSec = int.tryParse(entry.restSecController.text) ?? 0;
          return VariableInterval(
            distance: _ergFormat == ErgFormat.distance ? val : null,
            time: _ergFormat == ErgFormat.time ? val : null,
            restSeconds: rMin * 60 + rSec,
          );
        }).toList();
        break;
    }

    return widget.existingTemplate.copyWith(
      updatedAt: now,
      name: _nameController.text.trim(),
      isBenchmark: _isBenchmark,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      ergType: _ergType,
      ergFormat: _ergFormat,
      targetDistance: targetDistance,
      targetTime: targetTime,
      intervalCount: intervalCount,
      intervalDistance: intervalDistance,
      intervalTime: intervalTime,
      restSeconds: restSeconds,
      variableIntervals: variableIntervals,
    );
  }

  WorkoutSession _buildUpdatedSession() {
    return widget.existingSession.copyWith(
      name: _nameController.text.trim(),
      hideUntilStart: _hideUntilStart,
      athletesCanSeeResults: _athletesCanSeeResults,
    );
  }
}

/// Helper for variable interval form entries
class _VariableIntervalEntry {
  final TextEditingController valueController = TextEditingController();
  final TextEditingController restMinController = TextEditingController();
  final TextEditingController restSecController = TextEditingController();

  void dispose() {
    valueController.dispose();
    restMinController.dispose();
    restSecController.dispose();
  }
}
