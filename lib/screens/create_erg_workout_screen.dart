import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../models/calendar_event.dart';
import '../services/workout_service.dart';
import '../services/calendar_service.dart';
import '../widgets/team_header.dart';

class CreateErgWorkoutScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final WorkoutTemplate? existingTemplate; // for editing

  const CreateErgWorkoutScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    this.existingTemplate,
  });

  @override
  State<CreateErgWorkoutScreen> createState() => _CreateErgWorkoutScreenState();
}

class _CreateErgWorkoutScreenState extends State<CreateErgWorkoutScreen> {
  final _workoutService = WorkoutService();
  final _calendarService = CalendarService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Erg config
  ErgType _ergType = ErgType.single;
  ErgFormat _ergFormat = ErgFormat.distance;

  // Single piece
  final _singleDistanceController = TextEditingController();
  final _singleTimeMinController = TextEditingController();
  final _singleTimeSecController = TextEditingController();

  // Standard intervals
  final _intervalCountController = TextEditingController();
  final _intervalDistanceController = TextEditingController();
  final _intervalTimeMinController = TextEditingController();
  final _intervalTimeSecController = TextEditingController();
  final _restMinController = TextEditingController();
  final _restSecController = TextEditingController();

  // Variable intervals
  List<_VariableIntervalEntry> _variableIntervals = [_VariableIntervalEntry()];

  // Practice linking
  // 'linkToPractice' or 'onYourOwn'
  String _scheduleMode = 'linkToPractice';
  List<CalendarEvent> _upcomingPractices = [];
  CalendarEvent? _selectedPractice;
  bool _loadingPractices = true;

  // Session scheduling (for on-your-own mode)
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();

  // Options
  bool _isBenchmark = false;
  bool _hideUntilStart = false;
  bool _athletesCanSeeResults = true;

  bool _isSaving = false;
  bool _nameManuallyEdited = false;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    if (widget.existingTemplate != null) {
      _loadFromTemplate(widget.existingTemplate!);
    }
    _nameController.addListener(() {
      if (_nameController.text.isNotEmpty) {
        _nameManuallyEdited = true;
      }
    });
    _loadUpcomingPractices();
  }

  Future<void> _loadUpcomingPractices() async {
    if (widget.team == null) {
      setState(() => _loadingPractices = false);
      return;
    }
    try {
      final practices = await _calendarService.getUpcomingPractices(
        widget.team!.id,
      );
      if (mounted) {
        setState(() {
          _upcomingPractices = practices;
          _loadingPractices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPractices = false);
      }
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

  void _loadFromTemplate(WorkoutTemplate t) {
    _nameController.text = t.name;
    _nameManuallyEdited = true;
    _descriptionController.text = t.description ?? '';
    _ergType = t.ergType ?? ErgType.single;
    _ergFormat = t.ergFormat ?? ErgFormat.distance;
    _isBenchmark = t.isBenchmark;

    if (_ergType == ErgType.single) {
      if (_ergFormat == ErgFormat.distance && t.targetDistance != null) {
        _singleDistanceController.text = t.targetDistance.toString();
      } else if (_ergFormat == ErgFormat.time && t.targetTime != null) {
        _singleTimeMinController.text = (t.targetTime! ~/ 60).toString();
        _singleTimeSecController.text = (t.targetTime! % 60).toString();
      }
    } else if (_ergType == ErgType.standardIntervals) {
      _intervalCountController.text = (t.intervalCount ?? '').toString();
      if (_ergFormat == ErgFormat.distance && t.intervalDistance != null) {
        _intervalDistanceController.text = t.intervalDistance.toString();
      } else if (_ergFormat == ErgFormat.time && t.intervalTime != null) {
        _intervalTimeMinController.text = (t.intervalTime! ~/ 60).toString();
        _intervalTimeSecController.text = (t.intervalTime! % 60).toString();
      }
      if (t.restSeconds != null) {
        _restMinController.text = (t.restSeconds! ~/ 60).toString();
        _restSecController.text = (t.restSeconds! % 60).toString();
      }
    } else if (_ergType == ErgType.variableIntervals &&
        t.variableIntervals != null) {
      _variableIntervals = t.variableIntervals!.map((v) {
        final entry = _VariableIntervalEntry();
        if (_ergFormat == ErgFormat.distance && v.distance != null) {
          entry.valueController.text = v.distance.toString();
        } else if (_ergFormat == ErgFormat.time && v.time != null) {
          entry.valueController.text = v.time.toString();
        }
        entry.restMinController.text = (v.restSeconds ~/ 60).toString();
        entry.restSecController.text = (v.restSeconds % 60).toString();
        return entry;
      }).toList();
    }
  }

  /// Auto-generate workout name from spec
  String _generateName() {
    switch (_ergType) {
      case ErgType.single:
        if (_ergFormat == ErgFormat.distance) {
          final d = _singleDistanceController.text;
          if (d.isNotEmpty) return '${d}m Piece';
        } else {
          final m = _singleTimeMinController.text;
          final s = _singleTimeSecController.text;
          if (m.isNotEmpty) {
            return s.isNotEmpty && s != '0'
                ? '${m}min ${s}sec Piece'
                : '${m}min Piece';
          }
        }
        return 'Erg Piece';

      case ErgType.standardIntervals:
        final count = _intervalCountController.text;
        if (_ergFormat == ErgFormat.distance) {
          final d = _intervalDistanceController.text;
          if (count.isNotEmpty && d.isNotEmpty) return '${count}x${d}m';
        } else {
          final m = _intervalTimeMinController.text;
          if (count.isNotEmpty && m.isNotEmpty) return '${count}x${m}min';
        }
        return 'Erg Intervals';

      case ErgType.variableIntervals:
        final pieces = _variableIntervals
            .where((v) => v.valueController.text.isNotEmpty)
            .map((v) {
              final val = v.valueController.text;
              return _ergFormat == ErgFormat.distance ? '${val}m' : '${val}s';
            })
            .toList();
        if (pieces.isNotEmpty) return pieces.join('/');
        return 'Variable Intervals';
    }
  }

  void _updateAutoName() {
    if (!_nameManuallyEdited || _nameController.text.isEmpty) {
      final newName = _generateName();
      _nameController.text = newName;
      _nameManuallyEdited = false;
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
            title: 'Erg Workout',
            subtitle: widget.team?.name ?? widget.organization.name,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: primaryColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Erg type selector ──
                  _buildSectionLabel('Erg Type'),
                  const SizedBox(height: 8),
                  _buildErgTypeSelector(),
                  const SizedBox(height: 24),

                  // ── Format selector (time vs distance) ──
                  _buildSectionLabel('Format'),
                  const SizedBox(height: 8),
                  _buildFormatSelector(),
                  const SizedBox(height: 24),

                  // ── Type-specific fields ──
                  ..._buildTypeSpecificFields(),
                  const SizedBox(height: 24),

                  // ── Workout name ──
                  _buildSectionLabel('Workout Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Auto-generated from spec',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Re-generate name',
                        onPressed: () {
                          _nameManuallyEdited = false;
                          _updateAutoName();
                        },
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Name required' : null,
                    onChanged: (v) {
                      if (v.isNotEmpty) _nameManuallyEdited = true;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Description ──
                  _buildSectionLabel('Description (optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Coach notes about this workout...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Schedule / Practice Link ──
                  _buildSectionLabel('Schedule'),
                  const SizedBox(height: 8),
                  _buildScheduleModeSelector(),
                  const SizedBox(height: 12),
                  if (_scheduleMode == 'linkToPractice')
                    _buildPracticePicker()
                  else
                    _buildDateTimePicker(),
                  const SizedBox(height: 24),

                  // ── Options ──
                  _buildSectionLabel('Options'),
                  const SizedBox(height: 8),
                  _buildOptionsCard(),
                  const SizedBox(height: 32),

                  // ── Save button ──
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: primaryColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Workout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Erg type selector (3 chips) ──────────────────────────────

  Widget _buildErgTypeSelector() {
    return Row(
      children: [
        _buildChip('Single', ErgType.single),
        const SizedBox(width: 8),
        _buildChip('Intervals', ErgType.standardIntervals),
        const SizedBox(width: 8),
        _buildChip('Variable', ErgType.variableIntervals),
      ],
    );
  }

  Widget _buildChip(String label, ErgType type) {
    final selected = _ergType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _ergType = type);
          _updateAutoName();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? (primaryColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)
                    : Colors.grey[700],
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Format selector (time / distance toggle) ─────────────────

  Widget _buildFormatSelector() {
    return Row(
      children: [
        _buildFormatChip('Distance', ErgFormat.distance, Icons.straighten),
        const SizedBox(width: 12),
        _buildFormatChip('Time', ErgFormat.time, Icons.timer),
      ],
    );
  }

  Widget _buildFormatChip(String label, ErgFormat format, IconData icon) {
    final selected = _ergFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _ergFormat = format);
          _updateAutoName();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primaryColor : Colors.grey[300]!,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? primaryColor : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? primaryColor : Colors.grey[700],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Type-specific form fields ────────────────────────────────

  List<Widget> _buildTypeSpecificFields() {
    switch (_ergType) {
      case ErgType.single:
        return _buildSingleFields();
      case ErgType.standardIntervals:
        return _buildStandardIntervalFields();
      case ErgType.variableIntervals:
        return _buildVariableIntervalFields();
    }
  }

  List<Widget> _buildSingleFields() {
    if (_ergFormat == ErgFormat.distance) {
      return [
        _buildSectionLabel('Distance (meters)'),
        const SizedBox(height: 8),
        _buildNumberField(
          controller: _singleDistanceController,
          hint: 'e.g. 6000',
          suffix: 'm',
          onChanged: (_) => _updateAutoName(),
        ),
      ];
    } else {
      return [
        _buildSectionLabel('Time'),
        const SizedBox(height: 8),
        _buildTimeInput(
          minController: _singleTimeMinController,
          secController: _singleTimeSecController,
          onChanged: () => _updateAutoName(),
        ),
      ];
    }
  }

  List<Widget> _buildStandardIntervalFields() {
    return [
      // Number of intervals
      _buildSectionLabel('Number of Intervals'),
      const SizedBox(height: 8),
      _buildNumberField(
        controller: _intervalCountController,
        hint: 'e.g. 6',
        onChanged: (_) => _updateAutoName(),
      ),
      const SizedBox(height: 16),

      // Interval distance or time
      _buildSectionLabel(
        _ergFormat == ErgFormat.distance
            ? 'Distance per Interval (meters)'
            : 'Time per Interval',
      ),
      const SizedBox(height: 8),
      if (_ergFormat == ErgFormat.distance)
        _buildNumberField(
          controller: _intervalDistanceController,
          hint: 'e.g. 1000',
          suffix: 'm',
          onChanged: (_) => _updateAutoName(),
        )
      else
        _buildTimeInput(
          minController: _intervalTimeMinController,
          secController: _intervalTimeSecController,
          onChanged: () => _updateAutoName(),
        ),
      const SizedBox(height: 16),

      // Rest
      _buildSectionLabel('Rest Between Intervals'),
      const SizedBox(height: 8),
      _buildTimeInput(
        minController: _restMinController,
        secController: _restSecController,
        minLabel: 'min',
        secLabel: 'sec',
      ),
    ];
  }

  List<Widget> _buildVariableIntervalFields() {
    return [
      _buildSectionLabel('Intervals'),
      const SizedBox(height: 8),
      ...List.generate(_variableIntervals.length, (index) {
        final entry = _variableIntervals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Interval ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_variableIntervals.length > 1)
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red[400],
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _variableIntervals[index].dispose();
                              _variableIntervals.removeAt(index);
                            });
                            _updateAutoName();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Value (distance or time in seconds)
                  _buildNumberField(
                    controller: entry.valueController,
                    hint: _ergFormat == ErgFormat.distance
                        ? 'Distance (m)'
                        : 'Time (seconds)',
                    suffix: _ergFormat == ErgFormat.distance ? 'm' : 's',
                    onChanged: (_) => _updateAutoName(),
                  ),
                  const SizedBox(height: 12),
                  // Rest
                  Row(
                    children: [
                      Text(
                        'Rest:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniTimeInput(
                          minController: entry.restMinController,
                          secController: entry.restSecController,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _variableIntervals.add(_VariableIntervalEntry());
            });
          },
          icon: Icon(Icons.add_circle_outline, color: primaryColor),
          label: Text('Add Interval', style: TextStyle(color: primaryColor)),
        ),
      ),
    ];
  }

  // ── Schedule picker ──────────────────────────────────────────

  Widget _buildDateTimePicker() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _scheduledDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _scheduledDate = picked);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_scheduledDate),
                    style: const TextStyle(fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
            const Divider(height: 24),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _scheduledTime,
                );
                if (picked != null) {
                  setState(() => _scheduledTime = picked);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.access_time, color: primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _scheduledTime.format(context),
                    style: const TextStyle(fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Options card ─────────────────────────────────────────────

  Widget _buildOptionsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Benchmark Test'),
            subtitle: const Text('Track results over time'),
            value: _isBenchmark,
            activeColor: primaryColor,
            onChanged: (v) => setState(() => _isBenchmark = v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Hide Until Practice'),
            subtitle: const Text('Athletes can\'t see workout beforehand'),
            value: _hideUntilStart,
            activeColor: primaryColor,
            onChanged: (v) => setState(() => _hideUntilStart = v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Athletes See Results'),
            subtitle: const Text('Athletes can view each other\'s results'),
            value: _athletesCanSeeResults,
            activeColor: primaryColor,
            onChanged: (v) => setState(() => _athletesCanSeeResults = v),
          ),
        ],
      ),
    );
  }

  // ── Shared input builders ────────────────────────────────────

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

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    String? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildTimeInput({
    required TextEditingController minController,
    required TextEditingController secController,
    String minLabel = 'min',
    String secLabel = 'sec',
    VoidCallback? onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: minController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: minLabel,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: secController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '00',
              suffixText: secLabel,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTimeInput({
    required TextEditingController minController,
    required TextEditingController secController,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: TextFormField(
            controller: minController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'm',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(':'),
        const SizedBox(width: 4),
        SizedBox(
          width: 60,
          child: TextFormField(
            controller: secController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '00',
              suffixText: 's',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Schedule mode selector ────────────────────────────────

  Widget _buildScheduleModeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _scheduleMode = 'linkToPractice'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _scheduleMode == 'linkToPractice'
                    ? primaryColor.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _scheduleMode == 'linkToPractice'
                      ? primaryColor
                      : Colors.grey[300]!,
                  width: _scheduleMode == 'linkToPractice' ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event,
                    size: 20,
                    color: _scheduleMode == 'linkToPractice'
                        ? primaryColor
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Link to Practice',
                    style: TextStyle(
                      color: _scheduleMode == 'linkToPractice'
                          ? primaryColor
                          : Colors.grey[700],
                      fontWeight: _scheduleMode == 'linkToPractice'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _scheduleMode = 'onYourOwn';
              _selectedPractice = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _scheduleMode == 'onYourOwn'
                    ? primaryColor.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _scheduleMode == 'onYourOwn'
                      ? primaryColor
                      : Colors.grey[300]!,
                  width: _scheduleMode == 'onYourOwn' ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 20,
                    color: _scheduleMode == 'onYourOwn'
                        ? primaryColor
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'On Your Own',
                    style: TextStyle(
                      color: _scheduleMode == 'onYourOwn'
                          ? primaryColor
                          : Colors.grey[700],
                      fontWeight: _scheduleMode == 'onYourOwn'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticePicker() {
    if (_loadingPractices) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_upcomingPractices.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.event_busy, color: Colors.grey[400], size: 36),
              const SizedBox(height: 12),
              Text(
                'No upcoming practices found',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a practice event on the calendar first, or use "On Your Own" mode.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ..._upcomingPractices.map((practice) {
            final isSelected = _selectedPractice?.id == practice.id;
            final workoutCount = practice.linkedWorkoutSessionIds.length;
            return InkWell(
              onTap: () => setState(() => _selectedPractice = practice),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.08)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isSelected ? primaryColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected ? primaryColor : Colors.grey[400],
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              practice.title,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('EEE, MMM d').format(practice.startTime)} · ${DateFormat('h:mm a').format(practice.startTime)} – ${DateFormat('h:mm a').format(practice.endTime)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (workoutCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$workoutCount workout${workoutCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Save logic ───────────────────────────────────────────────

  Future<void> _save() async {
    // Auto-name if empty
    if (_nameController.text.isEmpty) {
      _nameController.text = _generateName();
    }

    if (!_formKey.currentState!.validate()) return;

    // Validate erg-specific fields
    if (!_validateErgFields()) return;

    // Validate practice selection
    if (_scheduleMode == 'linkToPractice' && _selectedPractice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a practice to link this workout to'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();

      // Determine scheduled date from practice or manual input
      final DateTime scheduledDateTime;
      final String? calendarEventId;

      if (_scheduleMode == 'linkToPractice' && _selectedPractice != null) {
        scheduledDateTime = _selectedPractice!.startTime;
        calendarEventId = _selectedPractice!.id;
      } else {
        scheduledDateTime = DateTime(
          _scheduledDate.year,
          _scheduledDate.month,
          _scheduledDate.day,
          _scheduledTime.hour,
          _scheduledTime.minute,
        );
        calendarEventId = null;
      }

      // Build template
      final template = _buildTemplate(now);

      // Save template
      final savedTemplate = await _workoutService.createTemplate(template);

      // Create session from template
      final savedSession = await _workoutService.createSessionFromTemplate(
        template: savedTemplate,
        scheduledDate: scheduledDateTime,
        createdBy: widget.user.id,
        teamId: widget.team?.id,
        calendarEventId: calendarEventId,
        hideUntilStart: _hideUntilStart,
        athletesCanSeeResults: _athletesCanSeeResults,
      );

      // Link workout session to practice event
      if (calendarEventId != null) {
        await _calendarService.linkWorkoutToEvent(
          calendarEventId,
          savedSession.id,
        );
      }

      if (mounted) {
        final message = _scheduleMode == 'linkToPractice'
            ? 'Workout created and linked to practice!'
            : 'On-your-own workout created!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // pop erg screen
        Navigator.of(context).pop(); // pop create workout screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validateErgFields() {
    String? error;

    switch (_ergType) {
      case ErgType.single:
        if (_ergFormat == ErgFormat.distance) {
          if (_singleDistanceController.text.isEmpty) {
            error = 'Enter a distance';
          }
        } else {
          if (_singleTimeMinController.text.isEmpty &&
              _singleTimeSecController.text.isEmpty) {
            error = 'Enter a time';
          }
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

  WorkoutTemplate _buildTemplate(DateTime now) {
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
        final restMin = int.tryParse(_restMinController.text) ?? 0;
        final restSec = int.tryParse(_restSecController.text) ?? 0;
        restSeconds = restMin * 60 + restSec;
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

    return WorkoutTemplate(
      id: '', // set by service
      organizationId: widget.organization.id,
      teamId: widget.team?.id,
      createdBy: widget.user.id,
      createdAt: now,
      updatedAt: now,
      name: _nameController.text.trim(),
      category: WorkoutCategory.erg,
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
}

/// Helper class to hold controllers for each variable interval entry
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
