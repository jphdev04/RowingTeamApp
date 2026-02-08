import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../services/calendar_service.dart';
import '../widgets/team_header.dart';

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
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      border: UnderlineInputBorder(),
                      floatingLabelStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 32),

                  // ── Event type ──
                  if (widget.team != null) ...[
                    DropdownButtonFormField<EventType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _availableTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.typeDisplayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedType = v!;
                        // Reset recurring if switching away from practice
                        if (!_canRecur) {
                          _isRecurring = false;
                          _recurringDays.clear();
                          _recurringEndDate = null;
                        }
                      }),
                    ),
                  ] else ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.corporate_fare),
                      title: const Text('Event Type'),
                      subtitle: Text(
                        EventType.organization.typeDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Date & time ──
                  _buildDateTimePickers(),
                  const SizedBox(height: 24),

                  // ── Recurring toggle (practices only) ──
                  if (_canRecur) ...[
                    _buildRecurringSection(),
                    const SizedBox(height: 24),
                  ],

                  // ── Location ──
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Notes ──
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 40),

                  // ── Save button ──
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: _textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _textOnPrimary,
                              ),
                            )
                          : Text(
                              _isRecurring
                                  ? 'Create Recurring Schedule'
                                  : 'Save Event',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
        // Date
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: Text(
            DateFormat('EEEE, MMM d').format(_selectedDate),
            style: const TextStyle(fontSize: 16),
          ),
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
        // Start & end time
        Row(
          children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(
                  _startTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (t != null) setState(() => _startTime = t);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('to', style: TextStyle(fontSize: 16)),
            ),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const SizedBox(width: 24), // alignment spacer
                title: Text(
                  _endTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Toggle
          SwitchListTile(
            title: const Text('Recurring Schedule'),
            subtitle: const Text('Create practices on multiple days'),
            value: _isRecurring,
            activeColor: primaryColor,
            onChanged: (v) => setState(() {
              _isRecurring = v;
              if (v && _recurringEndDate == null) {
                // Default to 3 months out
                _recurringEndDate = _selectedDate.add(const Duration(days: 90));
              }
            }),
          ),

          if (_isRecurring) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeat on',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDaySelector(),
                  const SizedBox(height: 20),

                  // End date
                  Text(
                    'Until',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _recurringEndDate != null
                                ? DateFormat(
                                    'EEEE, MMM d, yyyy',
                                  ).format(_recurringEndDate!)
                                : 'Select end date',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((entry) {
        final (dayNum, label) = entry;
        final selected = _recurringDays.contains(dayNum);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _recurringDays.remove(dayNum);
            } else {
              _recurringDays.add(dayNum);
            }
          }),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? primaryColor : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? _textOnPrimary : Colors.grey[700],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
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
