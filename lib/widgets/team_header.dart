import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/organization.dart';

class TeamHeader extends StatelessWidget {
  final Team? team;
  final Organization? organization;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  const TeamHeader({
    super.key,
    this.team,
    this.organization,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        team?.primaryColorObj ??
        organization?.primaryColorObj ??
        const Color(0xFF1976D2);
    final secondaryColor =
        team?.secondaryColorObj ??
        organization?.secondaryColorObj ??
        const Color(0xFFFFFFFF);
    final textColor = primaryColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    final subtextColor = primaryColor.computeLuminance() > 0.5
        ? Colors.black54
        : Colors.white70;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 8,
        20,
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // No rounded corners — flat bar
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: leading + actions
            Row(
              children: [
                if (leading != null) leading!,
                const Spacer(),
                if (actions != null) ...actions!,
              ],
            ),
            if (team != null) ...[
              Text(
                team!.name,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (organization != null && team == null) ...[
              Text(
                organization!.name,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(color: subtextColor, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
