import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/workout_result.dart';
import '../services/workout_service.dart';
import '../utils/boathouse_styles.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../models/workout_template.dart';

class ProfileTab extends StatefulWidget {
  final AppUser user;
  final List<Membership> memberships;
  final Membership currentMembership;
  final Organization? organization;
  final Team? team;

  const ProfileTab({
    super.key,
    required this.user,
    required this.memberships,
    required this.currentMembership,
    required this.organization,
    required this.team,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _workoutService = WorkoutService();

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization?.primaryColorObj ??
      Colors.blue;

  bool get _isRower =>
      widget.currentMembership.role == MembershipRole.rower ||
      widget.currentMembership.role == MembershipRole.athlete;

  @override
  Widget build(BuildContext context) {
    final orgId = widget.organization?.id;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Profile Header Card ──
        _buildProfileHeader(),
        const SizedBox(height: 20),

        // ── Stats from workout results ──
        if (orgId != null)
          StreamBuilder<List<WorkoutResult>>(
            stream: _workoutService.getUserResults(orgId, widget.user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                );
              }

              final results = snapshot.data ?? [];
              final ergResults = results
                  .where((r) => r.category == WorkoutCategory.erg)
                  .toList();

              if (results.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Stats Row ──
                  _buildQuickStats(results, ergResults),
                  const SizedBox(height: 20),

                  // ── Erg PRs ──
                  if (ergResults.isNotEmpty) ...[
                    BoathouseStyles.sectionLabel('Erg Personal Records'),
                    const SizedBox(height: 4),
                    _buildErgPRs(ergResults),
                    const SizedBox(height: 20),
                  ],

                  // ── Recent Activity ──
                  BoathouseStyles.sectionLabel('Recent Activity'),
                  const SizedBox(height: 4),
                  _buildRecentActivity(results),
                ],
              );
            },
          )
        else
          _buildEmptyState(),

        const SizedBox(height: 24),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // PROFILE HEADER
  // ════════════════════════════════════════════════════════════

  Widget _buildProfileHeader() {
    final membership = widget.currentMembership;

    return BoathouseStyles.card(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar + edit/settings row
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: primaryColor,
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.email,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildRoleBadge(membership),
                        if (_isRower && membership.side != null) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            _sideLabel(membership.side!),
                            Icons.swap_horiz,
                          ),
                        ],
                        if (_isRower && membership.weightClass != null) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            _shortWeightClass(membership.weightClass!),
                            Icons.monitor_weight_outlined,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          user: widget.user,
                          membership: widget.currentMembership,
                          organization: widget.organization,
                          team: widget.team,
                        ),
                      ),
                    );
                    if (result == true && mounted) setState(() {});
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: primaryColor,
                  ),
                  label: Text(
                    'Edit Profile',
                    style: TextStyle(color: primaryColor, fontSize: 13),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey[200]),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          user: widget.user,
                          membership: widget.currentMembership,
                          organization: widget.organization,
                          team: widget.team,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  label: Text(
                    'Settings',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // QUICK STATS
  // ════════════════════════════════════════════════════════════

  Widget _buildQuickStats(
    List<WorkoutResult> allResults,
    List<WorkoutResult> ergResults,
  ) {
    // Lifetime erg meters
    final lifetimeMeters = ergResults.fold<int>(
      0,
      (sum, r) => sum + r.calculatedErgTotalDistance,
    );

    // Total workouts logged
    final totalWorkouts = allResults.length;

    // This month's meters
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthMeters = ergResults
        .where((r) => r.createdAt.isAfter(monthStart))
        .fold<int>(0, (sum, r) => sum + r.calculatedErgTotalDistance);

    // Current streak (consecutive days with a workout)
    final streak = _calculateStreak(allResults);

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            label: 'Lifetime Meters',
            value: _formatMeters(lifetimeMeters),
            icon: Icons.straighten,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            label: 'This Month',
            value: _formatMeters(monthMeters),
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            label: 'Workouts',
            value: '$totalWorkouts',
            icon: Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            label: 'Streak',
            value: '${streak}d',
            icon: Icons.local_fire_department,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return BoathouseStyles.card(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ERG PERSONAL RECORDS
  // ════════════════════════════════════════════════════════════

  Widget _buildErgPRs(List<WorkoutResult> ergResults) {
    // Standard PR distances in rowing
    final prDistances = [500, 1000, 2000, 5000, 6000, 10000];
    final prs = <_ErgPR>[];

    for (final dist in prDistances) {
      final matching = ergResults.where((r) {
        // Check single-piece results matching this distance
        if (r.ergIntervals != null && r.ergIntervals!.length == 1) {
          return r.ergIntervals!.first.distance == dist;
        }
        // Also check total distance for single-piece workouts
        return r.calculatedErgTotalDistance == dist &&
            (r.ergIntervals == null || r.ergIntervals!.length == 1);
      }).toList();

      if (matching.isNotEmpty) {
        // Find the best (lowest) split
        matching.sort(
          (a, b) => a.calculatedErgAvgSplitPer500Ms.compareTo(
            b.calculatedErgAvgSplitPer500Ms,
          ),
        );
        final best = matching.first;
        prs.add(
          _ErgPR(
            distance: dist,
            timeMs: best.calculatedErgTotalTimeMs,
            splitMs: best.calculatedErgAvgSplitPer500Ms,
            date: best.createdAt,
          ),
        );
      }
    }

    if (prs.isEmpty) {
      return BoathouseStyles.card(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 32,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                'No erg PRs yet',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete single-distance erg workouts to see PRs here',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return BoathouseStyles.card(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        children: prs.asMap().entries.map((entry) {
          final i = entry.key;
          final pr = entry.value;
          return Column(
            children: [
              _buildPRRow(pr),
              if (i < prs.length - 1)
                Divider(height: 1, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPRRow(_ErgPR pr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Distance label
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatDistanceLabel(pr.distance),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),

          // Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WorkoutResult.formatTime(pr.timeMs),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${WorkoutResult.formatSplit(pr.splitMs)} /500m',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // Date
          Text(
            _formatDate(pr.date),
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // RECENT ACTIVITY
  // ════════════════════════════════════════════════════════════

  Widget _buildRecentActivity(List<WorkoutResult> results) {
    // Show most recent 5
    final recent = results.take(5).toList();

    return BoathouseStyles.card(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        children: recent.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return Column(
            children: [
              _buildActivityRow(r),
              if (i < recent.length - 1)
                Divider(height: 1, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityRow(WorkoutResult result) {
    final icon = _categoryIcon(result.category);
    final title = _categoryLabel(result.category);
    final subtitle = _activitySubtitle(result);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Text(
            _formatDate(result.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return BoathouseStyles.card(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.rowing, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No workouts yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your erg PRs, lifetime meters, and activity will show up here once you start logging workouts.',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ════════════════════════════════════════════════════════════

  Widget _buildRoleBadge(Membership membership) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getRoleColor(membership.role),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        membership.customTitle ?? membership.role.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════

  int _calculateStreak(List<WorkoutResult> results) {
    if (results.isEmpty) return 0;

    // Sort by date descending
    final sorted = List<WorkoutResult>.from(results)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Get unique workout dates
    final dates =
        sorted
            .map(
              (r) => DateTime(
                r.createdAt.year,
                r.createdAt.month,
                r.createdAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Streak must include today or yesterday
    final diff = today.difference(dates.first).inDays;
    if (diff > 1) return 0;

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i - 1].difference(dates[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _formatMeters(int meters) {
    if (meters >= 1000000) {
      return '${(meters / 1000000).toStringAsFixed(1)}M';
    } else if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}k';
    }
    return '$meters';
  }

  String _formatDistanceLabel(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return km == km.roundToDouble()
          ? '${km.toInt()}k'
          : '${km.toStringAsFixed(1)}k';
    }
    return '${meters}m';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _sideLabel(String side) {
    switch (side) {
      case 'port':
        return 'Port';
      case 'starboard':
        return 'Starboard';
      case 'both':
        return 'Both';
      default:
        return side;
    }
  }

  String _shortWeightClass(String wc) {
    if (wc.contains('Lightweight')) return 'Ltwt';
    if (wc.contains('Heavyweight')) return 'Hwt';
    if (wc.contains('Openweight')) return 'Open';
    return wc;
  }

  IconData _categoryIcon(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.erg:
        return Icons.rowing;
      case WorkoutCategory.water:
        return Icons.water;
      case WorkoutCategory.lift:
        return Icons.fitness_center;
      case WorkoutCategory.circuit:
        return Icons.loop;
      case WorkoutCategory.race:
        return Icons.emoji_events;
    }
  }

  String _categoryLabel(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.erg:
        return 'Erg Workout';
      case WorkoutCategory.water:
        return 'Water Workout';
      case WorkoutCategory.lift:
        return 'Lift';
      case WorkoutCategory.circuit:
        return 'Circuit';
      case WorkoutCategory.race:
        return 'Race';
    }
  }

  String _activitySubtitle(WorkoutResult r) {
    switch (r.category) {
      case WorkoutCategory.erg:
        final dist = r.calculatedErgTotalDistance;
        final split = r.calculatedErgAvgSplitPer500Ms;
        if (dist > 0 && split > 0) {
          return '${_formatMeters(dist)}m · ${WorkoutResult.formatSplit(split)} /500m';
        }
        if (dist > 0) return '${_formatMeters(dist)}m';
        return '';
      case WorkoutCategory.water:
        final dist = r.waterTotalDistance;
        return dist != null ? '${_formatMeters(dist)}m' : '';
      case WorkoutCategory.lift:
        final count = r.liftResults?.length ?? 0;
        return count > 0 ? '$count exercises' : '';
      case WorkoutCategory.circuit:
        final rounds = r.circuitRoundsCompleted;
        return rounds != null ? '$rounds rounds' : '';
      case WorkoutCategory.race:
        final time = r.raceTimeMs;
        return time != null ? WorkoutResult.formatTime(time) : '';
    }
  }

  Color _getRoleColor(MembershipRole role) {
    switch (role) {
      case MembershipRole.admin:
        return Colors.deepPurple;
      case MembershipRole.coach:
        return Colors.purple;
      case MembershipRole.coxswain:
        return Colors.orange;
      case MembershipRole.rower:
        return Colors.blue;
      case MembershipRole.boatman:
        return Colors.brown;
      case MembershipRole.athlete:
        return Colors.teal;
    }
  }
}

// ════════════════════════════════════════════════════════════
// DATA CLASS
// ════════════════════════════════════════════════════════════

class _ErgPR {
  final int distance;
  final int timeMs;
  final int splitMs;
  final DateTime date;

  _ErgPR({
    required this.distance,
    required this.timeMs,
    required this.splitMs,
    required this.date,
  });
}
