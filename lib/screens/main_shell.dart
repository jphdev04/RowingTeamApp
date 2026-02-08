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
import 'team_selector_screen.dart';

class MainShell extends StatefulWidget {
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

  /// Drives the header animation without rebuilding the whole tree.
  /// 0.0 = expanded (Home), 1.0 = compact (other tabs)
  final ValueNotifier<double> _collapseNotifier = ValueNotifier(0.0);

  // Cached data
  AppUser? _user;
  List<Membership> _memberships = [];
  Membership? _currentMembership;
  Organization? _organization;
  Team? _team;
  bool _dataReady = false;

  static const _tabTitles = ['Home', 'Calendar', 'Chat', 'Workouts', 'Profile'];
  static const _tabSubtitles = [
    '',
    'Schedule & events',
    'Team messaging',
    'Track & assign',
    'Your account',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _collapseNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? 0.0;
    // Only the header listens to this — no setState needed
    _collapseNotifier.value = page.clamp(0.0, 1.0);
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
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ── Persistent animated header (only this repaints on swipe) ──
          ValueListenableBuilder<double>(
            valueListenable: _collapseNotifier,
            builder: (context, collapse, _) {
              return _AnimatedHeader(
                collapse: collapse,
                currentIndex: _currentIndex,
                user: _user!,
                memberships: _memberships,
                currentMembership: _currentMembership!,
                organization: _organization,
                team: _team,
                tabTitles: _tabTitles,
                tabSubtitles: _tabSubtitles,
              );
            },
          ),
          // ── Tab content (not rebuilt during swipe animation) ──
          Expanded(
            child: PageView(
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

// ─────────────────────────────────────────────────────────────────
// Animated header — only this widget rebuilds during swipe
// ─────────────────────────────────────────────────────────────────

class _AnimatedHeader extends StatelessWidget {
  final double collapse;
  final int currentIndex;
  final AppUser user;
  final List<Membership> memberships;
  final Membership currentMembership;
  final Organization? organization;
  final Team? team;
  final List<String> tabTitles;
  final List<String> tabSubtitles;

  const _AnimatedHeader({
    required this.collapse,
    required this.currentIndex,
    required this.user,
    required this.memberships,
    required this.currentMembership,
    required this.organization,
    required this.team,
    required this.tabTitles,
    required this.tabSubtitles,
  });

  // ── Expanded height: 230, Compact height: 100 ──
  static const _expandedHeight = 230.0;
  static const _compactHeight = 150.0;

  MembershipRole get role => currentMembership.role;

  Color get primaryColor =>
      team?.primaryColorObj ??
      organization?.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get secondaryColor =>
      team?.secondaryColorObj ??
      organization?.secondaryColorObj ??
      const Color(0xFFFFFFFF);

  Color get _textColor =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  Color get _subtextColor =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

  String get _roleDisplayName {
    if (currentMembership.customTitle != null) {
      return currentMembership.customTitle!;
    }
    switch (role) {
      case MembershipRole.coach:
        return 'Coach ${user.name}';
      case MembershipRole.admin:
        return 'Admin ${user.name}';
      case MembershipRole.boatman:
        return 'Boatman ${user.name}';
      default:
        return user.name;
    }
  }

  String get _viewLabel {
    switch (role) {
      case MembershipRole.admin:
        if (team != null) return 'Admin → ${team!.name}';
        return 'Organization View';
      case MembershipRole.coach:
        return 'Coach View';
      case MembershipRole.boatman:
        return 'Boatman View';
      case MembershipRole.rower:
        return 'Rower';
      case MembershipRole.coxswain:
        return 'Coxswain';
      case MembershipRole.athlete:
        return 'Athlete';
    }
  }

  String get _compactTitle {
    if (currentIndex == 0) return 'Home';
    return tabTitles[currentIndex];
  }

  String get _compactSubtitle {
    if (currentIndex == 0) return '';
    return tabSubtitles[currentIndex];
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final contentHeight = _lerpDouble(
      _expandedHeight,
      _compactHeight,
      collapse,
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // No rounded corners — flat bar
      ),
      child: SizedBox(
        height: contentHeight,
        child: Stack(
          children: [
            // ── Expanded content (Home) ──
            Opacity(
              opacity: (1.0 - collapse).clamp(0.0, 1.0),
              child: IgnorePointer(
                ignoring: collapse > 0.5,
                child: _buildExpandedContent(context),
              ),
            ),
            // ── Compact content (other tabs) ──
            Opacity(
              opacity: collapse.clamp(0.0, 1.0),
              child: IgnorePointer(
                ignoring: collapse < 0.5,
                child: _buildCompactContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopRow(context),
        const SizedBox(height: 8),
        Center(
          child: Icon(
            Icons.house_outlined,
            size: 48,
            color: _textColor.withOpacity(0.25),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Welcome back,',
          style: TextStyle(color: _subtextColor, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          _roleDisplayName,
          style: TextStyle(
            color: _textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (team != null) ...[
          const SizedBox(height: 4),
          Text(
            team!.name,
            style: TextStyle(
              color: _subtextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (organization != null) ...[
          const SizedBox(height: 2),
          Text(
            organization!.name,
            style: TextStyle(color: _textColor.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactContent(BuildContext context) {
    return Column(
      children: [
        _buildTopRow(context),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _compactTitle,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_compactSubtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _compactSubtitle,
                      style: TextStyle(color: _subtextColor, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (team != null)
                  Text(
                    team!.name,
                    style: TextStyle(
                      color: _subtextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (organization != null)
                  Text(
                    organization!.name,
                    style: TextStyle(
                      color: _textColor.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (memberships.length > 1 || role == MembershipRole.admin)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      TeamSelectorScreen(user: user, memberships: memberships),
                ),
              );
            },
            icon: Icon(Icons.swap_horiz, color: _textColor, size: 20),
            label: Text(
              'Switch',
              style: TextStyle(color: _textColor, fontSize: 13),
            ),
          )
        else
          const SizedBox(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _textColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _viewLabel,
            style: TextStyle(
              color: _textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
