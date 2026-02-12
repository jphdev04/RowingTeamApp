import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../services/workout_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';
import 'manage_lineups_screen.dart';

/// Coaches pick an upcoming water workout session to manage lineups for.
class PickSessionForLineupsScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;

  const PickSessionForLineupsScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
  });

  @override
  State<PickSessionForLineupsScreen> createState() =>
      _PickSessionForLineupsScreenState();
}

class _PickSessionForLineupsScreenState
    extends State<PickSessionForLineupsScreen> {
  final _workoutService = WorkoutService();

  List<WorkoutSession> _sessions = [];
  bool _isLoading = true;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      // Use existing stream-based service, take first emission
      final Stream<List<WorkoutSession>> stream;
      if (widget.team?.id != null) {
        stream = _workoutService.getTeamSessions(
          widget.organization.id,
          widget.team!.id,
        );
      } else {
        // Fallback: get all org sessions if no team
        stream = _workoutService.getTeamSessions(
          widget.organization.id,
          '', // will need org-level query if no team
        );
      }

      final allSessions = await stream.first;

      // Filter to water sessions only, then sort upcoming first
      final waterSessions =
          allSessions.where((s) => s.category == WorkoutCategory.water).toList()
            ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

      if (mounted) {
        setState(() {
          _sessions = waterSessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
            organization: widget.team == null ? widget.organization : null,
            title: 'Manage Lineups',
            subtitle: widget.team?.name ?? widget.organization.name,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                ? _buildEmptyState()
                : _buildSessionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rowing, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No water workouts found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a water workout first, then come back here to set up lineups.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList() {
    // Group sessions by date
    final grouped = <String, List<WorkoutSession>>{};
    for (final s in _sessions) {
      final key = DateFormat('EEEE, MMM d').format(s.scheduledDate);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Select a water workout to manage lineups',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ...grouped.entries.expand(
            (entry) => [
              // Date header
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Session cards for that date
              ...entry.value.map(_buildSessionCard),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(WorkoutSession session) {
    final time = DateFormat('h:mm a').format(session.scheduledDate);
    final lineupCount = _lineupBoatCount(session);
    final hasLineups = lineupCount > 0;
    final spec = session.workoutSpec;
    final format = spec['waterFormat'] as String? ?? '';
    final pieceCount = spec['waterPieceCount'] as int?;

    // Build subtitle parts
    final subtitleParts = <String>[];
    subtitleParts.add(time);
    if (format == 'structured' && pieceCount != null) {
      subtitleParts.add('$pieceCount ${pieceCount == 1 ? 'piece' : 'pieces'}');
    } else if (format == 'loose') {
      subtitleParts.add('Loose format');
    }
    if (session.isSeatRace) {
      subtitleParts.add('Seat Race');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToLineups(session),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasLineups
                      ? Colors.green.withOpacity(0.1)
                      : primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasLineups ? Icons.check_circle_outline : Icons.rowing,
                  color: hasLineups ? Colors.green : primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleParts.join(' · '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Boat count badge
              if (hasLineups) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$lineupCount ${lineupCount == 1 ? 'boat' : 'boats'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
            ],
          ),
        ),
      ),
    );
  }

  int _lineupBoatCount(WorkoutSession session) {
    if (session.lineups == null || session.lineups!.isEmpty) return 0;
    // Return boat count from first piece lineup
    return session.lineups!.first.boats.length;
  }

  Future<void> _navigateToLineups(WorkoutSession session) async {
    final updatedSession = await Navigator.push<WorkoutSession>(
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
    );

    // Refresh in case lineups were modified
    if (updatedSession != null) {
      _loadSessions();
    }
  }
}
