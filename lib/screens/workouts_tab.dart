import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../widgets/team_header.dart';

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

  bool get isCoach =>
      currentMembership.role == MembershipRole.coach ||
      currentMembership.role == MembershipRole.admin;

  bool get isCoxswain => currentMembership.role == MembershipRole.coxswain;

  String get _subtitle {
    if (isCoach) return 'Assign and track team workouts';
    if (isCoxswain) return 'Log erg workouts';
    return 'Track your workouts';
  }

  String get _placeholderText {
    if (isCoach) return 'Workout management coming soon!';
    if (isCoxswain) return 'Erg workout logging coming soon!';
    return 'Concept2 connection and workout tracking coming soon!';
  }

  IconData get _placeholderIcon {
    if (isCoxswain) return Icons.timer;
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          TeamHeader(
            team: team,
            organization: team == null ? organization : null,
            title: 'Workouts',
            subtitle: _subtitle,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_placeholderIcon, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Workouts',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _placeholderText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
