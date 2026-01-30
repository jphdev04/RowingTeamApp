import 'package:flutter/material.dart';
import '../models/team.dart';

class TeamHeader extends StatelessWidget {
  final Team? team;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const TeamHeader({
    super.key,
    this.team,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = team?.primaryColorObj ?? const Color(0xFF1976D2);
    final secondaryColor = team?.secondaryColorObj ?? const Color(0xFFFFFFFF);

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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (actions != null)
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
            if (team != null) ...[
              Text(
                team!.name,
                style: TextStyle(
                  color: primaryColor.computeLuminance() > 0.5
                      ? Colors.black54
                      : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              title,
              style: TextStyle(
                color: primaryColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  color: primaryColor.computeLuminance() > 0.5
                      ? Colors.black54
                      : Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
