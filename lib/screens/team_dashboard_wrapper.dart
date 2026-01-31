import 'package:flutter/material.dart';
import '../services/team_service.dart';
import '../models/team.dart';
import 'dashboard_screen.dart';

class TeamDashboardWrapper extends StatelessWidget {
  final String teamId;

  const TeamDashboardWrapper({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final teamService = TeamService();

    return FutureBuilder<Team?>(
      future: teamService.getTeam(teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Pass the team to the dashboard even if user isn't assigned to it
        // The dashboard will use the admin membership
        return const DashboardScreen();
      },
    );
  }
}
