import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';

class ChatTab extends StatelessWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization? organization;
  final Team? team;

  const ChatTab({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Team Chat',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Messaging coming soon!',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
