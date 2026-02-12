import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/membership.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import '../utils/boathouse_styles.dart';
import '../widgets/team_header.dart';

/// Screen for coaches to view and edit a shell's rigging configuration.
/// Supports preset selection, per-seat toggling, dual-rig switching,
/// and validates that the rig is balanced (equal port/starboard).
class RiggingEditorScreen extends StatefulWidget {
  final AppUser user;
  final Membership currentMembership;
  final Organization organization;
  final Team? team;
  final Equipment shell;

  const RiggingEditorScreen({
    super.key,
    required this.user,
    required this.currentMembership,
    required this.organization,
    required this.team,
    required this.shell,
  });

  @override
  State<RiggingEditorScreen> createState() => _RiggingEditorScreenState();
}

class _RiggingEditorScreenState extends State<RiggingEditorScreen> {
  final _equipmentService = EquipmentService();

  late Equipment _shell;
  late List<RiggerPosition> _positions;
  String _setupName = '';
  bool _isSaving = false;
  bool _hasChanges = false;

  Color get primaryColor =>
      widget.team?.primaryColorObj ??
      widget.organization.primaryColorObj ??
      const Color(0xFF1976D2);

  Color get _onPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  int get _seatCount {
    final st = _shell.effectiveShellType;
    if (st == null) return 0;
    return _seatCountForShellType(st);
  }

  bool get _isSweep => _shell.isSweepConfig;
  bool get _isScull => _shell.isScullConfig;
  bool get _isDualRigged => _shell.riggingType == RiggingType.dualRigged;

  bool get _isBalanced {
    if (_positions.isEmpty) return true;
    final portCount = _positions.where((p) => p.side == RiggerSide.port).length;
    final stbdCount = _positions
        .where((p) => p.side == RiggerSide.starboard)
        .length;
    return portCount == stbdCount;
  }

  int get _portCount =>
      _positions.where((p) => p.side == RiggerSide.port).length;
  int get _stbdCount =>
      _positions.where((p) => p.side == RiggerSide.starboard).length;

  @override
  void initState() {
    super.initState();
    _shell = widget.shell;
    _initializePositions();
  }

  void _initializePositions() {
    final existing = _shell.effectiveRiggingSetup;
    if (existing != null) {
      _positions = List.from(existing.positions);
      _setupName = existing.name;
    } else {
      // Generate default
      final preset = RiggingPresets.standardPortStroke(_seatCount);
      _positions = List.from(preset.positions);
      _setupName = preset.name;
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
            title: 'Rigging Setup',
            subtitle: _shell.displayName,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _onPrimary),
              onPressed: () => Navigator.pop(context, _shell),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Shell info card ──
                _buildShellInfoCard(),
                const SizedBox(height: 20),

                // ── Dual-rig switcher ──
                if (_isDualRigged) ...[
                  _buildDualRigSwitcher(),
                  const SizedBox(height: 20),
                ],

                // ── Rigging section (sweep only) ──
                if (_isSweep) ...[
                  _buildPresetPicker(),
                  const SizedBox(height: 20),
                  _buildRiggingDiagram(),
                  const SizedBox(height: 16),
                  _buildBalanceIndicator(),
                  const SizedBox(height: 24),
                  BoathouseStyles.primaryButton(
                    primaryColor: primaryColor,
                    label: _isSaving ? 'Saving...' : 'Save Rigging',
                    onPressed: _hasChanges && _isBalanced && !_isSaving
                        ? _save
                        : null,
                  ),
                ],

                if (_isScull) ...[_buildScullInfo()],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // SHELL INFO
  // ════════════════════════════════════════════════════════════

  Widget _buildShellInfoCard() {
    final effectiveType = _shell.effectiveShellType;
    final classStr = effectiveType != null
        ? _shellTypeToClass(effectiveType)
        : '?';

    return BoathouseStyles.card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              classStr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
                  _shell.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_shell.manufacturer}${_shell.year != null ? ' · ${_shell.year}' : ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                if (_isDualRigged)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Dual Rigged',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // DUAL-RIG SWITCHER
  // ════════════════════════════════════════════════════════════

  Widget _buildDualRigSwitcher() {
    final baseType = _shell.shellType;
    if (baseType == null) return const SizedBox.shrink();

    // Determine the sweep and scull options for this hull
    final options = _dualRigOptions(baseType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('Configuration Mode'),
        BoathouseStyles.card(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: options.map((option) {
              final isActive =
                  _shell.effectiveShellType == option['type'] as ShellType;
              return Expanded(
                child: GestureDetector(
                  onTap: isActive
                      ? null
                      : () => _switchDualRig(option['type'] as ShellType),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isActive
                          ? Border.all(color: primaryColor.withOpacity(0.3))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          option['class'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isActive ? primaryColor : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? primaryColor : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _dualRigOptions(ShellType baseType) {
    // Map base shell types to their sweep/scull counterparts
    switch (baseType) {
      case ShellType.four:
      case ShellType.quad:
        return [
          {'type': ShellType.four, 'class': '4-', 'label': 'Sweep'},
          {'type': ShellType.quad, 'class': '4x', 'label': 'Scull'},
        ];
      case ShellType.coxedFour:
      case ShellType.coxedQuad:
        return [
          {'type': ShellType.coxedFour, 'class': '4+', 'label': 'Sweep'},
          {'type': ShellType.coxedQuad, 'class': '4x+', 'label': 'Scull'},
        ];
      case ShellType.pair:
      case ShellType.double:
        return [
          {'type': ShellType.pair, 'class': '2-', 'label': 'Sweep'},
          {'type': ShellType.double, 'class': '2x', 'label': 'Scull'},
        ];
      default:
        return [];
    }
  }

  Future<void> _switchDualRig(ShellType target) async {
    try {
      await _equipmentService.switchDualRigConfig(_shell.id, target);
      setState(() {
        _shell = _shell.copyWith(activeShellType: target);
        _initializePositions();
        _hasChanges = false;
      });

      if (mounted) {
        final isScull = _isScull;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isScull ? 'Switched to sculling mode' : 'Switched to sweep mode',
            ),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error switching config: $e')));
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // PRESET PICKER (bottom sheet)
  // ════════════════════════════════════════════════════════════

  Widget _buildPresetPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('Rigging Preset'),
        InkWell(
          onTap: _showPresetPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, size: 20, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _setupName.isNotEmpty ? _setupName : 'Select preset',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Tap to choose a preset or customize below',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPresetPicker() {
    final presets = RiggingPresets.presetsForSeatCount(_seatCount);

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
              'Rigging Presets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              'Select a standard rigging pattern',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ...presets.map((preset) {
              final isCurrent = _setupName == preset.name;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: isCurrent ? primaryColor.withOpacity(0.08) : null,
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  radius: 18,
                  child: Icon(Icons.tune, size: 18, color: primaryColor),
                ),
                title: Text(
                  preset.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  _presetPreview(preset),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                trailing: isCurrent
                    ? Icon(Icons.check_circle, color: primaryColor, size: 22)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _positions = List.from(preset.positions);
                    _setupName = preset.name;
                    _hasChanges = true;
                  });
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Short text preview: "S:P 7:S 6:P 5:S ..." (stroke down to bow)
  String _presetPreview(RiggingSetup preset) {
    final seatCount = preset.positions.length;
    return preset.positions.reversed
        .map((p) {
          final label = p.seat == seatCount
              ? 'S'
              : p.seat == 1
              ? 'B'
              : '${p.seat}';
          final side = p.side == RiggerSide.port ? 'P' : 'S';
          return '$label:$side';
        })
        .join('  ');
  }

  // ════════════════════════════════════════════════════════════
  // RIGGING DIAGRAM — visual per-seat editor
  // ════════════════════════════════════════════════════════════

  Widget _buildRiggingDiagram() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoathouseStyles.sectionLabel('Seat Rigging'),
        Text(
          'Tap a seat to toggle between port and starboard',
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
        const SizedBox(height: 12),

        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'PORT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 60,
                child: Text(
                  'STBD',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[400],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Seats from stroke (top) to bow (bottom)
        ...List.generate(_seatCount, (i) {
          final seatNum = _seatCount - i;
          final position = _positions.firstWhere(
            (p) => p.seat == seatNum,
            orElse: () => RiggerPosition(seat: seatNum, side: RiggerSide.port),
          );
          final seatLabel = seatNum == _seatCount
              ? 'Stroke'
              : seatNum == 1
              ? 'Bow'
              : 'Seat $seatNum';
          final isPort = position.side == RiggerSide.port;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () => _toggleSeat(seatNum),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // Port side indicator
                    _buildSideIndicator(
                      isActive: isPort,
                      color: Colors.red,
                      label: 'P',
                    ),
                    const SizedBox(width: 12),

                    // Rigger arm (port side)
                    if (isPort)
                      Container(
                        width: 30,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.red[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    else
                      const SizedBox(width: 30),

                    // Center — seat label
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            seatLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Rigger arm (starboard side)
                    if (!isPort)
                      Container(
                        width: 30,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.green[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    else
                      const SizedBox(width: 30),

                    const SizedBox(width: 12),

                    // Starboard side indicator
                    _buildSideIndicator(
                      isActive: !isPort,
                      color: Colors.green,
                      label: 'S',
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSideIndicator({
    required bool isActive,
    required MaterialColor color,
    required String label,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? color.withOpacity(0.4) : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? color[700] : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  void _toggleSeat(int seatNum) {
    setState(() {
      final idx = _positions.indexWhere((p) => p.seat == seatNum);
      if (idx >= 0) {
        final current = _positions[idx];
        _positions[idx] = current.copyWith(
          side: current.side == RiggerSide.port
              ? RiggerSide.starboard
              : RiggerSide.port,
        );
      }
      _setupName = 'Custom';
      _hasChanges = true;
    });
  }

  // ════════════════════════════════════════════════════════════
  // BALANCE INDICATOR
  // ════════════════════════════════════════════════════════════

  Widget _buildBalanceIndicator() {
    return BoathouseStyles.card(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            _isBalanced ? Icons.check_circle : Icons.warning_amber_rounded,
            color: _isBalanced ? Colors.green : Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBalanced ? 'Rig is balanced' : 'Rig is unbalanced',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _isBalanced ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                Text(
                  '$_portCount port · $_stbdCount starboard',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (!_isBalanced)
            Text(
              'Must be equal to save',
              style: TextStyle(fontSize: 11, color: Colors.orange[400]),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // SCULL INFO (no rigging needed)
  // ════════════════════════════════════════════════════════════

  Widget _buildScullInfo() {
    return BoathouseStyles.card(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Sculling Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Each rower rows on both sides.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          if (_isDualRigged) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Sculling mode active',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Switch to sweep mode above to configure rigging.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // SAVE
  // ════════════════════════════════════════════════════════════

  Future<void> _save() async {
    if (!_isBalanced) return;

    setState(() => _isSaving = true);

    try {
      final setup = RiggingSetup(
        name: _setupName,
        positions: _positions,
        isDefault: true,
      );

      await _equipmentService.updateRiggingSetup(_shell.id, setup);

      setState(() {
        _shell = _shell.copyWith(riggingSetup: setup);
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rigging saved'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

  int _seatCountForShellType(ShellType st) {
    switch (st) {
      case ShellType.eight:
        return 8;
      case ShellType.coxedFour:
      case ShellType.four:
      case ShellType.quad:
      case ShellType.coxedQuad:
        return 4;
      case ShellType.pair:
      case ShellType.double:
        return 2;
      case ShellType.single:
        return 1;
    }
  }

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
