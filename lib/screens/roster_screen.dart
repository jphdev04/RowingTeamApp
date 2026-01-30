import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/athlete_service.dart';
import '../models/athlete.dart';
import 'login_screen.dart';
import 'add_athlete_screen.dart';
import 'athlete_detail_screen.dart';

class RosterScreen extends StatelessWidget {
  final String teamId;

  const RosterScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final athleteService = AthleteService();

    return Scaffold(
      appBar: AppBar(title: const Text('Team Roster')),
      body: StreamBuilder<List<Athlete>>(
        stream: athleteService.getAthletesByTeam(teamId), // Filter by team
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final athletes = snapshot.data ?? [];

          if (athletes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No athletes yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first athlete',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: athletes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final athlete = athletes[index];
              return _AthleteCard(athlete: athlete);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddAthleteScreen(teamId: teamId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AthleteCard extends StatelessWidget {
  final Athlete athlete;

  const _AthleteCard({required this.athlete});

  Color _getSideColor(String? side) {
    if (side == null) return Colors.transparent;
    switch (side.toLowerCase()) {
      case 'port':
        return Colors.red;
      case 'starboard':
        return Colors.green;
      case 'both':
        return Colors.purple;
      default:
        return Colors.transparent;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'coach':
        return Colors.purple;
      case 'coxswain':
        return Colors.orange;
      case 'rower':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRower = athlete.role == 'rower';
    final Color sideColor = _getSideColor(athlete.side);
    final bool showSideBadge = isRower && athlete.side != null;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AthleteDetailScreen(athlete: athlete),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: athlete.isInjured ? Colors.red : Colors.black,
            width: athlete.isInjured ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: athlete.isInjured ? Colors.red[50] : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Name and role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(athlete.role),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            athlete.role.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (showSideBadge) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: sideColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              athlete.side!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Injury indicator or chevron
              if (athlete.isInjured)
                const Column(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 28),
                    SizedBox(height: 2),
                    Text(
                      'INJURED',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
