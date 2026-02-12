import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/equipment.dart';
import '../models/workout_session.dart';
import '../services/equipment_service.dart';
import '../services/membership_service.dart';
import '../services/user_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';

class AddBoatToLineupScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final List<PieceLineup> existingLineups;
  final int activePieceIndex;
  final BoatLineup? editingBoat;
  final int? editingBoatIndex;

  const AddBoatToLineupScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    required this.existingLineups,
    required this.activePieceIndex,
    this.editingBoat,
    this.editingBoatIndex,
  });

  @override
  State<AddBoatToLineupScreen> createState() => _AddBoatToLineupScreenState();
}

class _AddBoatToLineupScreenState extends State<AddBoatToLineupScreen> {
  final _equipmentService = EquipmentService();
  final _membershipService = MembershipService();
  final _userService = UserService();

  List<Equipment> _availableShells = [];
  List<Equipment> _availableOarSets = [];
  List<_TeamMember> _teamMembers = [];
  bool _isLoading = true;

  Equipment? _selectedShell;
  String _boatClass = '';
  List<OarAllocation> _oarAllocations = [];
  String? _coxswainId;
  late List<SeatAssignment> _seats;

  Set<String> _allocatedShellIds = {};
  Map<String, int> _allocatedOarCounts = {};
  Set<String> _allocatedAthleteIds = {};

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  bool get _isEditing => widget.editingBoat != null;

  /// Get the rigging setup for the selected shell.
  RiggingSetup? get _rigging {
    if (_selectedShell == null) return null;
    if (!_selectedShell!.isSweepConfig) return null;
    return _selectedShell!.effectiveRiggingSetup;
  }

  /// Get the rigger side for a specific seat number.
  RiggerSide? _riggerSideForSeat(int seatNum) {
    final rig = _rigging;
    if (rig == null) return null;
    final pos = rig.positions.where((p) => p.seat == seatNum).toList();
    return pos.isNotEmpty ? pos.first.side : null;
  }

  @override
  void initState() {
    super.initState();
    _computeAllocations();
    if (_isEditing) {
      final b = widget.editingBoat!;
      _boatClass = b.boatClass;
      _oarAllocations = List.from(b.oarAllocations);
      _coxswainId = b.coxswainId;
      _seats = List.from(b.seats);
    } else {
      _seats = [];
    }
    _loadData();
  }

  void _computeAllocations() {
    _allocatedShellIds = {};
    _allocatedOarCounts = {};
    _allocatedAthleteIds = {};

    if (widget.activePieceIndex < widget.existingLineups.length) {
      final boats = widget.existingLineups[widget.activePieceIndex].boats;
      for (int i = 0; i < boats.length; i++) {
        if (_isEditing && i == widget.editingBoatIndex) continue;
        final b = boats[i];
        if (b.shellId.isNotEmpty) _allocatedShellIds.add(b.shellId);
        for (final oa in b.oarAllocations) {
          _allocatedOarCounts[oa.oarSetId] =
              (_allocatedOarCounts[oa.oarSetId] ?? 0) + oa.quantityUsed;
        }
        for (final s in b.seats) {
          if (s.userId.isNotEmpty) _allocatedAthleteIds.add(s.userId);
        }
        if (b.coxswainId != null && b.coxswainId!.isNotEmpty) {
          _allocatedAthleteIds.add(b.coxswainId!);
        }
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final shells = await _equipmentService
          .getEquipmentByType(
            widget.organization.id,
            EquipmentType.shell,
            teamId: widget.team?.id,
          )
          .first;
      final oars = await _equipmentService
          .getEquipmentByType(
            widget.organization.id,
            EquipmentType.oar,
            teamId: widget.team?.id,
          )
          .first;

      final Stream<List<Membership>> memberStream;
      if (widget.team?.id != null) {
        memberStream = _membershipService.getTeamMemberships(widget.team!.id);
      } else {
        memberStream = _membershipService.getOrganizationMemberships(
          widget.organization.id,
        );
      }
      final memberships = await memberStream.first;

      final members = <_TeamMember>[];
      for (final m in memberships) {
        if (!m.isActive) continue;
        try {
          final user = await _userService.getUser(m.userId);
          members.add(
            _TeamMember(
              userId: m.userId,
              name: user?.name ?? m.userId,
              role: m.role,
              side: m.side,
            ),
          );
        } catch (_) {
          members.add(
            _TeamMember(
              userId: m.userId,
              name: m.userId,
              role: m.role,
              side: m.side,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _availableShells =
              shells
                  .where(
                    (s) =>
                        s.status != EquipmentStatus.damaged &&
                        s.status != EquipmentStatus.maintenance,
                  )
                  .toList()
                ..sort((a, b) => a.displayName.compareTo(b.displayName));
          _availableOarSets =
              oars
                  .where(
                    (o) =>
                        o.status != EquipmentStatus.damaged &&
                        o.status != EquipmentStatus.maintenance,
                  )
                  .toList()
                ..sort((a, b) => a.displayName.compareTo(b.displayName));
          _teamMembers = members..sort((a, b) => a.name.compareTo(b.name));
          if (_isEditing && widget.editingBoat!.shellId.isNotEmpty) {
            _selectedShell = _availableShells.cast<Equipment?>().firstWhere(
              (s) => s!.id == widget.editingBoat!.shellId,
              orElse: () => null,
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
            title: _isEditing ? 'Edit Boat' : 'Add Boat',
            subtitle: widget.team?.name ?? widget.organization.name,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildShellSection(),
                      const SizedBox(height: 24),
                      if (_selectedShell != null) ...[
                        _buildOarsSection(),
                        const SizedBox(height: 24),
                      ],
                      if (_selectedShell != null &&
                          boatClassHasCox(_boatClass)) ...[
                        _buildCoxSection(),
                        const SizedBox(height: 24),
                      ],
                      if (_selectedShell != null) ...[
                        _buildAthletesSection(),
                        const SizedBox(height: 32),
                        BoathouseStyles.primaryButton(
                          primaryColor: primaryColor,
                          label: _isEditing ? 'Save Changes' : 'Add to Lineup',
                          onPressed: _canSave ? _save : null,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // STEP 1: SHELL (bottom sheet picker + selected card)
  // ════════════════════════════════════════════════════════════

  Widget _buildShellSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('1. Select Shell'),
        if (_selectedShell != null)
          _buildSelectedShellCard()
        else
          _buildShellPickerButton(),
      ],
    );
  }

  Widget _buildSelectedShellCard() {
    final shell = _selectedShell!;
    final shellClass = shell.shellType != null
        ? _shellTypeToClass(shell.shellType!)
        : '?';
    final rig = _rigging;

    return BoathouseStyles.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shellClass,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shell.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (shell.manufacturer.isNotEmpty)
                      Text(
                        '${shell.manufacturer}${shell.year != null ? ' · ${shell.year}' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showShellPicker,
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (rig != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rig.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  ...rig.positions.reversed.map(
                    (p) => Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: p.side == RiggerSide.port
                            ? Colors.red.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Text(
                          p.side == RiggerSide.port ? 'P' : 'S',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: p.side == RiggerSide.port
                                ? Colors.red[700]
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShellPickerButton() {
    if (_availableShells.isEmpty) {
      return BoathouseStyles.card(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.directions_boat, size: 36, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No shells available',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Add shells in Equipment first.',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _showShellPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.directions_boat_outlined,
              size: 24,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap to select a shell',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  void _showShellPicker() {
    final grouped = <String, List<Equipment>>{};
    for (final shell in _availableShells) {
      final cls = shell.shellType != null
          ? _shellTypeToClass(shell.shellType!)
          : 'Other';
      grouped.putIfAbsent(cls, () => []).add(shell);
    }
    final orderedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ai = standardBoatClasses.indexOf(a);
        final bi = standardBoatClasses.indexOf(b);
        return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
      });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Shell',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  if (_selectedShell != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedShell = null;
                          _boatClass = '';
                          _seats = [];
                          _oarAllocations = [];
                          _coxswainId = null;
                        });
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              Text(
                '${_availableShells.length} shells available',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: orderedKeys.expand((cls) {
                    final shells = grouped[cls]!;
                    return [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cls,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${shells.length} ${shells.length == 1 ? 'shell' : 'shells'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...shells.map((shell) {
                        final isAllocated = _allocatedShellIds.contains(
                          shell.id,
                        );
                        final isSelected = _selectedShell?.id == shell.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            tileColor: isSelected
                                ? primaryColor.withOpacity(0.08)
                                : null,
                            leading: CircleAvatar(
                              backgroundColor: isAllocated
                                  ? Colors.grey.shade200
                                  : primaryColor.withOpacity(0.1),
                              radius: 20,
                              child: Icon(
                                Icons.directions_boat,
                                size: 20,
                                color: isAllocated ? Colors.grey : primaryColor,
                              ),
                            ),
                            title: Text(
                              shell.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: isAllocated
                                    ? Colors.grey
                                    : Colors.grey[800],
                              ),
                            ),
                            subtitle: Text(
                              '${shell.manufacturer}${shell.year != null ? ' · ${shell.year}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            trailing: isAllocated
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'In Use',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  )
                                : isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: primaryColor,
                                    size: 22,
                                  )
                                : null,
                            enabled: !isAllocated,
                            onTap: isAllocated
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    _selectShell(shell);
                                  },
                          ),
                        );
                      }),
                    ];
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectShell(Equipment shell) {
    final shellClass = shell.shellType != null
        ? _shellTypeToClass(shell.shellType!)
        : '?';
    setState(() {
      _selectedShell = shell;
      _boatClass = shellClass;
      _seats = List.generate(
        seatsForBoatClass(shellClass),
        (i) => SeatAssignment(seat: i + 1, userId: ''),
      );
      _oarAllocations = [];
      if (!boatClassHasCox(shellClass)) _coxswainId = null;
    });
  }

  // ════════════════════════════════════════════════════════════
  // STEP 2: OARS
  // ════════════════════════════════════════════════════════════

  Widget _buildOarsSection() {
    final neededOars = oarsForBoatClass(_boatClass);
    final currentTotal = _oarAllocations.fold<int>(
      0,
      (sum, o) => sum + o.quantityUsed,
    );
    final isScull = boatClassIsScull(_boatClass);
    final matchingOarSets = _availableOarSets.where((o) {
      if (isScull) return o.oarType == OarType.scull;
      return o.oarType == OarType.sweep;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BoathouseStyles.sectionLabel('2. Assign Oars', bottomPadding: 0),
            const Spacer(),
            Text(
              '$currentTotal / $neededOars oars',
              style: TextStyle(
                fontSize: 13,
                color: currentTotal == neededOars
                    ? Colors.green[600]
                    : Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._oarAllocations.asMap().entries.map((entry) {
          final i = entry.key;
          final alloc = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BoathouseStyles.card(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${alloc.oarSetName} — ${alloc.quantityUsed} oars',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: () =>
                        setState(() => _oarAllocations.removeAt(i)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        }),
        if (currentTotal < neededOars && matchingOarSets.isNotEmpty)
          TextButton.icon(
            icon: Icon(Icons.add, size: 18, color: primaryColor),
            label: Text('Add Oar Set', style: TextStyle(color: primaryColor)),
            onPressed: () =>
                _showOarSetPicker(matchingOarSets, neededOars - currentTotal),
          ),
        if (matchingOarSets.isEmpty)
          Text(
            'No ${isScull ? 'sculling' : 'sweep'} oar sets available.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
      ],
    );
  }

  void _showOarSetPicker(List<Equipment> oarSets, int remaining) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Oar Set',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              'Need $remaining more oar(s)',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ...oarSets.map((oarSet) {
              final totalInSet = oarSet.oarCount ?? 0;
              final usedElsewhere = _allocatedOarCounts[oarSet.id] ?? 0;
              final usedHere = _oarAllocations
                  .where((o) => o.oarSetId == oarSet.id)
                  .fold<int>(0, (s, o) => s + o.quantityUsed);
              final available = totalInSet - usedElsewhere - usedHere;
              final canUse = available > 0;
              final qty = remaining <= available ? remaining : available;
              return ListTile(
                title: Text(oarSet.displayName),
                subtitle: Text(
                  '$available of $totalInSet available',
                  style: TextStyle(
                    color: canUse ? Colors.grey[500] : Colors.red[300],
                  ),
                ),
                trailing: canUse
                    ? Text(
                        'Use $qty',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Text(
                        'None left',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                enabled: canUse,
                onTap: canUse
                    ? () {
                        Navigator.pop(ctx);
                        setState(() {
                          _oarAllocations.add(
                            OarAllocation(
                              oarSetId: oarSet.id,
                              oarSetName: oarSet.displayName,
                              totalInSet: totalInSet,
                              quantityUsed: qty,
                            ),
                          );
                        });
                      }
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // STEP 3: COXSWAIN
  // ════════════════════════════════════════════════════════════

  Widget _buildCoxSection() {
    final coxswains = _teamMembers
        .where((m) => m.role == MembershipRole.coxswain)
        .toList();
    final hasCoxswains = coxswains.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('3. Coxswain'),
        BoathouseStyles.card(
          padding: const EdgeInsets.all(14),
          child: _buildPersonPicker(
            selectedId: _coxswainId,
            label: 'Cox',
            members: hasCoxswains
                ? coxswains
                : _teamMembers
                      .where((m) => m.role == MembershipRole.athlete)
                      .toList(),
            onSelected: (id) => setState(() => _coxswainId = id),
            icon: Icons.headset_mic,
            riggerSide: null,
          ),
        ),
        if (!hasCoxswains)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange[400]),
                const SizedBox(width: 6),
                Text(
                  'No coxswains on roster — showing athletes instead',
                  style: TextStyle(fontSize: 12, color: Colors.orange[400]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // STEP 4: ATHLETES (side-aware)
  // ════════════════════════════════════════════════════════════

  Widget _buildAthletesSection() {
    final seatCount = seatsForBoatClass(_boatClass);
    final athletes = _teamMembers
        .where((m) => m.role == MembershipRole.athlete)
        .toList();
    final stepNum = boatClassHasCox(_boatClass) ? '4' : '3';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('$stepNum. Seat Athletes'),
        if (_rigging != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Athletes sorted by side match. Mismatches shown in orange.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        ...List.generate(seatCount, (i) {
          final seatNum = seatCount - i;
          final seatLabel = seatNum == seatCount
              ? 'Stroke'
              : seatNum == 1
              ? 'Bow'
              : 'Seat $seatNum';
          final assignment = _seats.firstWhere(
            (s) => s.seat == seatNum,
            orElse: () => SeatAssignment(seat: seatNum, userId: ''),
          );
          final rigSide = _riggerSideForSeat(seatNum);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BoathouseStyles.card(
              padding: const EdgeInsets.all(12),
              child: _buildPersonPicker(
                selectedId: assignment.userId.isNotEmpty
                    ? assignment.userId
                    : null,
                label: seatLabel,
                members: athletes,
                onSelected: (id) {
                  setState(() {
                    final idx = _seats.indexWhere((s) => s.seat == seatNum);
                    if (idx >= 0)
                      _seats[idx] = SeatAssignment(
                        seat: seatNum,
                        userId: id ?? '',
                      );
                  });
                },
                icon: Icons.person_outline,
                riggerSide: rigSide,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPersonPicker({
    required String? selectedId,
    required String label,
    required List<_TeamMember> members,
    required Function(String?) onSelected,
    required IconData icon,
    RiggerSide? riggerSide,
  }) {
    final selected = selectedId != null
        ? members.cast<_TeamMember?>().firstWhere(
            (m) => m!.userId == selectedId,
            orElse: () => null,
          )
        : null;

    bool hasMismatch = false;
    if (riggerSide != null &&
        selected?.side != null &&
        selected!.side!.isNotEmpty &&
        selected.side != 'both') {
      final rigSideStr = riggerSide == RiggerSide.port ? 'port' : 'starboard';
      if (selected.side != rigSideStr) hasMismatch = true;
    }

    return InkWell(
      onTap: () => _showMemberPicker(
        label: label,
        members: members,
        currentId: selectedId,
        onSelected: onSelected,
        riggerSide: riggerSide,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          if (riggerSide != null)
            Container(
              width: 22,
              height: 22,
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
            ),
          SizedBox(
            width: riggerSide != null ? 50 : 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selected?.name ?? 'Tap to assign',
              style: TextStyle(
                fontSize: 14,
                color: selected != null
                    ? (hasMismatch ? Colors.orange[700] : Colors.grey[800])
                    : Colors.grey[400],
                fontStyle: selected != null
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
          if (selected?.side != null && selected!.side!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                selected.side == 'both'
                    ? 'B'
                    : selected.side!.toUpperCase().substring(0, 1),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: hasMismatch ? Colors.orange[700] : Colors.grey[600],
                ),
              ),
            ),
          if (hasMismatch)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.warning_amber,
                size: 14,
                color: Colors.orange[600],
              ),
            ),
          Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
        ],
      ),
    );
  }

  void _showMemberPicker({
    required String label,
    required List<_TeamMember> members,
    required String? currentId,
    required Function(String?) onSelected,
    RiggerSide? riggerSide,
  }) {
    var available = members.where((m) {
      if (m.userId == currentId) return true;
      if (_allocatedAthleteIds.contains(m.userId)) return false;
      if (_seats.any((s) => s.userId == m.userId)) return false;
      if (_coxswainId == m.userId) return false;
      return true;
    }).toList();

    // Sort by side match if we have rigger info
    if (riggerSide != null) {
      final rigSideStr = riggerSide == RiggerSide.port ? 'port' : 'starboard';
      available.sort((a, b) {
        final aMatch = _sideMatchScore(a.side, rigSideStr);
        final bMatch = _sideMatchScore(b.side, rigSideStr);
        if (aMatch != bMatch) return bMatch.compareTo(aMatch);
        return a.name.compareTo(b.name);
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (riggerSide != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: riggerSide == RiggerSide.port
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            riggerSide == RiggerSide.port
                                ? 'Port side'
                                : 'Starboard side',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: riggerSide == RiggerSide.port
                                  ? Colors.red[600]
                                  : Colors.green[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (currentId != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onSelected(null);
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: available.length,
                  itemBuilder: (ctx, i) {
                    final m = available[i];
                    final isSelected = m.userId == currentId;

                    // Side match info
                    bool isMismatch = false;
                    bool isMatch = false;
                    if (riggerSide != null &&
                        m.side != null &&
                        m.side!.isNotEmpty &&
                        m.side != 'both') {
                      final rigSideStr = riggerSide == RiggerSide.port
                          ? 'port'
                          : 'starboard';
                      isMismatch = m.side != rigSideStr;
                      isMatch = m.side == rigSideStr;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? primaryColor
                            : Colors.grey.shade200,
                        radius: 18,
                        child: Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isSelected ? _onPrimary : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(m.name)),
                          if (isMatch)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.green[600],
                            ),
                          if (isMismatch)
                            Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: Colors.orange[600],
                            ),
                        ],
                      ),
                      subtitle: m.side != null && m.side!.isNotEmpty
                          ? Text(
                              m.side!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMismatch
                                    ? Colors.orange[500]
                                    : Colors.grey[500],
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: primaryColor)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelected(m.userId);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Scoring: 2 = exact match, 1 = "both", 0 = no side set, -1 = mismatch
  int _sideMatchScore(String? athleteSide, String rigSideStr) {
    if (athleteSide == null || athleteSide.isEmpty) return 0;
    if (athleteSide == 'both') return 1;
    if (athleteSide == rigSideStr) return 2;
    return -1;
  }

  // ════════════════════════════════════════════════════════════
  // SAVE
  // ════════════════════════════════════════════════════════════

  bool get _canSave => _selectedShell != null;

  void _save() {
    final boat = BoatLineup(
      boatName: _selectedShell!.displayName,
      boatClass: _boatClass,
      shellId: _selectedShell!.id,
      oarAllocations: _oarAllocations,
      seats: _seats,
      coxswainId: _coxswainId,
    );
    Navigator.pop(context, boat);
  }

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

  String _shellTypeToClass(ShellType type) {
    switch (type) {
      case ShellType.eight:
        return '8+';
      case ShellType.coxedFour:
        return '4+';
      case ShellType.four:
        return '4-';
      case ShellType.quad:
        return '4x';
      case ShellType.coxedQuad:
        return '4x+';
      case ShellType.pair:
        return '2-';
      case ShellType.double:
        return '2x';
      case ShellType.single:
        return '1x';
    }
  }
}

class _TeamMember {
  final String userId;
  final String name;
  final MembershipRole role;
  final String? side;
  _TeamMember({
    required this.userId,
    required this.name,
    required this.role,
    this.side,
  });
}
