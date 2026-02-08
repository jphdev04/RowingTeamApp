import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../screens/add_event_screen.dart';

class CalendarTab extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization? organization;
  final Team? team;

  const CalendarTab({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  final _calendarService = CalendarService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _groupedEvents = {};
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  bool get _canEdit {
    final role = widget.currentMembership.role;
    return role == MembershipRole.admin || role == MembershipRole.coach;
  }

  Color get _primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization?.primaryColorObj ??
      const Color(0xFF1976D2);

  Map<DateTime, List<CalendarEvent>> _groupEvents(List<CalendarEvent> events) {
    Map<DateTime, List<CalendarEvent>> data = {};
    for (var event in events) {
      bool shouldShow = false;

      if (widget.team != null) {
        if (event.teamId == widget.team!.id ||
            event.type == EventType.organization) {
          shouldShow = true;
        }
      } else {
        shouldShow = true;
      }

      if (shouldShow) {
        final date = _normalizeDate(event.startTime);
        data.putIfAbsent(date, () => []).add(event);
      }
    }
    return data;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _groupedEvents[_normalizeDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.organization == null) {
      return const Center(child: Text('No organization loaded'));
    }

    return Column(
      children: [
        // Action bar (jump to today + add event)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                  _selectedEvents.value = _getEventsForDay(DateTime.now());
                },
                icon: Icon(Icons.today, color: _primaryColor, size: 20),
                label: Text('Today', style: TextStyle(color: _primaryColor)),
              ),
              const Spacer(),
              if (_canEdit)
                TextButton.icon(
                  onPressed: () => _showAddEventDialog(),
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: _primaryColor,
                    size: 20,
                  ),
                  label: Text(
                    'Add Event',
                    style: TextStyle(color: _primaryColor),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Calendar + events
        Expanded(
          child: StreamBuilder<List<CalendarEvent>>(
            stream: _calendarService.getOrganizationEvents(
              widget.organization!.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];
              _groupedEvents = _groupEvents(events);

              if (_selectedDay != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _selectedEvents.value = _getEventsForDay(_selectedDay!);
                });
              }

              return Column(
                children: [
                  _buildTableCalendar(),
                  const Divider(height: 1),
                  Expanded(child: _buildEventList()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableCalendar() {
    return Container(
      color: Colors.white,
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: _primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: widget.team?.secondaryColorObj ?? Colors.blueGrey,
            shape: BoxShape.circle,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _selectedEvents.value = _getEventsForDay(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      ),
    );
  }

  Widget _buildEventList() {
    return ValueListenableBuilder<List<CalendarEvent>>(
      valueListenable: _selectedEvents,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return Center(
            child: Text(
              'No events scheduled',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: value.length,
          itemBuilder: (context, index) => _buildEventCard(value[index]),
        );
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('h:mm a').format(event.startTime)} @ ${event.location ?? "No location"}',
        ),
        trailing: const Icon(Icons.chevron_right, size: 16),
      ),
    );
  }

  void _showAddEventDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AddEventScreen(
          organization: widget.organization!,
          team: widget.team,
          initialDate: _selectedDay ?? DateTime.now(),
          currentUserId: widget.user.id,
        ),
      ),
    );
  }
}
