import 'package:flutter/material.dart';
import 'main_shell.dart';

/// Legacy redirect — all existing `DashboardScreen` references now land on `MainShell`.
/// Once you've updated all navigation calls, you can delete this file.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
