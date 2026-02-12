import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/equipment.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../services/workout_service.dart';
import '../services/membership_service.dart';
import '../services/user_service.dart';
import '../services/equipment_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';
import 'add_boat_to_lineup_screen.dart';
import 'rigging_editor_screen.dart';

class ManageLineupsScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final WorkoutSession session;

  const ManageLineupsScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    required this.session,
  });

  @override
  State<ManageLineupsScreen> createState() => _ManageLineupsScreenState();
}

class _ManageLineupsScreenState extends State<ManageLineupsScreen> {
  final _workoutService = WorkoutService();
  final _membershipService = MembershipService();
  final _userService = UserService();
  final _equipmentService = EquipmentService();

  late WorkoutSession _session;
  Map<String, String> _userNames = {};
  Map<String, String> _userSides = {}; // userId -> port/starboard/both
  Map<String, Equipment> _shellCache = {}; // shellId -> Equipment
  bool _isSaving = false;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  int _activePieceIndex = 0;

  List<PieceLineup> get _lineups =>
      _session.lineups ?? [PieceLineup(pieceNumber: 0, boats: [])];

  List<BoatLineup> get _activeBoats {
    if (_activePieceIndex < _lineups.length) {
      return _lineups[_activePieceIndex].boats;
    }
    return [];
  }

  int get _pieceCount {
    final spec = _session.workoutSpec;
    final count = spec['waterPieceCount'] as int?;
    if (count != null && count > 0) return count;
    final pieces = spec['waterPieces'] as List?;
    if (pieces != null && pieces.isNotEmpty) return pieces.length;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _loadUserNames();
  }

  Future<void> _loadUserNames() async {
    try {
      final Stream<List<Membership>> stream;
      if (widget.team?.id != null) {
        stream = _membershipService.getTeamMemberships(widget.team!.id);
      } else {
        stream = _membershipService.getOrganizationMemberships(
          widget.organization.id,
        );
      }
      final memberships = await stream.first;

      final names = <String, String>{};
      final sides = <String, String>{};
      for (final m in memberships) {
        if (!names.containsKey(m.userId)) {
          try {
            final user = await _userService.getUser(m.userId);
            names[m.userId] = user?.name ?? m.userId;
          } catch (_) {
            names[m.userId] = m.userId;
          }
        }
        if (m.side != null && m.side!.isNotEmpty) {
          sides[m.userId] = m.side!;
        }
      }

      if (mounted) {
        setState(() {
          _userNames = names;
          _userSides = sides;
        });
      }
    } catch (_) {}
  }

  String _userName(String userId) => _userNames[userId] ?? userId;
  String? _userSide(String userId) => _userSides[userId];

  /// Fetch and cache shell equipment data for rigging info.
  Future<Equipment?> _getShell(String shellId) async {
    if (shellId.isEmpty) return null;
    if (_shellCache.containsKey(shellId)) return _shellCache[shellId];
    try {
      final shell = await _equipmentService.getEquipment(shellId);
      if (shell != null) {
        _shellCache[shellId] = shell;
      }
      return shell;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TeamHeader(
            team: widget.team,
            organization: widget.team == null ? widget.organization : null,
            title: 'Lineups',
            subtitle: _session.name,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _onPrimary),
              onPressed: () => Navigator.pop(context, _session),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: BoathouseStyles.switchCard(
                    primaryColor: primaryColor,
                    switches: [
                      SwitchTileData(
                        title: 'Seat Race',
                        subtitle: 'Enable per-piece lineups for athlete swaps',
                        value: _session.isSeatRace,
                        onChanged: _toggleSeatRace,
                      ),
                    ],
                  ),
                ),
                if (_session.isSeatRace) ...[
                  const SizedBox(height: 12),
                  _buildPieceTabs(),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: _activeBoats.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _activeBoats.length,
                          itemBuilder: (context, i) =>
                              _buildBoatCard(_activeBoats[i], i),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: _onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Boat'),
        onPressed: _addBoat,
      ),
    );
  }

  Widget _buildPieceTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _lineups.length,
        itemBuilder: (context, i) {
          final isActive = i == _activePieceIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('Piece ${_lineups[i].pieceNumber}'),
              selected: isActive,
              selectedColor: primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isActive ? primaryColor : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _activePieceIndex = i),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rowing, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No boats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Boat" to start building your lineup.\n'
              'Pick a shell, assign oars, and seat your athletes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoatCard(BoatLineup boat, int index) {
    final seatCount = seatsForBoatClass(boat.boatClass);
    final hasCox = boatClassHasCox(boat.boatClass);
    final isSweep = !boatClassIsScull(boat.boatClass);
    final filledSeats = boat.seats.where((s) => s.userId.isNotEmpty).length;
    final isComplete =
        filledSeats == seatCount &&
        (!hasCox || (boat.coxswainId != null && boat.coxswainId!.isNotEmpty));

    return FutureBuilder<Equipment?>(
      future: _getShell(boat.shellId),
      builder: (context, shellSnapshot) {
        final shell = shellSnapshot.data;
        final rigging = shell?.effectiveRiggingSetup;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BoathouseStyles.card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        boat.boatClass,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        boat.boatName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      isComplete ? Icons.check_circle : Icons.warning_amber,
                      color: isComplete ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Boat'),
                        ),
                        if (isSweep && shell != null)
                          const PopupMenuItem(
                            value: 'rigging',
                            child: Text('Edit Rigging'),
                          ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      onSelected: (a) {
                        if (a == 'edit') _editBoat(index);
                        if (a == 'rigging' && shell != null) {
                          _editRigging(shell);
                        }
                        if (a == 'remove') _removeBoat(index);
                      },
                    ),
                  ],
                ),

                // Rigging summary (if sweep)
                if (isSweep && rigging != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.tune, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(
                        rigging.description,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 20),
                if (boat.oarAllocations.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.sports_hockey,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          boat.oarAllocations
                              .map((o) => '${o.oarSetName} (${o.quantityUsed})')
                              .join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (hasCox) ...[
                  _buildCrewRow(
                    'Cox',
                    boat.coxswainId != null && boat.coxswainId!.isNotEmpty
                        ? _userName(boat.coxswainId!)
                        : null,
                    Icons.headset_mic,
                    riggerSide: null,
                    athleteSide: null,
                  ),
                  const SizedBox(height: 4),
                ],
                ...List.generate(seatCount, (seatIdx) {
                  final seatNum = seatCount - seatIdx;
                  final assignment = boat.seats.firstWhere(
                    (s) => s.seat == seatNum,
                    orElse: () => SeatAssignment(seat: seatNum, userId: ''),
                  );
                  final label = seatNum == seatCount
                      ? 'Stroke'
                      : seatNum == 1
                      ? 'Bow'
                      : 'Seat $seatNum';

                  // Get rigger side for this seat
                  RiggerSide? riggerSide;
                  if (isSweep && rigging != null) {
                    final rigPos = rigging.positions
                        .where((p) => p.seat == seatNum)
                        .toList();
                    if (rigPos.isNotEmpty) riggerSide = rigPos.first.side;
                  }

                  // Get athlete's preferred side
                  final athleteSide = assignment.userId.isNotEmpty
                      ? _userSide(assignment.userId)
                      : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _buildCrewRow(
                      label,
                      assignment.userId.isNotEmpty
                          ? _userName(assignment.userId)
                          : null,
                      Icons.person_outline,
                      riggerSide: riggerSide,
                      athleteSide: athleteSide,
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Text(
                  '$filledSeats/$seatCount seats filled',
                  style: TextStyle(
                    fontSize: 11,
                    color: isComplete ? Colors.green[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCrewRow(
    String label,
    String? name,
    IconData icon, {
    RiggerSide? riggerSide,
    String? athleteSide,
  }) {
    // Determine if there's a side mismatch
    bool hasMismatch = false;
    if (riggerSide != null && athleteSide != null && athleteSide != 'both') {
      final rigSideStr = riggerSide == RiggerSide.port ? 'port' : 'starboard';
      if (athleteSide != rigSideStr) {
        hasMismatch = true;
      }
    }

    return Row(
      children: [
        // Rigger side indicator
        if (riggerSide != null)
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: riggerSide == RiggerSide.port
                  ? Colors.red.withOpacity(0.12)
                  : Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: riggerSide == RiggerSide.port
                    ? Colors.red.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                riggerSide == RiggerSide.port ? 'P' : 'S',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: riggerSide == RiggerSide.port
                      ? Colors.red[700]
                      : Colors.green[700],
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 26),

        SizedBox(
          width: 54,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name ?? '—',
            style: TextStyle(
              fontSize: 13,
              color: name != null
                  ? (hasMismatch ? Colors.orange[700] : Colors.grey[800])
                  : Colors.grey[400],
              fontStyle: name != null ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),

        // Athlete side badge
        if (name != null && athleteSide != null && athleteSide.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: hasMismatch
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: hasMismatch
                  ? Border.all(color: Colors.orange.withOpacity(0.3))
                  : null,
            ),
            child: Text(
              athleteSide == 'both'
                  ? 'B'
                  : athleteSide.toUpperCase().substring(0, 1),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: hasMismatch ? Colors.orange[700] : Colors.grey[600],
              ),
            ),
          ),
        ],

        // Mismatch warning icon
        if (hasMismatch)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.warning_amber,
              size: 14,
              color: Colors.orange[600],
            ),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════

  void _toggleSeatRace(bool enabled) {
    setState(() {
      if (enabled) {
        final baseBoats = _activeBoats;
        final perPiece = List.generate(
          _pieceCount,
          (i) => PieceLineup(
            pieceNumber: i + 1,
            boats: baseBoats
                .map(
                  (b) => BoatLineup(
                    boatName: b.boatName,
                    boatClass: b.boatClass,
                    shellId: b.shellId,
                    oarAllocations: List.from(b.oarAllocations),
                    seats: b.seats.map((s) => s.copyWith()).toList(),
                    coxswainId: b.coxswainId,
                  ),
                )
                .toList(),
          ),
        );
        _session = _session.copyWith(isSeatRace: true, lineups: perPiece);
        _activePieceIndex = 0;
      } else {
        final firstBoats = _lineups.isNotEmpty
            ? _lineups.first.boats
            : <BoatLineup>[];
        _session = _session.copyWith(
          isSeatRace: false,
          lineups: [PieceLineup(pieceNumber: 0, boats: firstBoats)],
          seatRaceConfig: null,
        );
        _activePieceIndex = 0;
      }
    });
    _persistLineups();
  }

  Future<void> _addBoat() async {
    final result = await Navigator.push<BoatLineup>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBoatToLineupScreen(
          user: widget.user,
          currentMembership: widget.currentMembership,
          organization: widget.organization,
          team: widget.team,
          existingLineups: _lineups,
          activePieceIndex: _activePieceIndex,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        final lineups = List<PieceLineup>.from(_lineups);
        if (_activePieceIndex < lineups.length) {
          final boats = List<BoatLineup>.from(lineups[_activePieceIndex].boats)
            ..add(result);
          lineups[_activePieceIndex] = lineups[_activePieceIndex].copyWith(
            boats: boats,
          );
        } else {
          lineups.add(
            PieceLineup(
              pieceNumber: _session.isSeatRace ? _activePieceIndex + 1 : 0,
              boats: [result],
            ),
          );
        }
        _session = _session.copyWith(lineups: lineups);
      });
      _persistLineups();
    }
  }

  Future<void> _editBoat(int boatIndex) async {
    final result = await Navigator.push<BoatLineup>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBoatToLineupScreen(
          user: widget.user,
          currentMembership: widget.currentMembership,
          organization: widget.organization,
          team: widget.team,
          existingLineups: _lineups,
          activePieceIndex: _activePieceIndex,
          editingBoat: _activeBoats[boatIndex],
          editingBoatIndex: boatIndex,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        final lineups = List<PieceLineup>.from(_lineups);
        final boats = List<BoatLineup>.from(lineups[_activePieceIndex].boats);
        boats[boatIndex] = result;
        lineups[_activePieceIndex] = lineups[_activePieceIndex].copyWith(
          boats: boats,
        );
        _session = _session.copyWith(lineups: lineups);
      });
      _persistLineups();
    }
  }

  Future<void> _editRigging(Equipment shell) async {
    final updatedShell = await Navigator.push<Equipment>(
      context,
      MaterialPageRoute(
        builder: (_) => RiggingEditorScreen(
          user: widget.user,
          currentMembership: widget.currentMembership,
          organization: widget.organization,
          team: widget.team,
          shell: shell,
        ),
      ),
    );

    if (updatedShell != null) {
      // Update cache so the card rebuilds with new rigging
      setState(() {
        _shellCache[updatedShell.id] = updatedShell;
      });
    }
  }

  void _removeBoat(int boatIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Boat'),
        content: Text(
          'Remove "${_activeBoats[boatIndex].boatName}" from this lineup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final lineups = List<PieceLineup>.from(_lineups);
                final boats = List<BoatLineup>.from(
                  lineups[_activePieceIndex].boats,
                )..removeAt(boatIndex);
                lineups[_activePieceIndex] = lineups[_activePieceIndex]
                    .copyWith(boats: boats);
                _session = _session.copyWith(lineups: lineups);
              });
              _persistLineups();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _persistLineups() async {
    try {
      await _workoutService.updateSession(_session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving lineup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
