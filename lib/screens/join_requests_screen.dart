import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/join_request.dart';
import '../models/organization.dart';
import '../models/team.dart';
import '../services/join_request_service.dart';
import '../services/team_service.dart';
import '../services/membership_service.dart';
import '../services/auth_service.dart';
import '../models/membership.dart';

class JoinRequestsScreen extends StatelessWidget {
  final String organizationId;
  final Organization organization;

  const JoinRequestsScreen({
    super.key,
    required this.organizationId,
    required this.organization,
  });

  @override
  Widget build(BuildContext context) {
    final joinRequestService = JoinRequestService();
    final primaryColor = organization.primaryColorObj;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 16,
              24,
              24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, organization.secondaryColorObj],
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: primaryColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Join Requests',
                      style: TextStyle(
                        color: primaryColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  organization.name,
                  style: TextStyle(
                    color:
                        (primaryColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white)
                            .withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Request List
          Expanded(
            child: StreamBuilder<List<JoinRequest>>(
              stream: joinRequestService.getPendingRequests(organizationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'No Pending Requests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All join requests have been processed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _JoinRequestCard(
                      request: requests[index],
                      organization: organization,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinRequestCard extends StatefulWidget {
  final JoinRequest request;
  final Organization organization;

  const _JoinRequestCard({required this.request, required this.organization});

  @override
  State<_JoinRequestCard> createState() => _JoinRequestCardState();
}

class _JoinRequestCardState extends State<_JoinRequestCard> {
  final _joinRequestService = JoinRequestService();
  final _membershipService = MembershipService();
  final _teamService = TeamService();
  final _authService = AuthService();

  bool _isProcessing = false;

  Future<void> _approveRequest() async {
    setState(() => _isProcessing = true);

    try {
      final currentUserId = _authService.currentUser!.uid;

      // Create membership with named parameters
      await _membershipService.createMembership(
        userId: widget.request.userId,
        organizationId: widget.request.organizationId,
        teamId: widget.request.teamId,
        role: widget.request.requestedRole,
      );

      // Approve the request
      await _joinRequestService.approveRequest(
        widget.request.id,
        currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.request.userName} approved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectReasonDialog(),
    );

    if (reason == null) return; // User cancelled

    setState(() => _isProcessing = true);

    try {
      final currentUserId = _authService.currentUser!.uid;

      await _joinRequestService.rejectRequest(
        widget.request.id,
        currentUserId,
        reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Color _getRoleColor(MembershipRole role) {
    switch (role) {
      case MembershipRole.coach:
        return Colors.purple;
      case MembershipRole.rower:
        return Colors.blue;
      case MembershipRole.coxswain:
        return Colors.orange;
      case MembershipRole.athlete:
        return Colors.teal;
      case MembershipRole.boatman:
        return Colors.brown;
      case MembershipRole.admin:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(widget.request.requestedRole),
                  child: Text(
                    widget.request.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.request.userEmail,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Role badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(
                      widget.request.requestedRole,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.request.requestedRole.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(widget.request.requestedRole),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Requested ${DateFormat('MM/dd/yyyy').format(widget.request.requestedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            // Team (if specified)
            if (widget.request.teamId != null) ...[
              const SizedBox(height: 12),
              FutureBuilder<Team?>(
                future: _teamService.getTeam(widget.request.teamId!),
                builder: (context, snapshot) {
                  if (snapshot.data == null) return const SizedBox();
                  final team = snapshot.data!;
                  return Row(
                    children: [
                      Icon(Icons.groups, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        team.name,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  );
                },
              ),
            ],

            // Message
            if (widget.request.message?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.request.message.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _approveRequest,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _rejectRequest,
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Please provide a reason for rejecting this request (optional):',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
              hintText: 'e.g., Team is full, wrong experience level',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text.trim());
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
