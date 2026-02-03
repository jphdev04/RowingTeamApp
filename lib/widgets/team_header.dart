import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/organization.dart';

class TeamHeader extends StatelessWidget {
  final Team? team;
  final Organization? organization;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  const TeamHeader({
    super.key,
    this.team,
    this.organization,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  Color get _primaryColor {
    if (team != null) return team!.primaryColorObj;
    if (organization != null) return organization!.primaryColorObj;
    return const Color(0xFF1976D2);
  }

  Color get _secondaryColor {
    if (team != null) return team!.secondaryColorObj;
    if (organization != null) return organization!.secondaryColorObj;
    return const Color(0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _primaryColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        32,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with leading (back button) and actions
          Row(
            children: [
              if (leading != null) leading! else const SizedBox(width: 48),
              const Spacer(),
              ...actions,
            ],
          ),
          const SizedBox(height: 16),

          // Icon
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }
}
