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
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';
import 'manage_lineups_screen.dart';

class CreateWaterWorkoutScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final WorkoutTemplate? fromTemplate;
  final dynamic preLinkedEvent;

  const CreateWaterWorkoutScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    this.fromTemplate,
    this.preLinkedEvent,
  });

  @override
  State<CreateWaterWorkoutScreen> createState() =>
      _CreateWaterWorkoutScreenState();
}

class _CreateWaterWorkoutScreenState extends State<CreateWaterWorkoutScreen> {
  final _workoutService = WorkoutService();
  final _calendarService = CalendarService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  WaterFormat _waterFormat = WaterFormat.structured;
  final _looseDescriptionController = TextEditingController();

  int _pieceType = 0;
  ErgFormat _pieceFormat = ErgFormat.distance;

  final _singleDistanceController = TextEditingController();
  final _singleTimeMinController = TextEditingController();
  final _singleTimeSecController = TextEditingController();

  final _intervalCountController = TextEditingController();
  final _intervalDistanceController = TextEditingController();
  final _intervalTimeMinController = TextEditingController();
  final _intervalTimeSecController = TextEditingController();
  final _restMinController = TextEditingController();
  final _restSecController = TextEditingController();

  List<_WaterVariableEntry> _variableIntervals = [_WaterVariableEntry()];

  String _scheduleMode = 'linkToPractice';
  List<CalendarEvent> _upcomingPractices = [];
  CalendarEvent? _selectedPractice;
  bool _loadingPractices = true;

  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();

  bool _saveAsTemplate = true;
  bool _isBenchmark = false;
  bool _hideUntilStart = false;
  bool _athletesCanSeeResults = true;

  bool _isSaving = false;
  bool _nameManuallyEdited = false;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  void initState() {
    super.initState();
    if (widget.fromTemplate != null) _loadFromTemplate(widget.fromTemplate!);
    if (widget.preLinkedEvent != null) {
      _scheduleMode = 'linkToPractice';
      _selectedPractice = widget.preLinkedEvent as CalendarEvent?;
    }
    _loadUpcomingPractices();
    _updateAutoName();
  }

  void _loadFromTemplate(WorkoutTemplate t) {
    _nameController.text = t.name;
    _nameManuallyEdited = true;
    _descriptionController.text = t.description ?? '';
    _isBenchmark = t.isBenchmark;
    _waterFormat = t.waterFormat ?? WaterFormat.structured;
    _looseDescriptionController.text = t.waterDescription ?? '';

    if (_waterFormat == WaterFormat.structured && t.waterPieces != null) {
      final pieces = t.waterPieces!;
      if (pieces.length == 1) {
        _pieceType = 0;
        if (pieces.first.distance != null) {
          _pieceFormat = ErgFormat.distance;
          _singleDistanceController.text = pieces.first.distance.toString();
        } else if (pieces.first.time != null) {
          _pieceFormat = ErgFormat.time;
          _singleTimeMinController.text = (pieces.first.time! ~/ 60).toString();
          final sec = pieces.first.time! % 60;
          if (sec > 0) _singleTimeSecController.text = sec.toString();
        }
      } else {
        final allSame = pieces.every(
          (p) =>
              p.distance == pieces.first.distance &&
              p.time == pieces.first.time,
        );
        if (allSame) {
          _pieceType = 1;
          _intervalCountController.text = pieces.length.toString();
          if (pieces.first.distance != null) {
            _pieceFormat = ErgFormat.distance;
            _intervalDistanceController.text = pieces.first.distance.toString();
          } else if (pieces.first.time != null) {
            _pieceFormat = ErgFormat.time;
            _intervalTimeMinController.text = (pieces.first.time! ~/ 60)
                .toString();
            final sec = pieces.first.time! % 60;
            if (sec > 0) _intervalTimeSecController.text = sec.toString();
          }
          if (pieces.first.restSeconds != null) {
            _restMinController.text = (pieces.first.restSeconds! ~/ 60)
                .toString();
            final rSec = pieces.first.restSeconds! % 60;
            if (rSec > 0) _restSecController.text = rSec.toString();
          }
        } else {
          _pieceType = 2;
          _variableIntervals = pieces.map((wp) {
            final e = _WaterVariableEntry();
            if (wp.distance != null) {
              _pieceFormat = ErgFormat.distance;
              e.valueController.text = wp.distance.toString();
            } else if (wp.time != null) {
              _pieceFormat = ErgFormat.time;
              e.valueController.text = wp.time.toString();
            }
            if (wp.restSeconds != null) {
              e.restMinController.text = (wp.restSeconds! ~/ 60).toString();
              final rSec = wp.restSeconds! % 60;
              if (rSec > 0) e.restSecController.text = rSec.toString();
            }
            return e;
          }).toList();
        }
      }
    }
  }

  Future<void> _loadUpcomingPractices() async {
    try {
      final now = DateTime.now();
      final events = await _calendarService.getEventsInRange(
        widget.organization.id,
        widget.team?.id,
        now,
        now.add(const Duration(days: 14)),
      );
      if (mounted) {
        setState(() {
          _upcomingPractices =
              events.where((e) => e.type == EventType.practice).toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));
          _loadingPractices = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPractices = false);
    }
  }

  void _updateAutoName() {
    if (_nameManuallyEdited) return;
    String name;
    if (_waterFormat == WaterFormat.loose) {
      name = 'Water Workout';
    } else {
      switch (_pieceType) {
        case 0:
          if (_pieceFormat == ErgFormat.distance) {
            final d = _singleDistanceController.text;
            name = d.isNotEmpty ? '${d}m Water Piece' : 'Water Piece';
          } else {
            final m = _singleTimeMinController.text;
            name = m.isNotEmpty ? '${m}min Water Piece' : 'Water Piece';
          }
          break;
        case 1:
          final c = _intervalCountController.text;
          if (_pieceFormat == ErgFormat.distance) {
            final d = _intervalDistanceController.text;
            name = c.isNotEmpty && d.isNotEmpty
                ? '${c}x${d}m Water'
                : 'Water Intervals';
          } else {
            final m = _intervalTimeMinController.text;
            final s = _intervalTimeSecController.text;
            final t = m.isNotEmpty
                ? (s.isNotEmpty ? '$m:${s.padLeft(2, '0')}' : '${m}min')
                : '';
            name = c.isNotEmpty && t.isNotEmpty
                ? '${c}x$t Water'
                : 'Water Intervals';
          }
          break;
        case 2:
          if (_variableIntervals.isNotEmpty) {
            final p = _variableIntervals
                .map((vi) {
                  final v = vi.valueController.text;
                  if (v.isEmpty) return '?';
                  return _pieceFormat == ErgFormat.distance ? '${v}m' : '${v}s';
                })
                .join('/');
            name = p;
          } else {
            name = 'Variable Water Pieces';
          }
          break;
        default:
          name = 'Water Workout';
      }
    }
    _nameController.text = name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _looseDescriptionController.dispose();
    _singleDistanceController.dispose();
    _singleTimeMinController.dispose();
    _singleTimeSecController.dispose();
    _intervalCountController.dispose();
    _intervalDistanceController.dispose();
    _intervalTimeMinController.dispose();
    _intervalTimeSecController.dispose();
    _restMinController.dispose();
    _restSecController.dispose();
    for (final vi in _variableIntervals) vi.dispose();
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
            organization: widget.team == null ? widget.organization : null,
            title: 'Water Workout',
            subtitle: widget.team?.name ?? widget.organization.name,
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
                  // ── Format: Structured vs Loose ──
                  BoathouseStyles.sectionLabel('Workout Format'),
                  BoathouseStyles.toggleChipRow(
                    primaryColor: primaryColor,
                    labels: const ['Structured', 'Loose'],
                    icons: const [Icons.grid_on, Icons.notes],
                    selectedIndex: _waterFormat == WaterFormat.structured
                        ? 0
                        : 1,
                    onSelected: (i) {
                      setState(
                        () => _waterFormat = i == 0
                            ? WaterFormat.structured
                            : WaterFormat.loose,
                      );
                      _updateAutoName();
                    },
                    filled: true,
                    spacing: 12,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _waterFormat == WaterFormat.structured
                        ? 'Define pieces like an erg workout. Cox logs per-piece data.'
                        : 'Describe the workout freely. Cox logs total distance/time.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),

                  // ── Structured fields ──
                  if (_waterFormat == WaterFormat.structured) ...[
                    BoathouseStyles.sectionLabel('Piece Type'),
                    BoathouseStyles.toggleChipRow(
                      primaryColor: primaryColor,
                      labels: const ['Single', 'Intervals', 'Variable'],
                      selectedIndex: _pieceType,
                      onSelected: (i) {
                        setState(() => _pieceType = i);
                        _updateAutoName();
                      },
                      filled: true,
                    ),
                    const SizedBox(height: 24),

                    BoathouseStyles.sectionLabel('Format'),
                    BoathouseStyles.toggleChipRow(
                      primaryColor: primaryColor,
                      labels: const ['Distance', 'Time'],
                      icons: const [Icons.straighten, Icons.timer],
                      selectedIndex: _pieceFormat == ErgFormat.distance ? 0 : 1,
                      onSelected: (i) {
                        setState(
                          () => _pieceFormat = i == 0
                              ? ErgFormat.distance
                              : ErgFormat.time,
                        );
                        _updateAutoName();
                      },
                      spacing: 12,
                    ),
                    const SizedBox(height: 24),

                    ..._buildTypeSpecificFields(),
                    const SizedBox(height: 24),
                  ],

                  // ── Loose fields ──
                  if (_waterFormat == WaterFormat.loose) ...[
                    BoathouseStyles.sectionLabel('Workout Description'),
                    BoathouseStyles.textField(
                      primaryColor: primaryColor,
                      controller: _looseDescriptionController,
                      hintText:
                          'e.g., 4x20min pieces at rate 20, 3min rest.\nFocus on consistent pressure and clean catches.',
                      maxLines: 5,
                      validator: (v) {
                        if (_waterFormat == WaterFormat.loose &&
                            (v == null || v.isEmpty)) {
                          return 'Please describe the workout';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Workout Name ──
                  BoathouseStyles.sectionLabel('Workout Name'),
                  BoathouseStyles.textField(
                    primaryColor: primaryColor,
                    controller: _nameController,
                    hintText: 'Auto-generated from spec',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Re-generate name',
                      onPressed: () {
                        _nameManuallyEdited = false;
                        _updateAutoName();
                      },
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Name required' : null,
                    onChanged: (v) {
                      if (v.isNotEmpty) _nameManuallyEdited = true;
                    },
                  ),
                  const SizedBox(height: 16),

                  BoathouseStyles.sectionLabel('Description (optional)'),
                  BoathouseStyles.textField(
                    primaryColor: primaryColor,
                    controller: _descriptionController,
                    hintText: 'Coach notes about this workout...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // ── Schedule ──
                  BoathouseStyles.sectionLabel('Schedule'),
                  _buildScheduleToggle(),
                  const SizedBox(height: 12),
                  if (_scheduleMode == 'linkToPractice')
                    _buildPracticePicker()
                  else
                    _buildDateTimePicker(),
                  const SizedBox(height: 24),

                  // ── Options ──
                  BoathouseStyles.sectionLabel('Options'),
                  BoathouseStyles.switchCard(
                    primaryColor: primaryColor,
                    switches: [
                      SwitchTileData(
                        title: 'Save as Template',
                        subtitle: 'Reuse this workout setup in the future',
                        value: _saveAsTemplate,
                        onChanged: (v) => setState(() => _saveAsTemplate = v),
                      ),
                      SwitchTileData(
                        title: 'Benchmark Test',
                        subtitle: 'Track results over time',
                        value: _isBenchmark,
                        onChanged: (v) => setState(() => _isBenchmark = v),
                      ),
                      SwitchTileData(
                        title: 'Hide Until Practice',
                        subtitle: "Athletes can't see workout beforehand",
                        value: _hideUntilStart,
                        onChanged: (v) => setState(() => _hideUntilStart = v),
                      ),
                      SwitchTileData(
                        title: 'Athletes See Results',
                        subtitle: "Athletes can view each other's results",
                        value: _athletesCanSeeResults,
                        onChanged: (v) =>
                            setState(() => _athletesCanSeeResults = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  BoathouseStyles.primaryButton(
                    primaryColor: primaryColor,
                    label: 'Create Water Workout',
                    onPressed: _isSaving ? null : _saveWorkout,
                    isLoading: _isSaving,
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

  // ════════════════════════════════════════════════════════════
  // TYPE-SPECIFIC FIELDS — mirrors erg screen
  // ════════════════════════════════════════════════════════════

  List<Widget> _buildTypeSpecificFields() {
    switch (_pieceType) {
      case 0:
        return _buildSinglePieceFields();
      case 1:
        return _buildStandardIntervalFields();
      case 2:
        return _buildVariableIntervalFields();
      default:
        return [];
    }
  }

  List<Widget> _buildSinglePieceFields() {
    return [
      if (_pieceFormat == ErgFormat.distance) ...[
        BoathouseStyles.sectionLabel('Distance (meters)'),
        BoathouseStyles.numberField(
          primaryColor: primaryColor,
          controller: _singleDistanceController,
          hintText: 'e.g. 6000',
          suffixText: 'm',
          onChanged: (_) => _updateAutoName(),
        ),
      ] else ...[
        BoathouseStyles.sectionLabel('Time'),
        BoathouseStyles.timeInput(
          primaryColor: primaryColor,
          minController: _singleTimeMinController,
          secController: _singleTimeSecController,
          onChanged: _updateAutoName,
        ),
      ],
    ];
  }

  List<Widget> _buildStandardIntervalFields() {
    return [
      BoathouseStyles.sectionLabel('Number of Intervals'),
      BoathouseStyles.numberField(
        primaryColor: primaryColor,
        controller: _intervalCountController,
        hintText: 'e.g. 4',
        onChanged: (_) => _updateAutoName(),
      ),
      const SizedBox(height: 16),
      BoathouseStyles.sectionLabel(
        _pieceFormat == ErgFormat.distance
            ? 'Distance per Interval (meters)'
            : 'Time per Interval',
      ),
      if (_pieceFormat == ErgFormat.distance)
        BoathouseStyles.numberField(
          primaryColor: primaryColor,
          controller: _intervalDistanceController,
          hintText: 'e.g. 1000',
          suffixText: 'm',
          onChanged: (_) => _updateAutoName(),
        )
      else
        BoathouseStyles.timeInput(
          primaryColor: primaryColor,
          minController: _intervalTimeMinController,
          secController: _intervalTimeSecController,
          onChanged: _updateAutoName,
        ),
      const SizedBox(height: 16),
      BoathouseStyles.sectionLabel('Rest Between Intervals'),
      BoathouseStyles.timeInput(
        primaryColor: primaryColor,
        minController: _restMinController,
        secController: _restSecController,
      ),
    ];
  }

  List<Widget> _buildVariableIntervalFields() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BoathouseStyles.sectionLabel('Intervals', bottomPadding: 0),
          TextButton.icon(
            onPressed: () {
              setState(() => _variableIntervals.add(_WaterVariableEntry()));
              _updateAutoName();
            },
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
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
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
                      'Piece ${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (_variableIntervals.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _variableIntervals[i].dispose();
                            _variableIntervals.removeAt(i);
                          });
                          _updateAutoName();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                BoathouseStyles.numberField(
                  primaryColor: primaryColor,
                  controller: vi.valueController,
                  hintText: _pieceFormat == ErgFormat.distance
                      ? 'Distance (m)'
                      : 'Time (seconds)',
                  suffixText: _pieceFormat == ErgFormat.distance ? 'm' : 's',
                  onChanged: (_) => _updateAutoName(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Rest',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                BoathouseStyles.compactTimeInput(
                  primaryColor: primaryColor,
                  minController: vi.restMinController,
                  secController: vi.restSecController,
                ),
              ],
            ),
          );
        }),
    ];
  }

  // ════════════════════════════════════════════════════════════
  // BOAT CLASSES
  // ════════════════════════════════════════════════════════════

  // ════════════════════════════════════════════════════════════
  // SCHEDULING — same as erg screen
  // ════════════════════════════════════════════════════════════

  Widget _buildScheduleToggle() {
    return BoathouseStyles.toggleChipRow(
      primaryColor: primaryColor,
      labels: const ['Link to Practice', 'On Your Own'],
      icons: const [Icons.event, Icons.person],
      selectedIndex: _scheduleMode == 'linkToPractice' ? 0 : 1,
      onSelected: (i) => setState(() {
        _scheduleMode = i == 0 ? 'linkToPractice' : 'onYourOwn';
        if (i == 1) _selectedPractice = null;
      }),
      spacing: 12,
    );
  }

  Widget _buildDateTimePicker() {
    return BoathouseStyles.card(
      child: Column(
        children: [
          BoathouseStyles.pickerRow(
            primaryColor: primaryColor,
            icon: Icons.calendar_today,
            text: DateFormat('EEEE, MMM d, yyyy').format(_scheduledDate),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _scheduledDate,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _scheduledDate = picked);
            },
          ),
          const Divider(height: 24),
          BoathouseStyles.pickerRow(
            primaryColor: primaryColor,
            icon: Icons.access_time,
            text: _scheduledTime.format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _scheduledTime,
              );
              if (picked != null) setState(() => _scheduledTime = picked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPracticePicker() {
    if (_loadingPractices) {
      return BoathouseStyles.card(
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_upcomingPractices.isEmpty) {
      return BoathouseStyles.card(
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
      );
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: _upcomingPractices.map((practice) {
          final isSelected = _selectedPractice?.id == practice.id;
          final wc = (practice.linkedWorkoutSessionIds ?? []).length;
          return ListTile(
            selected: isSelected,
            selectedTileColor: primaryColor.withOpacity(0.05),
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.event,
              color: isSelected ? primaryColor : Colors.grey[400],
            ),
            title: Text(
              DateFormat('EEE, MMM d – h:mm a').format(practice.startTime),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: wc > 0
                ? Text(
                    '$wc workout${wc > 1 ? 's' : ''} linked',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  )
                : null,
            onTap: () => setState(() => _selectedPractice = practice),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // SAVE
  // ════════════════════════════════════════════════════════════

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateFields()) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      DateTime scheduledDateTime;
      String? calendarEventId;

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

      final template = _buildTemplate(now);

      WorkoutTemplate? savedTemplate;
      if (_saveAsTemplate)
        savedTemplate = await _workoutService.createTemplate(template);

      final workoutSpec = <String, dynamic>{
        'waterFormat': _waterFormat.name,
        if (template.waterDescription != null)
          'waterDescription': template.waterDescription,
        if (template.waterPieceCount != null)
          'waterPieceCount': template.waterPieceCount,
        if (template.waterPieces != null)
          'waterPieces': template.waterPieces!.map((p) => p.toMap()).toList(),
      };

      final session = WorkoutSession(
        id: '',
        organizationId: widget.organization.id,
        teamId: widget.team?.id,
        templateId: savedTemplate?.id,
        calendarEventId: calendarEventId,
        createdBy: widget.user.id,
        createdAt: now,
        name: _nameController.text.trim(),
        category: WorkoutCategory.water,
        scheduledDate: scheduledDateTime,
        workoutSpec: workoutSpec,
        hideUntilStart: _hideUntilStart,
        athletesCanSeeResults: _athletesCanSeeResults,
      );

      final created = await _workoutService.createSession(session);
      if (calendarEventId != null)
        await _calendarService.linkWorkoutToEvent(calendarEventId, created.id);

      if (mounted) {
        // Ask if coach wants to set up lineups now
        final setupLineups = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Workout Created!'),
            content: const Text(
              'Would you like to set up lineups for this workout now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Set Up Lineups'),
              ),
            ],
          ),
        );

        if (mounted) {
          if (setupLineups == true) {
            // Replace this screen with the lineup screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ManageLineupsScreen(
                  user: widget.user,
                  currentMembership: widget.currentMembership,
                  organization: widget.organization,
                  team: widget.team,
                  session: created,
                ),
              ),
            );
          } else {
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validateFields() {
    String? error;
    if (_scheduleMode == 'linkToPractice' && _selectedPractice == null) {
      error = 'Select a practice or switch to "On Your Own"';
    }
    if (_waterFormat == WaterFormat.structured) {
      switch (_pieceType) {
        case 0:
          if (_pieceFormat == ErgFormat.distance &&
              _singleDistanceController.text.isEmpty)
            error = 'Enter a distance';
          if (_pieceFormat == ErgFormat.time &&
              _singleTimeMinController.text.isEmpty &&
              _singleTimeSecController.text.isEmpty)
            error = 'Enter a time';
          break;
        case 1:
          if (_intervalCountController.text.isEmpty)
            error = 'Enter number of intervals';
          else if (_pieceFormat == ErgFormat.distance &&
              _intervalDistanceController.text.isEmpty)
            error = 'Enter distance per interval';
          else if (_pieceFormat == ErgFormat.time &&
              _intervalTimeMinController.text.isEmpty &&
              _intervalTimeSecController.text.isEmpty)
            error = 'Enter time per interval';
          break;
        case 2:
          if (_variableIntervals.isEmpty) {
            error = 'Add at least one interval';
          } else {
            for (int i = 0; i < _variableIntervals.length; i++) {
              if (_variableIntervals[i].valueController.text.isEmpty) {
                error = 'Enter value for piece ${i + 1}';
                break;
              }
            }
          }
          break;
      }
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
    List<WaterPiece>? waterPieces;
    int? waterPieceCount;
    String? waterDescription;

    if (_waterFormat == WaterFormat.loose) {
      waterDescription = _looseDescriptionController.text.trim();
    } else {
      switch (_pieceType) {
        case 0:
          int? dist;
          int? time;
          if (_pieceFormat == ErgFormat.distance) {
            dist = int.tryParse(_singleDistanceController.text);
          } else {
            final m = int.tryParse(_singleTimeMinController.text) ?? 0;
            final s = int.tryParse(_singleTimeSecController.text) ?? 0;
            time = m * 60 + s;
            if (time == 0) time = null;
          }
          waterPieces = [
            WaterPiece(pieceNumber: 1, distance: dist, time: time),
          ];
          waterPieceCount = 1;
          break;
        case 1:
          final count = int.tryParse(_intervalCountController.text) ?? 0;
          int? dist;
          int? time;
          if (_pieceFormat == ErgFormat.distance) {
            dist = int.tryParse(_intervalDistanceController.text);
          } else {
            final m = int.tryParse(_intervalTimeMinController.text) ?? 0;
            final s = int.tryParse(_intervalTimeSecController.text) ?? 0;
            time = m * 60 + s;
            if (time == 0) time = null;
          }
          final rM = int.tryParse(_restMinController.text) ?? 0;
          final rS = int.tryParse(_restSecController.text) ?? 0;
          final rest = rM * 60 + rS;
          waterPieces = List.generate(
            count,
            (i) => WaterPiece(
              pieceNumber: i + 1,
              distance: dist,
              time: time,
              restSeconds: rest > 0 ? rest : null,
            ),
          );
          waterPieceCount = count;
          break;
        case 2:
          waterPieces = _variableIntervals.asMap().entries.map((entry) {
            final i = entry.key;
            final vi = entry.value;
            int? dist;
            int? time;
            if (_pieceFormat == ErgFormat.distance) {
              dist = int.tryParse(vi.valueController.text);
            } else {
              time = int.tryParse(vi.valueController.text);
            }
            final rM = int.tryParse(vi.restMinController.text) ?? 0;
            final rS = int.tryParse(vi.restSecController.text) ?? 0;
            final rest = rM * 60 + rS;
            return WaterPiece(
              pieceNumber: i + 1,
              distance: dist,
              time: time,
              restSeconds: rest > 0 ? rest : null,
            );
          }).toList();
          waterPieceCount = waterPieces.length;
          break;
      }
      if (_looseDescriptionController.text.trim().isNotEmpty)
        waterDescription = _looseDescriptionController.text.trim();
    }

    return WorkoutTemplate(
      id: '',
      organizationId: widget.organization.id,
      teamId: widget.team?.id,
      createdBy: widget.user.id,
      createdAt: now,
      updatedAt: now,
      name: _nameController.text.trim(),
      category: WorkoutCategory.water,
      isBenchmark: _isBenchmark,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      waterFormat: _waterFormat,
      waterDescription: waterDescription,
      waterPieceCount: waterPieceCount,
      waterPieces: waterPieces,
    );
  }
}

class _WaterVariableEntry {
  final TextEditingController valueController = TextEditingController();
  final TextEditingController restMinController = TextEditingController();
  final TextEditingController restSecController = TextEditingController();
  void dispose() {
    valueController.dispose();
    restMinController.dispose();
    restSecController.dispose();
  }
}
