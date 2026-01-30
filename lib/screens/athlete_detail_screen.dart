import 'package:flutter/material.dart';
import '../models/athlete.dart';
import 'edit_athlete_screen.dart';

class AthleteDetailScreen extends StatelessWidget {
  final Athlete athlete;

  const AthleteDetailScreen({super.key, required this.athlete});

  bool get _isCoxswain => athlete.role == 'coxswain';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(athlete.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditAthleteScreen(athlete: athlete),
                ),
              );

              if (result == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and basic info
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _getRoleColor(athlete.role),
                child: Text(
                  athlete.name.isNotEmpty ? athlete.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                athlete.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(athlete.role),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  athlete.role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                athlete.email,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),

            // Injury warning banner
            if (athlete.isInjured) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INJURED',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (athlete.injuryDetails != null &&
                              athlete.injuryDetails!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              athlete.injuryDetails!,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Basic details
            const Text(
              'Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 16),
            if (athlete.gender != null)
              _buildInfoRow(
                'Gender',
                athlete.gender == 'male' ? 'Male' : 'Female',
              ),
            if (athlete.side != null && athlete.role == 'rower')
              _buildInfoRow('Side', _formatSide(athlete.side!)),
            if (athlete.weightClass != null && athlete.role == 'rower')
              _buildInfoRow('Weight Class', athlete.weightClass!),

            // Physical stats (not for coxswains)
            if (!_isCoxswain) ...[
              const SizedBox(height: 32),
              const Text(
                'Physical Stats',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              const SizedBox(height: 16),
              if (athlete.height != null ||
                  athlete.weight != null ||
                  athlete.wingspan != null) ...[
                if (athlete.height != null)
                  _buildStatCard(
                    icon: Icons.height,
                    label: 'Height',
                    value:
                        '${athlete.height}"  (${(athlete.height! / 12).toStringAsFixed(1)} ft)',
                  ),
                if (athlete.weight != null)
                  _buildStatCard(
                    icon: Icons.monitor_weight,
                    label: 'Weight',
                    value: '${athlete.weight} lbs',
                  ),
                if (athlete.wingspan != null)
                  _buildStatCard(
                    icon: Icons.airline_stops,
                    label: 'Wingspan',
                    value: '${athlete.wingspan}"',
                  ),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No physical stats recorded',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],

            // Erg scores (not for coxswains)
            if (!_isCoxswain) ...[
              const SizedBox(height: 32),
              const Text(
                'Erg Scores',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              const SizedBox(height: 16),
              athlete.ergScores.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No erg scores yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Column(
                      children: athlete.ergScores.map((score) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.timer),
                            title: Text(
                              score.testType,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(score.date.toString().split(' ')[0]),
                            trailing: Text(
                              score.formattedTime,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'coach':
        return Colors.purple;
      case 'coxswain':
        return Colors.orange;
      case 'rower':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatSide(String side) {
    return side[0].toUpperCase() + side.substring(1);
  }
}
