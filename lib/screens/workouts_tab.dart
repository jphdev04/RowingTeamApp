import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../widgets/dashboard_card.dart';
import 'create_workout_screen.dart';

class WorkoutsTab extends StatelessWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization? organization;
  final Team? team;

  const WorkoutsTab({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
  });

  MembershipRole get role => currentMembership.role;

  Color get primaryColor =>
      team?.primaryColorObj ??
      organization?.primaryColorObj ??
      const Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        ..._buildCardsForRole(context),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildCardsForRole(BuildContext context) {
    switch (role) {
      case MembershipRole.admin:
        // Admin viewing a specific team → show coach cards
        // Admin in org view (no team) → show admin cards
        if (team != null) {
          return _buildCoachCards(context);
        }
        return _buildAdminOrgCards(context);
      case MembershipRole.coach:
        return _buildCoachCards(context);
      case MembershipRole.coxswain:
        return _buildCoxswainCards(context);
      case MembershipRole.rower:
        return _buildRowerCards(context);
      case MembershipRole.athlete:
        return _buildAthleteCards(context);
      case MembershipRole.boatman:
        return _buildBoatmanCards(context);
    }
  }

  // ── Admin in Org View (no team selected) ────────────────────

  List<Widget> _buildAdminOrgCards(BuildContext context) {
    return [
      Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Switch to a specific team to create or manage team workouts.',
                    style: TextStyle(color: Colors.blue[800], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      _cardRow(
        DashboardCard(
          title: 'View Results',
          subtitle: 'All teams',
          icon: Icons.bar_chart,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Org-wide results'),
        ),
        DashboardCard(
          title: 'Benchmarks',
          subtitle: 'Test history',
          icon: Icons.trending_up,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Benchmark tracking'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Personal Log',
          subtitle: 'Your workouts',
          icon: Icons.person_outline,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Personal workout log'),
        ),
        null,
      ),
    ];
  }

  // ── Coach / Admin viewing team ─────────────────────────────

  List<Widget> _buildCoachCards(BuildContext context) {
    return [
      _cardRow(
        DashboardCard(
          title: 'Create Workout',
          subtitle: 'New team workout',
          icon: Icons.add_circle_outline,
          color: primaryColor,
          onTap: () {
            if (organization != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateWorkoutScreen(
                    user: user,
                    currentMembership: currentMembership,
                    organization: organization!,
                    team: team,
                  ),
                ),
              );
            }
          },
        ),
        DashboardCard(
          title: 'Team Workouts',
          subtitle: 'View & manage',
          icon: Icons.list_alt,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Team workout list'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'View Results',
          subtitle: 'Team performance',
          icon: Icons.bar_chart,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Results viewer'),
        ),
        DashboardCard(
          title: 'Benchmarks',
          subtitle: 'Test history',
          icon: Icons.trending_up,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Benchmark tracking'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Personal Log',
          subtitle: 'Your workouts',
          icon: Icons.person_outline,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Personal workout log'),
        ),
        null,
      ),
    ];
  }

  List<Widget> _buildCoxswainCards(BuildContext context) {
    return [
      _cardRow(
        DashboardCard(
          title: 'Log Workouts',
          subtitle: 'Enter team data',
          icon: Icons.edit_note,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Cox workout logging'),
        ),
        DashboardCard(
          title: 'Team Workouts',
          subtitle: "Today's schedule",
          icon: Icons.list_alt,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Team workout list'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'Personal Log',
          subtitle: 'Your erg workouts',
          icon: Icons.person_outline,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Personal workout log'),
        ),
        null,
      ),
    ];
  }

  List<Widget> _buildRowerCards(BuildContext context) {
    return [
      _cardRow(
        DashboardCard(
          title: 'Team Workouts',
          subtitle: "Today's schedule",
          icon: Icons.list_alt,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Team workout list'),
        ),
        DashboardCard(
          title: 'Log Results',
          subtitle: 'Enter your data',
          icon: Icons.edit_note,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Log erg results'),
        ),
      ),
      const SizedBox(height: 12),
      _cardRow(
        DashboardCard(
          title: 'My Results',
          subtitle: 'Your history',
          icon: Icons.bar_chart,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Personal results'),
        ),
        DashboardCard(
          title: 'Personal Log',
          subtitle: 'Private workouts',
          icon: Icons.person_outline,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Personal workout log'),
        ),
      ),
    ];
  }

  List<Widget> _buildAthleteCards(BuildContext context) {
    return [
      _cardRow(
        DashboardCard(
          title: 'Personal Log',
          subtitle: 'Track your workouts',
          icon: Icons.fitness_center,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Personal workout log'),
        ),
        DashboardCard(
          title: 'My Results',
          subtitle: 'Your history',
          icon: Icons.bar_chart,
          color: primaryColor,
          onTap: () => _comingSoon(context, 'Personal results'),
        ),
      ),
    ];
  }

  List<Widget> _buildBoatmanCards(BuildContext context) {
    return [
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.fitness_center, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Workout features are not available\nfor the boatman role.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _cardRow(DashboardCard first, DashboardCard? second) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        if (second != null)
          Expanded(child: second)
        else
          const Expanded(child: SizedBox()),
      ],
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon!')));
  }
}
