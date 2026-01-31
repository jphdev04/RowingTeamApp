import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'models/user.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/membership_service.dart';
import 'models/membership.dart';
import 'screens/team_selector_screen.dart';
import 'screens/organization_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Boathouse',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: GoogleFonts.instrumentSansTextTheme(
          Theme.of(context).textTheme,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.instrumentSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userService = UserService();
    final membershipService = MembershipService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasData) {
          final userId = authSnapshot.data!.uid;

          return FutureBuilder(
            future: userService.getUser(userId),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final user = userSnapshot.data;

              if (user == null) {
                return const LoginScreen();
              }

              // Check if user has joined any organizations
              if (user.currentOrganizationId == null) {
                return OnboardingScreen(user: user);
              }

              // User has memberships - check how many
              return StreamBuilder<List<Membership>>(
                stream: membershipService.getUserMemberships(userId),
                builder: (context, membershipsSnapshot) {
                  if (membershipsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final memberships = membershipsSnapshot.data ?? [];

                  if (memberships.isEmpty) {
                    // No memberships (shouldn't happen, but handle it)
                    return OnboardingScreen(user: user);
                  }

                  // Find current membership
                  final currentMembership = memberships.firstWhere(
                    (m) => m.id == user.currentMembershipId,
                    orElse: () => memberships.first,
                  );

                  // Check if this is an admin with no team (organization view)
                  if (currentMembership.role == MembershipRole.admin &&
                      currentMembership.teamId == null) {
                    return const OrganizationDashboardScreen();
                  }

                  // Regular team view
                  return const DashboardScreen();
                },
              );
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
