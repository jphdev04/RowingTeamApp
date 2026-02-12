import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/workout_template.dart';
import '../services/workout_service.dart';
import '../widgets/team_header.dart';
import 'create_erg_workout_screen.dart';
import 'create_water_workout_screen.dart';

/// Browse Templates Screen — shown before the create form so coaches
/// can pick an existing template to pre-fill the form, or start fresh.
///
/// Flow: Workouts Tab → Create Workout → Category (Erg) → Browse Templates →
///       either pick a template → Create Erg (pre-filled)
///       or tap "Start Fresh" → Create Erg (empty)
class BrowseTemplatesScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final WorkoutCategory category;

  /// Optional: pre-linked calendar event when creating from calendar detail
  final dynamic preLinkedEvent; // CalendarEvent?

  const BrowseTemplatesScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    required this.category,
    this.preLinkedEvent,
  });

  @override
  State<BrowseTemplatesScreen> createState() => _BrowseTemplatesScreenState();
}

class _BrowseTemplatesScreenState extends State<BrowseTemplatesScreen> {
  final WorkoutService _workoutService = WorkoutService();
  String _searchQuery = '';
  bool _showBenchmarksOnly = false;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  String get _categoryLabel {
    switch (widget.category) {
      case WorkoutCategory.erg:
        return 'Erg';
      case WorkoutCategory.water:
        return 'Water';
      case WorkoutCategory.race:
        return 'Race';
      case WorkoutCategory.lift:
        return 'Lift';
      case WorkoutCategory.circuit:
        return 'Circuit';
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
            title: '$_categoryLabel Workouts',
            subtitle: 'Choose a template or start fresh',
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                // ── Start Fresh button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToCreate(null),
                      icon: Icon(Icons.add, color: primaryColor),
                      label: Text(
                        'Create New ${_categoryLabel} Workout',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Divider with label ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR USE A SAVED TEMPLATE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Search + Filter ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: _buildSearchField()),
                      const SizedBox(width: 10),
                      _buildBenchmarkFilter(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Template List ──
                Expanded(child: _buildTemplateList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search templates...',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildBenchmarkFilter() {
    return GestureDetector(
      onTap: () => setState(() => _showBenchmarksOnly = !_showBenchmarksOnly),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _showBenchmarksOnly ? Colors.amber.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showBenchmarksOnly
                ? Colors.amber.shade400
                : Colors.grey.shade300,
            width: _showBenchmarksOnly ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 18,
              color: _showBenchmarksOnly
                  ? Colors.amber.shade700
                  : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Text(
              'Tests',
              style: TextStyle(
                fontSize: 13,
                fontWeight: _showBenchmarksOnly
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: _showBenchmarksOnly
                    ? Colors.amber.shade700
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateList() {
    // Stream templates filtered by category for this team
    return StreamBuilder<List<WorkoutTemplate>>(
      stream: widget.team != null
          ? _workoutService.getTeamTemplates(
              widget.organization.id,
              widget.team!.id,
            )
          : _workoutService.getOrgTemplates(widget.organization.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading templates',
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }

        var templates = (snapshot.data ?? [])
            .where((t) => t.category == widget.category)
            .toList();

        // Apply filters
        if (_showBenchmarksOnly) {
          templates = templates.where((t) => t.isBenchmark).toList();
        }
        if (_searchQuery.isNotEmpty) {
          templates = templates
              .where((t) => t.name.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (templates.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: templates.length,
          itemBuilder: (context, i) => _buildTemplateCard(templates[i]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _showBenchmarksOnly
                ? 'No benchmark templates yet'
                : _searchQuery.isNotEmpty
                ? 'No templates match "$_searchQuery"'
                : 'No saved templates yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first ${_categoryLabel.toLowerCase()} workout above',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(WorkoutTemplate template) {
    final spec = _buildSpecLabel(template);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _navigateToCreate(template),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(template.category),
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Name + spec
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (template.isBenchmark) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Text(
                              'TEST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spec.isNotEmpty ? spec : 'Erg workout',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last used ${dateFormat.format(template.updatedAt)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              // More menu (use template / delete)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'use') {
                    _navigateToCreate(template);
                  } else if (value == 'delete') {
                    _confirmDeleteTemplate(template);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'use',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('Use Template'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        const SizedBox(width: 10),
                        const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTemplate(WorkoutTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Delete "${template.name}"? This won\'t affect any workouts '
          'already created from this template.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _workoutService.deleteTemplate(
          widget.organization.id,
          template.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${template.name}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting template: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _buildSpecLabel(WorkoutTemplate template) {
    if (template.category != WorkoutCategory.erg) return '';

    switch (template.ergType) {
      case ErgType.single:
        if (template.targetDistance != null) {
          return '${template.targetDistance}m';
        }
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
          return template.variableIntervals!
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
        }
        return 'Variable intervals';

      default:
        return '';
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

  // ═══════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════

  void _navigateToCreate(WorkoutTemplate? fromTemplate) {
    Widget screen;

    switch (widget.category) {
      case WorkoutCategory.erg:
        screen = CreateErgWorkoutScreen(
          user: widget.user,
          currentMembership: widget.currentMembership,
          organization: widget.organization,
          team: widget.team,
          fromTemplate: fromTemplate,
          preLinkedEvent: widget.preLinkedEvent,
        );
        break;
      case WorkoutCategory.water:
        screen = CreateWaterWorkoutScreen(
          user: widget.user,
          currentMembership: widget.currentMembership,
          organization: widget.organization,
          team: widget.team,
          fromTemplate: fromTemplate,
          preLinkedEvent: widget.preLinkedEvent,
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_categoryLabel workouts coming soon!')),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }
}
