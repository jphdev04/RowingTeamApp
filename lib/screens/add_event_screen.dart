import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../services/calendar_service.dart';
import '../widgets/team_header.dart';
import '../utils/boathouse_styles.dart';

class AddEventScreen extends StatefulWidget {
  final Organization organization;
  final Team? team;
  final DateTime initialDate;
  final String currentUserId;

  const AddEventScreen({
    super.key,
    required this.organization,
    this.team,
    required this.initialDate,
    required this.currentUserId,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calendarService = CalendarService();

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  late EventType _selectedType;

  // Recurring schedule
  bool _isRecurring = false;
  final Set<int> _recurringDays = {}; // 1=Mon, 2=Tue, ..., 7=Sun
  DateTime? _recurringEndDate;
  bool _isSaving = false;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _textOnPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startTime = const TimeOfDay(hour: 6, minute: 0);
    _endTime = const TimeOfDay(hour: 7, minute: 30);
    _selectedType = widget.team == null
        ? EventType.organization
        : EventType.practice;
  }

  List<EventType> get _availableTypes {
    if (widget.team != null) {
      return [
        EventType.practice,
        EventType.race,
        EventType.workout,
        EventType.meeting,
        EventType.other,
      ];
    }
    return [EventType.organization];
  }

  // Only show recurring option for practices
  bool get _canRecur => _selectedType == EventType.practice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          TeamHeader(
            team: widget.team,
            organization: widget.organization,
            title: 'Create Event',
            subtitle: widget.team != null
                ? 'New Team Event'
                : 'New Organization Event',
            leading: IconButton(
              icon: Icon(Icons.close, color: _textOnPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: const [],
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // ── Title ──
                  BoathouseStyles.sectionLabel('Event Title'),
                  BoathouseStyles.textField(
                    primaryColor: primaryColor,
                    controller: _titleController,
                    hintText: 'Morning Practice',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 32),

                  // ── Event type ──
                  if (widget.team != null) ...[
                    BoathouseStyles.sectionLabel('Event Type'),
                    BoathouseStyles.dropdown<EventType>(
                      primaryColor: primaryColor,
                      value: _selectedType,
                      items: _availableTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.typeDisplayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedType = v!;
                          if (!_canRecur) {
                            _isRecurring = false;
                            _recurringDays.clear();
                            _recurringEndDate = null;
                          }
                        });
                      },
                    ),
                  ] else ...[
                    BoathouseStyles.sectionLabel('Event type'),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.corporate_fare),
                      title: Text(EventType.organization.typeDisplayName),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Date & time ──
                  BoathouseStyles.sectionLabel('Date and Time'),
                  const SizedBox(height: 12),
                  _buildDateTimePickers(),
                  const SizedBox(height: 24),

                  // ── Recurring toggle (practices only) ──
                  if (_canRecur) ...[
                    _buildRecurringSection(),
                    const SizedBox(height: 24),
                  ],

                  // ── Location ──
                  BoathouseStyles.sectionLabel('Location'),
                  BoathouseStyles.textField(
                    primaryColor: primaryColor,
                    controller: _locationController,
                    hintText: 'Boathouse',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 24),

                  // ── Notes ──
                  BoathouseStyles.sectionLabel('Notes'),
                  BoathouseStyles.textField(
                    primaryColor: primaryColor,
                    controller: _descriptionController,
                    hintText: 'Any notes for athletes here',
                    prefixIcon: const Icon(Icons.notes),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 40),

                  // ── Save button ──
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: BoathouseStyles.primaryButton(
                      primaryColor: primaryColor,
                      label: _isRecurring
                          ? 'Create Recurring Schedule'
                          : 'Save Event',
                      isLoading: _isSaving,
                      onPressed: _saveEvent,
                    ),
                  ),

                  // ── Preview count ──
                  if (_isRecurring && _recurringDays.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'This will create ${_calculateRecurringCount()} practice events',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Date & time pickers (fixed end time font) ────────────────

  Widget _buildDateTimePickers() {
    return Column(
      children: [
        BoathouseStyles.pickerRow(
          primaryColor: primaryColor,
          icon: Icons.calendar_today,
          text: DateFormat('EEEE, MMM d').format(_selectedDate),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime(2030),
            );
            if (d != null) setState(() => _selectedDate = d);
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: BoathouseStyles.pickerRow(
                primaryColor: primaryColor,
                icon: Icons.access_time,
                text: _startTime.format(context),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (t != null) setState(() => _startTime = t);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BoathouseStyles.pickerRow(
                primaryColor: primaryColor,
                icon: Icons.access_time,
                text: _endTime.format(context),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (t != null) setState(() => _endTime = t);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Recurring practices section ──────────────────────────────

  Widget _buildRecurringSection() {
    return BoathouseStyles.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BoathouseStyles.switchCard(
            primaryColor: primaryColor,
            switches: [
              SwitchTileData(
                title: 'Recurring Schedule',
                subtitle: 'Create practices on multiple days',
                value: _isRecurring,
                onChanged: (v) {
                  setState(() {
                    _isRecurring = v;
                    if (v && _recurringEndDate == null) {
                      _recurringEndDate = _selectedDate.add(
                        const Duration(days: 90),
                      );
                    }
                  });
                },
              ),
            ],
          ),

          if (_isRecurring) ...[
            const SizedBox(height: 16),

            BoathouseStyles.sectionLabel('Repeat on'),

            _buildDaySelector(),

            const SizedBox(height: 20),

            BoathouseStyles.sectionLabel('Until'),

            BoathouseStyles.pickerRow(
              primaryColor: primaryColor,
              icon: Icons.event,
              text: _recurringEndDate != null
                  ? DateFormat('EEEE, MMM d, yyyy').format(_recurringEndDate!)
                  : 'Select end date',
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate:
                      _recurringEndDate ??
                      _selectedDate.add(const Duration(days: 90)),
                  firstDate: _selectedDate.add(const Duration(days: 1)),
                  lastDate: DateTime(2030),
                );
                if (d != null) {
                  setState(() => _recurringEndDate = d);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    const days = [
      (1, 'Mon'),
      (2, 'Tue'),
      (3, 'Wed'),
      (4, 'Thu'),
      (5, 'Fri'),
      (6, 'Sat'),
      (7, 'Sun'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((entry) {
        final (dayNum, label) = entry;
        final selected = _recurringDays.contains(dayNum);

        return SizedBox(
          width: 70,
          child: BoathouseStyles.toggleChip(
            primaryColor: primaryColor,
            label: label,
            selected: selected,
            filled: false,
            onTap: () {
              setState(() {
                if (selected) {
                  _recurringDays.remove(dayNum);
                } else {
                  _recurringDays.add(dayNum);
                }
              });
            },
          ),
        );
      }).toList(),
    );
  }
  // ── Save logic ───────────────────────────────────────────────

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRecurring && _recurringDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one day for recurring schedule'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isRecurring) {
        await _saveRecurringEvents();
      } else {
        await _saveSingleEvent();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveSingleEvent() async {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final newEvent = CalendarEvent(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      startTime: start,
      endTime: end,
      type: _selectedType,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      organizationId: widget.organization.id,
      teamId: widget.team?.id,
      createdByUserId: widget.currentUserId,
    );

    await _calendarService.createEvent(newEvent);
  }

  Future<void> _saveRecurringEvents() async {
    final dates = _generateRecurringDates();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isNotEmpty
        ? _descriptionController.text.trim()
        : null;
    final location = _locationController.text.trim().isNotEmpty
        ? _locationController.text.trim()
        : null;

    // Create all events in batch
    int created = 0;
    for (final date in dates) {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        _startTime.hour,
        _startTime.minute,
      );
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        _endTime.hour,
        _endTime.minute,
      );

      final event = CalendarEvent(
        id: '',
        title: title,
        description: description,
        startTime: start,
        endTime: end,
        type: _selectedType,
        location: location,
        organizationId: widget.organization.id,
        teamId: widget.team?.id,
        createdByUserId: widget.currentUserId,
      );

      await _calendarService.createEvent(event);
      created++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created $created practice events!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  List<DateTime> _generateRecurringDates() {
    final dates = <DateTime>[];
    if (_recurringEndDate == null || _recurringDays.isEmpty) return dates;

    // Start from _selectedDate, go until _recurringEndDate
    var current = _selectedDate;
    while (!current.isAfter(_recurringEndDate!)) {
      // DateTime.weekday: 1=Monday, 7=Sunday (matches our _recurringDays)
      if (_recurringDays.contains(current.weekday)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  int _calculateRecurringCount() {
    return _generateRecurringDates().length;
  }
}
