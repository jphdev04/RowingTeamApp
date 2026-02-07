import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/membership_service.dart';
import '../services/organization_service.dart';
import '../services/team_service.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import 'home_tab.dart';
import 'calendar_tab.dart';
import 'chat_tab.dart';
import 'workouts_tab.dart';
import 'profile_tab.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class MainShell extends StatefulWidget {
  /// Optional team ID override — used when an admin selects a specific team
  /// from the team selector. If null, uses the membership's teamId.
  final String? teamOverrideId;

  const MainShell({super.key, this.teamOverrideId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _authService = AuthService();
  final _userService = UserService();
  final _membershipService = MembershipService();
  final _orgService = OrganizationService();
  final _teamService = TeamService();

  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Cached data
  AppUser? _user;
  List<Membership> _memberships = [];
  Membership? _currentMembership;
  Organization? _organization;
  Team? _team;
  bool _dataReady = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<AppUser?>(
      stream: _userService.getUserStream(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting &&
            _user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = userSnapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Error loading user')),
          );
        }
        _user = user;

        return StreamBuilder<List<Membership>>(
          stream: _membershipService.getUserMemberships(userId),
          builder: (context, membershipsSnapshot) {
            if (membershipsSnapshot.connectionState ==
                    ConnectionState.waiting &&
                _memberships.isEmpty) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final memberships = membershipsSnapshot.data ?? [];
            _memberships = memberships;

            if (memberships.isEmpty) {
              return _buildEmptyState(context, user);
            }

            // Resolve current membership
            Membership currentMembership;
            if (user.currentMembershipId != null) {
              currentMembership = memberships.firstWhere(
                (m) => m.id == user.currentMembershipId,
                orElse: () => memberships.first,
              );
            } else {
              currentMembership = memberships.first;
            }
            _currentMembership = currentMembership;

            return FutureBuilder<Organization?>(
              future: _orgService.getOrganization(
                currentMembership.organizationId,
              ),
              builder: (context, orgSnapshot) {
                if (orgSnapshot.connectionState == ConnectionState.waiting &&
                    _organization == null) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (orgSnapshot.data != null) {
                  _organization = orgSnapshot.data;
                }

                // Use teamOverrideId first, then fall back to membership's teamId
                final teamId =
                    widget.teamOverrideId ?? currentMembership.teamId;

                if (teamId != null) {
                  return FutureBuilder<Team?>(
                    future: _teamService.getTeam(teamId),
                    builder: (context, teamSnapshot) {
                      if (teamSnapshot.data != null) {
                        _team = teamSnapshot.data;
                      }
                      _dataReady = true;
                      return _buildShell();
                    },
                  );
                }

                _team = null;
                _dataReady = true;
                return _buildShell();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildShell() {
    if (!_dataReady || _user == null || _currentMembership == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final primaryColor =
        _team?.primaryColorObj ??
        _organization?.primaryColorObj ??
        const Color(0xFF1976D2);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          HomeTab(
            user: _user!,
            memberships: _memberships,
            currentMembership: _currentMembership!,
            organization: _organization,
            team: _team,
          ),
          CalendarTab(
            user: _user!,
            currentMembership: _currentMembership!,
            organization: _organization,
            team: _team,
          ),
          ChatTab(
            user: _user!,
            currentMembership: _currentMembership!,
            organization: _organization,
            team: _team,
          ),
          WorkoutsTab(
            user: _user!,
            currentMembership: _currentMembership!,
            organization: _organization,
            team: _team,
          ),
          ProfileTab(
            user: _user!,
            memberships: _memberships,
            currentMembership: _currentMembership!,
            organization: _organization,
            team: _team,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppUser user) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () => _showSignOutDialog(context),
                  icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.house_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Welcome to The Boathouse',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'You haven\'t joined any organizations yet.\nGet started by joining or creating one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OnboardingScreen(user: user),
                      ),
                    );
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text(
                    'Join or Create an Organization',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await _authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
