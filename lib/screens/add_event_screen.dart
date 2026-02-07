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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startTime = const TimeOfDay(hour: 6, minute: 0);
    _endTime = const TimeOfDay(hour: 7, minute: 30);

    // Logic: If no team, it's an Organization event. If team, default to Practice.
    _selectedType = widget.team == null
        ? EventType.organization
        : EventType.practice;
  }

  // Define which types are available based on context
  List<EventType> get _availableTypes {
    if (widget.team != null) {
      // Coaches/Admins in Team View
      return [
        EventType.practice,
        EventType.race,
        EventType.workout,
        EventType.meeting,
        EventType.other,
      ];
    }
    // Admin in Org View
    return [EventType.organization];
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

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
      description: _descriptionController.text.trim(),
      startTime: start,
      endTime: end,
      type: _selectedType,
      location: _locationController.text.trim(),
      organizationId: widget.organization.id,
      teamId: widget.team?.id, // Null if Org event
      createdByUserId: widget.currentUserId,
    );

    await _calendarService.createEvent(newEvent);
    if (mounted) Navigator.pop(context);
  }

  String _formatEnumName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

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
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            // Removed Save button from here
            actions: const [],
          ),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
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

                  if (widget.team != null) ...[
                    DropdownButtonFormField<EventType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      // FIX: Changed .toUpperCase() to our helper function
                      items: _availableTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(_formatEnumName(type.name)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ] else ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.corporate_fare),
                      title: const Text("Event Type"),
                      subtitle: Text(
                        _formatEnumName(EventType.organization.name),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  _buildDateTimePickers(),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 40),

                  // NEW: Large Save Button at the bottom
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.team?.primaryColorObj ??
                            widget.organization?.primaryColorObj ??
                            const Color(0xFF1976D2),
                        foregroundColor:
                            (widget.team?.primaryColorObj ??
                                        widget.organization?.primaryColorObj ??
                                        const Color(0xFF1976D2))
                                    .computeLuminance() >
                                0.5
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ), // Extra padding for bottom of list
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePickers() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: Text(DateFormat('EEEE, MMM d').format(_selectedDate)),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (d != null) setState(() => _selectedDate = d);
          },
        ),
        Row(
          children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(_startTime.format(context)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (t != null) setState(() => _startTime = t);
                },
              ),
            ),
            const Text("to"),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                trailing: Text(_endTime.format(context)),
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
}
