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

class CreateErgWorkoutScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final WorkoutTemplate? fromTemplate;
  final dynamic preLinkedEvent;

  const CreateErgWorkoutScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    this.fromTemplate,
    this.preLinkedEvent,
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
  final _singleRateCapController = TextEditingController();

  // Standard intervals
  final _intervalCountController = TextEditingController();
  final _intervalDistanceController = TextEditingController();
  final _intervalTimeMinController = TextEditingController();
  final _intervalTimeSecController = TextEditingController();
  final _restMinController = TextEditingController();
  final _restSecController = TextEditingController();
  List<TextEditingController> _intervalRateCapControllers = [];

  // Variable intervals
  List<_VariableIntervalEntry> _variableIntervals = [_VariableIntervalEntry()];

  // Practice linking
  String _scheduleMode = 'linkToPractice';
  List<CalendarEvent> _upcomingPractices = [];
  CalendarEvent? _selectedPractice;
  bool _loadingPractices = true;

  // Session scheduling (on-your-own mode)
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();

  // Options
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
    if (widget.fromTemplate != null) {
      _loadFromTemplate(widget.fromTemplate!);
    }
    if (widget.preLinkedEvent != null) {
      _scheduleMode = 'linkToPractice';
      _selectedPractice = widget.preLinkedEvent as CalendarEvent?;
    }
    _loadUpcomingPractices();
  }

  void _loadFromTemplate(WorkoutTemplate t) {
    _ergType = t.ergType ?? ErgType.single;
    _ergFormat = t.ergFormat ?? ErgFormat.distance;
    _isBenchmark = t.isBenchmark;
    _nameController.text = t.name;
    _nameManuallyEdited = true;
    _descriptionController.text = t.description ?? '';

    // Single piece
    if (t.targetDistance != null) {
      _singleDistanceController.text = t.targetDistance.toString();
    }
    if (t.targetTime != null) {
      _singleTimeMinController.text = (t.targetTime! ~/ 60).toString();
      _singleTimeSecController.text = (t.targetTime! % 60).toString().padLeft(
        2,
        '0',
      );
    }
    if (t.strokeRateCap != null) {
      _singleRateCapController.text = t.strokeRateCap.toString();
    }

    // Standard intervals
    if (t.intervalCount != null) {
      _intervalCountController.text = t.intervalCount.toString();
    }
    if (t.intervalDistance != null) {
      _intervalDistanceController.text = t.intervalDistance.toString();
    }
    if (t.intervalTime != null) {
      _intervalTimeMinController.text = (t.intervalTime! ~/ 60).toString();
      _intervalTimeSecController.text = (t.intervalTime! % 60)
          .toString()
          .padLeft(2, '0');
    }
    if (t.restSeconds != null) {
      _restMinController.text = (t.restSeconds! ~/ 60).toString();
      _restSecController.text = (t.restSeconds! % 60).toString().padLeft(
        2,
        '0',
      );
    }
    // Per-interval rate caps
    if (t.intervalStrokeRateCaps != null) {
      _intervalRateCapControllers = t.intervalStrokeRateCaps!
          .map((cap) => TextEditingController(text: cap?.toString() ?? ''))
          .toList();
    }

    // Variable intervals
    if (t.variableIntervals != null && t.variableIntervals!.isNotEmpty) {
      _variableIntervals = t.variableIntervals!.map((vi) {
        final entry = _VariableIntervalEntry();
        if (_ergFormat == ErgFormat.distance && vi.distance != null) {
          entry.valueController.text = vi.distance.toString();
        } else if (_ergFormat == ErgFormat.time && vi.time != null) {
          entry.valueController.text = vi.time.toString();
        }
        if (vi.restSeconds > 0) {
          entry.restMinController.text = (vi.restSeconds ~/ 60).toString();
          entry.restSecController.text = (vi.restSeconds % 60)
              .toString()
              .padLeft(2, '0');
        }
        if (vi.strokeRateCap != null) {
          entry.rateCapController.text = vi.strokeRateCap.toString();
        }
        return entry;
      }).toList();
    }

    setState(() {});
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
        final now = DateTime.now();
        final twoWeeksFromNow = now.add(const Duration(days: 14));

        // 1. Filter: Only within the next two weeks (starting from start of today)
        final today = DateTime(now.year, now.month, now.day);
        final filteredPractices = practices.where((p) {
          return p.startTime.isAfter(today) &&
              p.startTime.isBefore(twoWeeksFromNow);
        }).toList();

        // 2. Sort: Ensure they are in chronological order
        filteredPractices.sort((a, b) => a.startTime.compareTo(b.startTime));

        setState(() {
          _upcomingPractices = filteredPractices;
          _loadingPractices = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPractices = false);
    }
  }

  /// Ensure the per-interval rate cap controllers match the interval count.
  void _syncIntervalRateCapControllers() {
    final count = int.tryParse(_intervalCountController.text) ?? 0;
    while (_intervalRateCapControllers.length < count) {
      _intervalRateCapControllers.add(TextEditingController());
    }
    while (_intervalRateCapControllers.length > count) {
      _intervalRateCapControllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _singleDistanceController.dispose();
    _singleTimeMinController.dispose();
    _singleTimeSecController.dispose();
    _singleRateCapController.dispose();
    _intervalCountController.dispose();
    _intervalDistanceController.dispose();
    _intervalTimeMinController.dispose();
    _intervalTimeSecController.dispose();
    _restMinController.dispose();
    _restSecController.dispose();
    for (final c in _intervalRateCapControllers) {
      c.dispose();
    }
    for (final entry in _variableIntervals) {
      entry.dispose();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // AUTO-NAME
  // ═══════════════════════════════════════════════════════════

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
      _nameController.text = _generateName();
      _nameManuallyEdited = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

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
                  // ── Erg Type ──
                  BoathouseStyles.sectionLabel('Erg Type'),
                  BoathouseStyles.toggleChipRow(
                    primaryColor: primaryColor,
                    labels: const ['Single', 'Intervals', 'Variable'],
                    selectedIndex: ErgType.values.indexOf(_ergType),
                    onSelected: (i) {
                      setState(() => _ergType = ErgType.values[i]);
                      _updateAutoName();
                    },
                    filled: true,
                  ),
                  const SizedBox(height: 24),

                  // ── Format ──
                  BoathouseStyles.sectionLabel('Format'),
                  BoathouseStyles.toggleChipRow(
                    primaryColor: primaryColor,
                    labels: const ['Distance', 'Time'],
                    icons: const [Icons.straighten, Icons.timer],
                    selectedIndex: _ergFormat == ErgFormat.distance ? 0 : 1,
                    onSelected: (i) {
                      setState(
                        () => _ergFormat = i == 0
                            ? ErgFormat.distance
                            : ErgFormat.time,
                      );
                      _updateAutoName();
                    },
                    spacing: 12,
                  ),
                  const SizedBox(height: 24),

                  // ── Type-specific fields ──
                  ..._buildTypeSpecificFields(),
                  const SizedBox(height: 24),

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

                  // ── Description ──
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
                  _buildScheduleModeSelector(),
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

                  // ── Save ──
                  BoathouseStyles.primaryButton(
                    primaryColor: primaryColor,
                    label: 'Create Workout',
                    onPressed: _save,
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

  // ═══════════════════════════════════════════════════════════
  // TYPE-SPECIFIC FIELDS
  // ═══════════════════════════════════════════════════════════

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
    return [
      if (_ergFormat == ErgFormat.distance) ...[
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
      const SizedBox(height: 16),
      // Rate cap for single piece
      BoathouseStyles.sectionLabel('Rate Cap (spm)'),
      _buildRateCapField(_singleRateCapController),
    ];
  }

  List<Widget> _buildStandardIntervalFields() {
    return [
      BoathouseStyles.sectionLabel('Number of Intervals'),
      BoathouseStyles.numberField(
        primaryColor: primaryColor,
        controller: _intervalCountController,
        hintText: 'e.g. 6',
        onChanged: (_) {
          _updateAutoName();
          setState(() => _syncIntervalRateCapControllers());
        },
      ),
      const SizedBox(height: 16),

      BoathouseStyles.sectionLabel(
        _ergFormat == ErgFormat.distance
            ? 'Distance per Interval (meters)'
            : 'Time per Interval',
      ),
      if (_ergFormat == ErgFormat.distance)
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
      const SizedBox(height: 16),

      // Per-interval rate caps
      if (_intervalRateCapControllers.isNotEmpty) ...[
        BoathouseStyles.sectionLabel('Rate Caps (spm per interval)'),
        _buildPerIntervalRateCaps(),
      ],
    ];
  }

  List<Widget> _buildVariableIntervalFields() {
    return [
      BoathouseStyles.sectionLabel('Intervals'),
      const SizedBox(height: 4),
      ...List.generate(_variableIntervals.length, (index) {
        final entry = _variableIntervals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BoathouseStyles.card(
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
                BoathouseStyles.numberField(
                  primaryColor: primaryColor,
                  controller: entry.valueController,
                  hintText: _ergFormat == ErgFormat.distance
                      ? 'Distance (m)'
                      : 'Time (seconds)',
                  suffixText: _ergFormat == ErgFormat.distance ? 'm' : 's',
                  onChanged: (_) => _updateAutoName(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            minController: entry.restMinController,
                            secController: entry.restSecController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate Cap',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildRateCapField(entry.rateCapController),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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

  // ═══════════════════════════════════════════════════════════
  // RATE CAP HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Compact rate cap field used in single piece and variable intervals.
  Widget _buildRateCapField(TextEditingController controller) {
    return BoathouseStyles.numberField(
      primaryColor: primaryColor,
      controller: controller,
      hintText: 'No cap',
      suffixText: 'spm',
    );
  }

  /// Grid of per-interval rate cap fields for standard intervals.
  Widget _buildPerIntervalRateCaps() {
    final count = _intervalRateCapControllers.length;
    // Show in a 2-column grid
    final rows = (count / 2).ceil();
    return Column(
      children: List.generate(rows, (row) {
        final i1 = row * 2;
        final i2 = i1 + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: _buildLabeledRateCap(i1)),
              const SizedBox(width: 10),
              if (i2 < count)
                Expanded(child: _buildLabeledRateCap(i2))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLabeledRateCap(int index) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '${index + 1}.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: BoathouseStyles.compactNumberField(
            primaryColor: primaryColor,
            controller: _intervalRateCapControllers[index],
            hintText: '—',
            suffixText: 'spm',
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SCHEDULE
  // ═══════════════════════════════════════════════════════════

  Widget _buildScheduleModeSelector() {
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
              'No practices in the next 2 weeks',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    List<Widget> children = [];
    DateTime? lastDate;

    for (var practice in _upcomingPractices) {
      // Check if we need to insert a Date Header (e.g., "Monday 10/05")
      final practiceDate = DateTime(
        practice.startTime.year,
        practice.startTime.month,
        practice.startTime.day,
      );

      if (lastDate == null || practiceDate != lastDate) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
            child: Text(
              DateFormat('EEEE MM/dd').format(practice.startTime),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
        lastDate = practiceDate;
      }

      // Build the individual practice item
      final isSelected = _selectedPractice?.id == practice.id;
      final workoutCount = (practice.linkedWorkoutSessionIds ?? []).length;

      children.add(
        InkWell(
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
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? primaryColor : Colors.grey[400],
                    size: 20,
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
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${DateFormat('h:mm a').format(practice.startTime)} – ${DateFormat('h:mm a').format(practice.endTime)}',
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
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$workoutCount',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SAVE
  // ═══════════════════════════════════════════════════════════

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      _nameController.text = _generateName();
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_validateErgFields()) return;

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

      final template = _buildTemplate(now);

      WorkoutTemplate? savedTemplate;
      if (_saveAsTemplate) {
        savedTemplate = await _workoutService.createTemplate(template);
      }

      // Build workoutSpec snapshot
      final workoutSpec = <String, dynamic>{
        'ergType': _ergType.name,
        'ergFormat': _ergFormat.name,
        if (template.targetDistance != null)
          'targetDistance': template.targetDistance,
        if (template.targetTime != null) 'targetTime': template.targetTime,
        if (template.intervalCount != null)
          'intervalCount': template.intervalCount,
        if (template.intervalDistance != null)
          'intervalDistance': template.intervalDistance,
        if (template.intervalTime != null)
          'intervalTime': template.intervalTime,
        if (template.restSeconds != null) 'restSeconds': template.restSeconds,
        if (template.strokeRateCap != null)
          'strokeRateCap': template.strokeRateCap,
        if (template.intervalStrokeRateCaps != null)
          'intervalStrokeRateCaps': template.intervalStrokeRateCaps,
        if (template.variableIntervals != null)
          'variableIntervals': template.variableIntervals!
              .map((vi) => vi.toMap())
              .toList(),
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
        category: WorkoutCategory.erg,
        scheduledDate: scheduledDateTime,
        workoutSpec: workoutSpec,
        hideUntilStart: _hideUntilStart,
        athletesCanSeeResults: _athletesCanSeeResults,
      );

      final createdSession = await _workoutService.createSession(session);

      if (calendarEventId != null) {
        await _calendarService.linkWorkoutToEvent(
          calendarEventId,
          createdSession.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _scheduleMode == 'linkToPractice'
                  ? 'Workout created and linked to practice!'
                  : 'On-your-own workout created!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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

  WorkoutTemplate _buildTemplate(DateTime now) {
    int? targetDistance;
    int? targetTime;
    int? intervalCount;
    int? intervalDistance;
    int? intervalTime;
    int? restSeconds;
    int? strokeRateCap;
    List<int?>? intervalStrokeRateCaps;
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
        strokeRateCap = int.tryParse(_singleRateCapController.text);
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
        // Per-interval rate caps
        if (_intervalRateCapControllers.isNotEmpty) {
          intervalStrokeRateCaps = _intervalRateCapControllers
              .map((c) => int.tryParse(c.text))
              .toList();
        }
        break;

      case ErgType.variableIntervals:
        variableIntervals = _variableIntervals.map((entry) {
          final val = int.tryParse(entry.valueController.text) ?? 0;
          final rMin = int.tryParse(entry.restMinController.text) ?? 0;
          final rSec = int.tryParse(entry.restSecController.text) ?? 0;
          final rate = int.tryParse(entry.rateCapController.text);
          return VariableInterval(
            distance: _ergFormat == ErgFormat.distance ? val : null,
            time: _ergFormat == ErgFormat.time ? val : null,
            restSeconds: rMin * 60 + rSec,
            strokeRateCap: rate,
          );
        }).toList();
        break;
    }

    return WorkoutTemplate(
      id: '',
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
      strokeRateCap: strokeRateCap,
      intervalStrokeRateCaps: intervalStrokeRateCaps,
    );
  }
}

/// Helper class for variable interval form entries
class _VariableIntervalEntry {
  final TextEditingController valueController = TextEditingController();
  final TextEditingController restMinController = TextEditingController();
  final TextEditingController restSecController = TextEditingController();
  final TextEditingController rateCapController = TextEditingController();

  void dispose() {
    valueController.dispose();
    restMinController.dispose();
    restSecController.dispose();
    rateCapController.dispose();
  }
}
