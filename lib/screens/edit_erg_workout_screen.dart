import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../services/workout_service.dart';
import '../services/calendar_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _workoutService = WorkoutService();
  final _calendarService = CalendarService();

  late ErgType _ergType;
  late ErgFormat _ergFormat;
  late bool _isBenchmark, _hideUntilStart, _athletesCanSeeResults;
  bool _isSaving = false;

  late TextEditingController _nameController, _descriptionController;
  late TextEditingController _singleDistanceController,
      _singleTimeMinController,
      _singleTimeSecController,
      _singleRateCapController;
  late TextEditingController _intervalCountController,
      _intervalDistanceController,
      _intervalTimeMinController,
      _intervalTimeSecController,
      _restMinController,
      _restSecController;

  final FocusNode _intervalCountFocusNode = FocusNode();
  List<TextEditingController> _intervalRateCapControllers = [];
  List<_VIEntry> _variableIntervals = [];

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  void initState() {
    super.initState();
    _init();

    // Refinement: Only sync rate cap controllers when the user finishes editing the count
  }

  void _init() {
    final t = widget.existingTemplate;
    final s = widget.existingSession;
    _ergType = t.ergType ?? ErgType.single;
    _ergFormat = t.ergFormat ?? ErgFormat.distance;
    _isBenchmark = t.isBenchmark;
    _hideUntilStart = s.hideUntilStart;
    _athletesCanSeeResults = s.athletesCanSeeResults;

    _nameController = TextEditingController(text: t.name);
    _descriptionController = TextEditingController(text: t.description ?? '');
    _singleDistanceController = TextEditingController(
      text: t.targetDistance?.toString() ?? '',
    );
    _singleRateCapController = TextEditingController(
      text: t.strokeRateCap?.toString() ?? '',
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

    _intervalRateCapControllers = (t.intervalStrokeRateCaps ?? [])
        .map((c) => TextEditingController(text: c?.toString() ?? ''))
        .toList();

    if (_intervalRateCapControllers.isEmpty) _syncRateCaps();

    if (t.variableIntervals != null) {
      _variableIntervals = t.variableIntervals!.map((vi) {
        final e = _VIEntry();
        if (vi.distance != null) {
          e.vMin.text = vi.distance.toString();
        } else if (vi.time != null) {
          e.vMin.text = (vi.time! ~/ 60).toString();
          e.vSec.text = (vi.time! % 60).toString().padLeft(2, '0');
        }
        if (vi.restSeconds > 0) {
          e.rMin.text = (vi.restSeconds ~/ 60).toString();
          e.rSec.text = (vi.restSeconds % 60).toString().padLeft(2, '0');
        }
        if (vi.strokeRateCap != null) e.rate.text = vi.strokeRateCap.toString();
        return e;
      }).toList();
    }
  }

  void _syncRateCaps() {
    final count = int.tryParse(_intervalCountController.text) ?? 0;
    if (count > 50) return; // Basic sanity check
    while (_intervalRateCapControllers.length < count) {
      _intervalRateCapControllers.add(TextEditingController());
    }
    while (_intervalRateCapControllers.length > count) {
      _intervalRateCapControllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    _intervalCountFocusNode.dispose();
    for (final c in [
      _nameController,
      _descriptionController,
      _singleDistanceController,
      _singleTimeMinController,
      _singleTimeSecController,
      _singleRateCapController,
      _intervalCountController,
      _intervalDistanceController,
      _intervalTimeMinController,
      _intervalTimeSecController,
      _restMinController,
      _restSecController,
    ]) {
      c.dispose();
    }
    for (final c in _intervalRateCapControllers) {
      c.dispose();
    }
    for (final e in _variableIntervals) {
      e.dispose();
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
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  BoathouseStyles.sectionLabel('Workout Name'),
                  BoathouseStyles.textField(
                    primaryColor: primaryColor,
                    controller: _nameController,
                    hintText: 'e.g., 6x1000m',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 20),

                  BoathouseStyles.sectionLabel('Erg Type'),
                  BoathouseStyles.toggleChipRow(
                    primaryColor: primaryColor,
                    labels: const ['Single', 'Intervals', 'Variable'],
                    selectedIndex: ErgType.values.indexOf(_ergType),
                    onSelected: (i) =>
                        setState(() => _ergType = ErgType.values[i]),
                    filled: true,
                  ),
                  const SizedBox(height: 20),

                  BoathouseStyles.sectionLabel('Format'),
                  BoathouseStyles.toggleChipRow(
                    primaryColor: primaryColor,
                    labels: const ['Distance', 'Time'],
                    icons: const [Icons.straighten, Icons.timer],
                    selectedIndex: _ergFormat == ErgFormat.distance ? 0 : 1,
                    onSelected: (i) => setState(
                      () => _ergFormat = i == 0
                          ? ErgFormat.distance
                          : ErgFormat.time,
                    ),
                    spacing: 12,
                  ),
                  const SizedBox(height: 20),

                  _buildDynamicFields(),
                  const SizedBox(height: 20),

                  BoathouseStyles.sectionLabel('Notes (optional)'),
                  BoathouseStyles.textField(
                    primaryColor: primaryColor,
                    controller: _descriptionController,
                    hintText: 'Any notes for athletes...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  BoathouseStyles.switchCard(
                    primaryColor: primaryColor,
                    switches: [
                      SwitchTileData(
                        title: 'Benchmark Test',
                        subtitle: 'Track as official test piece',
                        value: _isBenchmark,
                        onChanged: (v) => setState(() => _isBenchmark = v),
                      ),
                      SwitchTileData(
                        title: 'Hide Until Practice',
                        subtitle: "Athletes can't see until start time",
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
                    label: 'Save Changes',
                    onPressed: _saveChanges,
                    isLoading: _isSaving,
                  ),
                  const SizedBox(height: 16),
                  BoathouseStyles.destructiveButton(
                    label: 'Remove Workout',
                    onPressed: _isSaving ? null : _confirmDelete,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFields() {
    switch (_ergType) {
      case ErgType.single:
        return _buildSingleFields();
      case ErgType.standardIntervals:
        return _buildStdFields();
      case ErgType.variableIntervals:
        return _buildVarFields();
    }
  }

  Widget _buildSingleFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_ergFormat == ErgFormat.distance) ...[
        BoathouseStyles.sectionLabel('Distance'),
        BoathouseStyles.numberField(
          primaryColor: primaryColor,
          controller: _singleDistanceController,
          hintText: 'e.g., 2000',
          suffixText: 'm',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ] else ...[
        BoathouseStyles.sectionLabel('Time'),
        BoathouseStyles.timeInput(
          primaryColor: primaryColor,
          minController: _singleTimeMinController,
          secController: _singleTimeSecController,
        ),
      ],
      const SizedBox(height: 16),
      BoathouseStyles.sectionLabel('Rate Cap (spm)'),
      BoathouseStyles.numberField(
        primaryColor: primaryColor,
        controller: _singleRateCapController,
        hintText: 'No cap',
        suffixText: 'spm',
      ),
    ],
  );

  Widget _buildStdFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      BoathouseStyles.sectionLabel('Number of Intervals'),
      // We wrap it in a Focus widget to detect when the user clicks away
      Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            setState(() => _syncRateCaps());
          }
        },
        child: BoathouseStyles.numberField(
          primaryColor: primaryColor,
          controller: _intervalCountController,
          // focusNode parameter removed from here
          hintText: 'e.g., 6',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ),
      const SizedBox(height: 16),
      BoathouseStyles.sectionLabel(
        _ergFormat == ErgFormat.distance
            ? 'Distance per Interval'
            : 'Time per Interval',
      ),
      if (_ergFormat == ErgFormat.distance)
        BoathouseStyles.numberField(
          primaryColor: primaryColor,
          controller: _intervalDistanceController,
          hintText: 'e.g., 1000',
          suffixText: 'm',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        )
      else
        BoathouseStyles.timeInput(
          primaryColor: primaryColor,
          minController: _intervalTimeMinController,
          secController: _intervalTimeSecController,
        ),
      const SizedBox(height: 16),
      BoathouseStyles.sectionLabel('Rest Between'),
      BoathouseStyles.timeInput(
        primaryColor: primaryColor,
        minController: _restMinController,
        secController: _restSecController,
      ),
      if (_intervalRateCapControllers.isNotEmpty) ...[
        const SizedBox(height: 16),
        BoathouseStyles.sectionLabel('Rate Caps (spm per interval)'),
        _buildRateCapGrid(),
      ],
    ],
  );

  Widget _buildVarFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BoathouseStyles.sectionLabel('Intervals', bottomPadding: 0),
          TextButton.icon(
            onPressed: () => setState(() => _variableIntervals.add(_VIEntry())),
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
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                      onPressed: () => setState(() {
                        _variableIntervals[i].dispose();
                        _variableIntervals.removeAt(i);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Refinement: Support MM:SS in variable intervals
                Text(
                  _ergFormat == ErgFormat.distance ? 'Distance' : 'Time',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                if (_ergFormat == ErgFormat.distance)
                  BoathouseStyles.numberField(
                    primaryColor: primaryColor,
                    controller: vi.vMin,
                    hintText: 'Meters',
                    suffixText: 'm',
                  )
                else
                  BoathouseStyles.compactTimeInput(
                    primaryColor: primaryColor,
                    minController: vi.vMin,
                    secController: vi.vSec,
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rest after',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          BoathouseStyles.compactTimeInput(
                            primaryColor: primaryColor,
                            minController: vi.rMin,
                            secController: vi.rSec,
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          BoathouseStyles.numberField(
                            primaryColor: primaryColor,
                            controller: vi.rate,
                            hintText: '—',
                            suffixText: 'spm',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
    ],
  );

  Widget _buildRateCapGrid() {
    final c = _intervalRateCapControllers.length;
    return Column(
      children: List.generate((c / 2).ceil(), (row) {
        final i1 = row * 2;
        final i2 = i1 + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: _rateCapCell(i1)),
              const SizedBox(width: 10),
              if (i2 < c)
                Expanded(child: _rateCapCell(i2))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        );
      }),
    );
  }

  Widget _rateCapCell(int i) => Row(
    children: [
      SizedBox(
        width: 24,
        child: Text(
          '${i + 1}.',
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
          controller: _intervalRateCapControllers[i],
          hintText: '—',
          suffixText: 'spm',
        ),
      ),
    ],
  );

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _workoutService.updateTemplate(_buildTemplate(DateTime.now()));
      await _workoutService.updateSession(_buildSession());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Workout'),
        content: const Text(
          'This will remove the workout from this practice. The template will still be available for future use.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _isSaving = true);
    try {
      if (widget.existingSession.calendarEventId != null) {
        await _calendarService.unlinkWorkoutFromEvent(
          widget.existingSession.calendarEventId!,
          widget.existingSession.id,
        );
      }
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  WorkoutTemplate _buildTemplate(DateTime now) {
    int? targetDist, targetTime, intCount, intDist, intTime, rest, rateCap;
    List<int?>? intRateCaps;
    List<VariableInterval>? varInts;

    switch (_ergType) {
      case ErgType.single:
        if (_ergFormat == ErgFormat.distance) {
          targetDist = int.tryParse(_singleDistanceController.text);
        } else {
          final m = int.tryParse(_singleTimeMinController.text) ?? 0;
          final s = int.tryParse(_singleTimeSecController.text) ?? 0;
          targetTime = m * 60 + s;
        }
        rateCap = int.tryParse(_singleRateCapController.text);
        break;
      case ErgType.standardIntervals:
        intCount = int.tryParse(_intervalCountController.text);
        if (_ergFormat == ErgFormat.distance) {
          intDist = int.tryParse(_intervalDistanceController.text);
        } else {
          final m = int.tryParse(_intervalTimeMinController.text) ?? 0;
          final s = int.tryParse(_intervalTimeSecController.text) ?? 0;
          intTime = m * 60 + s;
        }
        final rm = int.tryParse(_restMinController.text) ?? 0;
        final rs = int.tryParse(_restSecController.text) ?? 0;
        rest = rm * 60 + rs;
        if (_intervalRateCapControllers.isNotEmpty) {
          intRateCaps = _intervalRateCapControllers
              .map((c) => int.tryParse(c.text))
              .toList();
        }
        break;
      case ErgType.variableIntervals:
        varInts = _variableIntervals.map((e) {
          final m = int.tryParse(e.vMin.text) ?? 0;
          final s = int.tryParse(e.vSec.text) ?? 0;
          final rm = int.tryParse(e.rMin.text) ?? 0;
          final rs = int.tryParse(e.rSec.text) ?? 0;
          return VariableInterval(
            distance: _ergFormat == ErgFormat.distance ? m : null,
            time: _ergFormat == ErgFormat.time ? (m * 60 + s) : null,
            restSeconds: rm * 60 + rs,
            strokeRateCap: int.tryParse(e.rate.text),
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
      targetDistance: targetDist,
      targetTime: targetTime,
      intervalCount: intCount,
      intervalDistance: intDist,
      intervalTime: intTime,
      restSeconds: rest,
      variableIntervals: varInts,
      strokeRateCap: rateCap,
      intervalStrokeRateCaps: intRateCaps,
    );
  }

  WorkoutSession _buildSession() => widget.existingSession.copyWith(
    name: _nameController.text.trim(),
    hideUntilStart: _hideUntilStart,
    athletesCanSeeResults: _athletesCanSeeResults,
  );
}

class _VIEntry {
  final vMin = TextEditingController();
  final vSec = TextEditingController();
  final rMin = TextEditingController();
  final rSec = TextEditingController();
  final rate = TextEditingController();
  void dispose() {
    vMin.dispose();
    vSec.dispose();
    rMin.dispose();
    rSec.dispose();
    rate.dispose();
  }
}
