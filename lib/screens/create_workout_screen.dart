import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/workout_template.dart';
import '../widgets/team_header.dart';
import 'create_erg_workout_screen.dart';
import 'browse_templates_screen.dart';
import 'create_water_workout_screen.dart';

class CreateWorkoutScreen extends StatelessWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final dynamic preLinkedEvent;

  const CreateWorkoutScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    this.preLinkedEvent,
  });

  Color get primaryColor =>
      team?.primaryColorObj ??
      organization.primaryColorObj ??
      const Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TeamHeader(
            team: team,
            organization: organization,
            title: 'Create Workout',
            subtitle: team?.name ?? organization.name,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: primaryColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'What type of workout?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a category to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // ── Category cards ──
                _CategoryCard(
                  title: 'Erg Workout',
                  subtitle:
                      'Single piece, standard intervals, or variable intervals',
                  icon: Icons.monitor_heart_rounded,
                  color: Colors.red[700]!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BrowseTemplatesScreen(
                        user: user,
                        currentMembership: currentMembership,
                        organization: organization,
                        team: team,
                        category: WorkoutCategory.erg,
                        preLinkedEvent: preLinkedEvent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _CategoryCard(
                  title: 'Water Workout',
                  subtitle: 'Steady state, interval work, or seat racing',
                  icon: Icons.rowing,
                  color: Colors.blue[700]!,
                  onTap: () =>
                      _navigateToCategory(context, WorkoutCategory.water),
                ),
                const SizedBox(height: 12),
                _CategoryCard(
                  title: 'Race',
                  subtitle: 'Head race, sprint, or dual',
                  icon: Icons.emoji_events,
                  color: Colors.amber[800]!,
                  onTap: () =>
                      _navigateToCategory(context, WorkoutCategory.race),
                ),
                const SizedBox(height: 12),
                _CategoryCard(
                  title: 'Lift',
                  subtitle: 'Exercises with sets, reps, and optional weight',
                  icon: Icons.fitness_center,
                  color: Colors.green[700]!,
                  onTap: () =>
                      _navigateToCategory(context, WorkoutCategory.lift),
                ),
                const SizedBox(height: 12),
                _CategoryCard(
                  title: 'Circuit',
                  subtitle: 'Timed stations or rep-based rounds',
                  icon: Icons.timer,
                  color: Colors.orange[700]!,
                  onTap: () =>
                      _navigateToCategory(context, WorkoutCategory.circuit),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCategory(BuildContext context, WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.erg:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateErgWorkoutScreen(
              user: user,
              currentMembership: currentMembership,
              organization: organization,
              team: team,
            ),
          ),
        );
        break;
      case WorkoutCategory.water:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateWaterWorkoutScreen(
              user: user,
              currentMembership: currentMembership,
              organization: organization,
              team: team,
            ),
          ),
        );
        break;
      case WorkoutCategory.race:
      case WorkoutCategory.lift:
      case WorkoutCategory.circuit:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category.name[0].toUpperCase()}${category.name.substring(1)} workout creation coming soon!',
            ),
          ),
        );
        break;
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
