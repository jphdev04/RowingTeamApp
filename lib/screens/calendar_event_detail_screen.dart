import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/calendar_event.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../services/calendar_service.dart';
import '../services/workout_service.dart';
import '../widgets/team_header.dart';
import 'edit_erg_workout_screen.dart';
import 'create_workout_screen.dart';
import 'create_water_workout_screen.dart';
import 'manage_lineups_screen.dart';

class CalendarEventDetailScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final CalendarEvent event;

  const CalendarEventDetailScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    required this.event,
  });

  @override
  State<CalendarEventDetailScreen> createState() =>
      _CalendarEventDetailScreenState();
}

class _CalendarEventDetailScreenState extends State<CalendarEventDetailScreen> {
  final CalendarService _calendarService = CalendarService();
  final WorkoutService _workoutService = WorkoutService();

  late CalendarEvent _event;
  List<WorkoutSession> _linkedSessions = [];
  Map<String, WorkoutTemplate?> _templateCache = {};
  bool _isLoading = true;

  bool get _isCoachOrAdmin =>
      widget.currentMembership.role == MembershipRole.admin ||
      widget.currentMembership.role == MembershipRole.coach;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadLinkedWorkouts();
  }

  Future<void> _loadLinkedWorkouts() async {
    setState(() => _isLoading = true);

    try {
      final sessionIds = _event.linkedWorkoutSessionIds ?? [];
      if (sessionIds.isEmpty) {
        setState(() {
          _linkedSessions = [];
          _isLoading = false;
        });
        return;
      }

      final List<WorkoutSession> sessions = [];
      for (final sessionId in sessionIds) {
        final session = await _workoutService.getSession(
          widget.organization.id,
          sessionId,
        );
        if (session != null) {
          if (_isCoachOrAdmin ||
              !session.hideUntilStart ||
              session.scheduledDate.isBefore(DateTime.now())) {
            sessions.add(session);
          }

          if (session.templateId != null &&
              !_templateCache.containsKey(session.templateId)) {
            final template = await _workoutService.getTemplate(
              widget.organization.id,
              session.templateId!,
            );
            _templateCache[session.templateId!] = template;
          }
        }
      }

      setState(() {
        _linkedSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading workouts: $e')));
      }
    }
  }

  Future<void> _refreshEvent() async {
    final updated = await _calendarService.getEvent(_event.id);
    if (updated != null && mounted) {
      setState(() => _event = updated);
      _loadLinkedWorkouts();
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
            title: _event.title,
            subtitle: _event.type.typeDisplayName,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: _isCoachOrAdmin
                ? [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: _onPrimary),
                      onPressed: _editEvent,
                      tooltip: 'Edit Event',
                    ),
                  ]
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshEvent,
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildEventInfoSection(),
                  const SizedBox(height: 20),
                  if (_event.description != null &&
                      _event.description!.isNotEmpty) ...[
                    _buildDescriptionSection(),
                    const SizedBox(height: 20),
                  ],
                  _buildWorkoutsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EVENT INFO SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildEventInfoSection() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final isSameDay =
        _event.startTime.year == _event.endTime.year &&
        _event.startTime.month == _event.endTime.month &&
        _event.startTime.day == _event.endTime.day;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _eventTypeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_eventTypeIcon, size: 16, color: _eventTypeColor),
                  const SizedBox(width: 6),
                  Text(
                    _event.type.typeDisplayName,
                    style: TextStyle(
                      color: _eventTypeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              dateFormat.format(_event.startTime),
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.access_time_outlined,
              isSameDay
                  ? '${timeFormat.format(_event.startTime)} – ${timeFormat.format(_event.endTime)}'
                  : '${timeFormat.format(_event.startTime)} – ${dateFormat.format(_event.endTime)} ${timeFormat.format(_event.endTime)}',
            ),
            if (_event.location != null && _event.location!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoRow(Icons.location_on_outlined, _event.location!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Color get _eventTypeColor {
    switch (_event.type) {
      case EventType.practice:
        return Colors.blue;
      case EventType.race:
        return Colors.red;
      case EventType.workout:
        return Colors.orange;
      case EventType.meeting:
        return Colors.purple;
      case EventType.organization:
        return Colors.teal;
      case EventType.other:
        return Colors.grey;
    }
  }

  IconData get _eventTypeIcon {
    switch (_event.type) {
      case EventType.practice:
        return Icons.rowing;
      case EventType.race:
        return Icons.emoji_events_outlined;
      case EventType.workout:
        return Icons.fitness_center;
      case EventType.meeting:
        return Icons.groups_outlined;
      case EventType.organization:
        return Icons.business_outlined;
      case EventType.other:
        return Icons.event_outlined;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DESCRIPTION SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _event.description!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WORKOUTS SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildWorkoutsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workout Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                if (_isCoachOrAdmin)
                  TextButton.icon(
                    onPressed: _addWorkoutToPractice,
                    icon: Icon(Icons.add, size: 18, color: primaryColor),
                    label: Text(
                      'Add Workout',
                      style: TextStyle(color: primaryColor, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_linkedSessions.isEmpty)
              _buildEmptyWorkouts()
            else
              ..._linkedSessions
                  .map((session) => _buildWorkoutCard(session))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWorkouts() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.fitness_center, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            _isCoachOrAdmin
                ? 'No workouts linked to this event yet'
                : 'No workouts posted for this event',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutSession session) {
    final template = session.templateId != null
        ? _templateCache[session.templateId]
        : null;

    final categoryIcon = _getCategoryIcon(session.category);
    final categoryColor = _getCategoryColor(session.category);
    final spec = _buildWorkoutSpec(session, template);

    // isBenchmark lives on the template, not the session
    final isBenchmark = template?.isBenchmark ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(categoryIcon, size: 20, color: categoryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (spec.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          spec,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isBenchmark)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      'Benchmark',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (template != null && session.category == WorkoutCategory.erg)
            _buildErgDetails(template),
          if (session.category == WorkoutCategory.water ||
              session.category == WorkoutCategory.race)
            _buildLineupSection(session),
          if (_isCoachOrAdmin) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () => _editWorkout(session, template),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Workout',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErgDetails(WorkoutTemplate template) {
    final details = <_DetailItem>[];

    if (template.ergType != null) {
      String typeLabel;
      switch (template.ergType!) {
        case ErgType.single:
          typeLabel = 'Single Piece';
          break;
        case ErgType.standardIntervals:
          typeLabel = 'Standard Intervals';
          break;
        case ErgType.variableIntervals:
          typeLabel = 'Variable Intervals';
          break;
      }
      details.add(_DetailItem('Type', typeLabel));
    }

    if (template.ergFormat != null) {
      details.add(
        _DetailItem(
          'Format',
          template.ergFormat == ErgFormat.distance ? 'Distance' : 'Time',
        ),
      );
    }

    if (template.targetDistance != null) {
      details.add(_DetailItem('Distance', '${template.targetDistance}m'));
    }
    if (template.targetTime != null) {
      final min = template.targetTime! ~/ 60;
      final sec = template.targetTime! % 60;
      details.add(
        _DetailItem('Time', '${min}:${sec.toString().padLeft(2, '0')}'),
      );
    }

    if (template.intervalCount != null) {
      details.add(_DetailItem('Intervals', '${template.intervalCount}'));
    }
    if (template.intervalDistance != null) {
      details.add(_DetailItem('Per Interval', '${template.intervalDistance}m'));
    }
    if (template.intervalTime != null) {
      final min = template.intervalTime! ~/ 60;
      final sec = template.intervalTime! % 60;
      details.add(
        _DetailItem('Per Interval', '${min}:${sec.toString().padLeft(2, '0')}'),
      );
    }

    if (template.restSeconds != null && template.restSeconds! > 0) {
      final min = template.restSeconds! ~/ 60;
      final sec = template.restSeconds! % 60;
      details.add(
        _DetailItem('Rest', '${min}:${sec.toString().padLeft(2, '0')}'),
      );
    }

    if (template.variableIntervals != null &&
        template.variableIntervals!.isNotEmpty) {
      final pieces = template.variableIntervals!
          .map((vi) {
            if (vi.distance != null) return '${vi.distance}m';
            if (vi.time != null) {
              final m = vi.time! ~/ 60;
              final s = vi.time! % 60;
              return '${m}:${s.toString().padLeft(2, '0')}';
            }
            return '?';
          })
          .join(' / ');
      details.add(_DetailItem('Pieces', pieces));

      // Show per-piece rate caps if any are set
      final rateCaps = template.variableIntervals!
          .where((vi) => vi.strokeRateCap != null)
          .map((vi) => '${vi.strokeRateCap} spm')
          .join(' / ');
      if (rateCaps.isNotEmpty) {
        details.add(_DetailItem('Rate Caps', rateCaps));
      }
    }

    // Single piece rate cap
    if (template.strokeRateCap != null) {
      details.add(_DetailItem('Rate Cap', '${template.strokeRateCap} spm'));
    }

    // Per-interval rate caps for standard intervals
    if (template.intervalStrokeRateCaps != null &&
        template.intervalStrokeRateCaps!.any((c) => c != null)) {
      final caps = template.intervalStrokeRateCaps!
          .map((c) => c != null ? '$c' : '—')
          .join(' / ');
      details.add(_DetailItem('Rate Caps', '$caps spm'));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: details.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == details.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineupSection(WorkoutSession session) {
    final lineups = session.lineups ?? [];
    final hasLineups =
        lineups.isNotEmpty && lineups.any((pl) => pl.boats.isNotEmpty);
    final boats = hasLineups ? lineups.first.boats : <BoatLineup>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Lineups',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (hasLineups) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${boats.length} ${boats.length == 1 ? 'boat' : 'boats'}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_isCoachOrAdmin)
                  GestureDetector(
                    onTap: () => _navigateToLineups(session),
                    child: Text(
                      hasLineups ? 'Edit' : 'Create',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),

            if (!hasLineups) ...[
              const SizedBox(height: 10),
              Text(
                _isCoachOrAdmin
                    ? 'No lineups yet — tap Create to set up boats'
                    : 'Lineups not yet posted',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ] else ...[
              const SizedBox(height: 10),
              ...boats.map((boat) => _buildLineupBoatRow(boat)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineupBoatRow(BoatLineup boat) {
    final totalSeats = _seatsForBoatClass(boat.boatClass);
    final filledSeats = boat.seats.where((s) => s.userId != null).length;
    final isFull = filledSeats == totalSeats;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Boat class badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              boat.boatClass,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Boat name
          Expanded(
            child: Text(
              boat.boatName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),

          // Seat count + status
          Text(
            '$filledSeats/$totalSeats',
            style: TextStyle(
              fontSize: 12,
              color: isFull ? Colors.green[600] : Colors.orange[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isFull ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isFull ? Colors.green : Colors.orange,
            size: 14,
          ),
        ],
      ),
    );
  }

  void _navigateToLineups(WorkoutSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageLineupsScreen(
          user: widget.user,
          currentMembership: widget.currentMembership,
          organization: widget.organization,
          team: widget.team,
          session: session,
        ),
      ),
    ).then((_) => _refreshEvent());
  }

  int _seatsForBoatClass(String boatClass) {
    switch (boatClass) {
      case '8+':
        return 8;
      case '4+':
      case '4-':
      case '4x':
      case '4x+':
        return 4;
      case '2-':
      case '2x':
        return 2;
      case '1x':
        return 1;
      default:
        return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  String _buildWorkoutSpec(WorkoutSession session, WorkoutTemplate? template) {
    if (template == null) return session.category.name.toUpperCase();

    if (session.category == WorkoutCategory.erg) {
      return _buildErgSpecString(template);
    }
    return session.category.name[0].toUpperCase() +
        session.category.name.substring(1);
  }

  String _buildErgSpecString(WorkoutTemplate template) {
    switch (template.ergType) {
      case ErgType.single:
        if (template.targetDistance != null)
          return '${template.targetDistance}m';
        if (template.targetTime != null) {
          final min = template.targetTime! ~/ 60;
          final sec = template.targetTime! % 60;
          return '${min}:${sec.toString().padLeft(2, '0')} piece';
        }
        return 'Single piece';

      case ErgType.standardIntervals:
        final count = template.intervalCount ?? 0;
        if (template.intervalDistance != null) {
          return '${count}x${template.intervalDistance}m';
        }
        if (template.intervalTime != null) {
          final min = template.intervalTime! ~/ 60;
          final sec = template.intervalTime! % 60;
          return '${count}x${min}:${sec.toString().padLeft(2, '0')}';
        }
        return '${count} intervals';

      case ErgType.variableIntervals:
        if (template.variableIntervals != null) {
          final pieces = template.variableIntervals!
              .map((vi) {
                if (vi.distance != null) return '${vi.distance}m';
                if (vi.time != null) {
                  final m = vi.time! ~/ 60;
                  final s = vi.time! % 60;
                  return '${m}:${s.toString().padLeft(2, '0')}';
                }
                return '?';
              })
              .join('/');
          return pieces;
        }
        return 'Variable intervals';

      default:
        return 'Erg workout';
    }
  }

  IconData _getCategoryIcon(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.erg:
        return Icons.timer_outlined;
      case WorkoutCategory.water:
        return Icons.water;
      case WorkoutCategory.race:
        return Icons.emoji_events_outlined;
      case WorkoutCategory.lift:
        return Icons.fitness_center;
      case WorkoutCategory.circuit:
        return Icons.loop;
    }
  }

  Color _getCategoryColor(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.erg:
        return Colors.blue;
      case WorkoutCategory.water:
        return Colors.cyan;
      case WorkoutCategory.race:
        return Colors.red;
      case WorkoutCategory.lift:
        return Colors.deepOrange;
      case WorkoutCategory.circuit:
        return Colors.green;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════

  void _editEvent() {
    // TODO: Pass _event to AddEventScreen in edit mode
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit event coming soon')));
  }

  void _addWorkoutToPractice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutScreen(
          user: widget.user,
          currentMembership: widget.currentMembership,
          organization: widget.organization,
          team: widget.team,
          preLinkedEvent: _event,
        ),
      ),
    ).then((_) => _refreshEvent());
  }

  void _editWorkout(WorkoutSession session, WorkoutTemplate? template) {
    if (template == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edit not yet available for this workout'),
        ),
      );
      return;
    }

    switch (session.category) {
      case WorkoutCategory.erg:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditErgWorkoutScreen(
              user: widget.user,
              currentMembership: widget.currentMembership,
              organization: widget.organization,
              team: widget.team,
              existingTemplate: template,
              existingSession: session,
            ),
          ),
        ).then((_) => _refreshEvent());
        break;
      case WorkoutCategory.water:
        // TODO: EditWaterWorkoutScreen (follow same pattern as EditErgWorkoutScreen)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Water workout editing coming soon')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edit not yet available for this workout type'),
          ),
        );
    }
  }
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}
