// seed_test_data.dart
// Run from your Flutter project root:
//   dart run lib/scripts/seed_test_data.dart
//
// Or paste the seedAll() function into a temporary button in your app
// and call it once.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// ─── CONFIG ──────────────────────────────────────────────
const orgId = '5MMegNdJuQyOAGZ9tYX5';
const teamId = '3QgMq1zrH1bsaZcVuDjN';
// ─────────────────────────────────────────────────────────

Future<void> seedAll() async {
  final firestore = FirebaseFirestore.instance;
  final batch1 = firestore.batch();
  final batch2 = firestore.batch();
  final batch3 = firestore.batch();

  final now = DateTime.now().toIso8601String();

  // ════════════════════════════════════════════════════════
  // 24 ROWERS
  // ════════════════════════════════════════════════════════
  final rowers = <Map<String, dynamic>>[
    {
      'name': 'James Callahan',
      'side': 'starboard',
      'weight': 190.0,
      'height': 75.0,
    },
    {'name': 'Ethan Brooks', 'side': 'port', 'weight': 185.0, 'height': 74.0},
    {
      'name': 'Liam Fitzgerald',
      'side': 'starboard',
      'weight': 195.0,
      'height': 76.0,
    },
    {'name': 'Noah Patterson', 'side': 'port', 'weight': 180.0, 'height': 73.0},
    {
      'name': 'Owen Sullivan',
      'side': 'starboard',
      'weight': 188.0,
      'height': 75.0,
    },
    {'name': 'Mason Rivera', 'side': 'port', 'weight': 192.0, 'height': 76.0},
    {'name': 'Carter Walsh', 'side': 'both', 'weight': 183.0, 'height': 74.0},
    {
      'name': 'Aidan Kowalski',
      'side': 'starboard',
      'weight': 197.0,
      'height': 77.0,
    },
    {'name': 'Dylan Mercer', 'side': 'port', 'weight': 186.0, 'height': 74.0},
    {
      'name': 'Jack Hennessy',
      'side': 'starboard',
      'weight': 191.0,
      'height': 75.0,
    },
    {'name': 'Ryan Tompkins', 'side': 'port', 'weight': 178.0, 'height': 72.0},
    {
      'name': 'Caleb Donovan',
      'side': 'starboard',
      'weight': 194.0,
      'height': 76.0,
    },
    {'name': 'Lucas Brennan', 'side': 'port', 'weight': 182.0, 'height': 73.0},
    {'name': 'Gavin Ashford', 'side': 'both', 'weight': 189.0, 'height': 75.0},
    {
      'name': 'Declan Murray',
      'side': 'starboard',
      'weight': 196.0,
      'height': 77.0,
    },
    {'name': 'Finn Gallagher', 'side': 'port', 'weight': 184.0, 'height': 74.0},
    {
      'name': 'Sean Whitfield',
      'side': 'starboard',
      'weight': 187.0,
      'height': 75.0,
    },
    {'name': 'Cole Prescott', 'side': 'port', 'weight': 181.0, 'height': 73.0},
    {'name': 'Tristan Locke', 'side': 'both', 'weight': 193.0, 'height': 76.0},
    {
      'name': 'Patrick Reeves',
      'side': 'starboard',
      'weight': 190.0,
      'height': 75.0,
    },
    {'name': 'Brendan Holt', 'side': 'port', 'weight': 179.0, 'height': 72.0},
    {
      'name': 'Connor Steele',
      'side': 'starboard',
      'weight': 198.0,
      'height': 77.0,
    },
    {'name': 'Kyle Weston', 'side': 'port', 'weight': 185.0, 'height': 74.0},
    {
      'name': 'Derek Chang',
      'side': 'starboard',
      'weight': 188.0,
      'height': 75.0,
    },
  ];

  // 3 COXSWAINS
  final coxswains = <Map<String, dynamic>>[
    {'name': 'Alex Navarro', 'weight': 125.0, 'height': 65.0},
    {'name': 'Sam Delgado', 'weight': 130.0, 'height': 66.0},
    {'name': 'Jordan Kessler', 'weight': 128.0, 'height': 64.0},
  ];

  // Create users + memberships for rowers
  for (final r in rowers) {
    final userRef = firestore.collection('users').doc();
    final memRef = firestore.collection('memberships').doc();
    final userId = userRef.id;

    batch1.set(userRef, {
      'id': userId,
      'name': r['name'],
      'email':
          '${(r['name'] as String).toLowerCase().replaceAll(' ', '.')}@test.com',
      'createdAt': now,
      'height': r['height'],
      'weight': r['weight'],
      'hasInjury': false,
      'currentOrganizationId': orgId,
      'currentMembershipId': memRef.id,
    });

    batch1.set(memRef, {
      'id': memRef.id,
      'userId': userId,
      'organizationId': orgId,
      'teamId': teamId,
      'role': 'athlete',
      'isActive': true,
      'startDate': now,
      'permissions': [
        'view_equipment',
        'log_personal_workouts',
        'report_equipment_damage',
      ],
      'useDefaultPermissions': true,
      'side': r['side'],
      'weightClass': (r['weight'] as double) <= 160.0
          ? 'lightweight'
          : 'heavyweight',
    });
  }

  // Create users + memberships for coxswains
  for (final c in coxswains) {
    final userRef = firestore.collection('users').doc();
    final memRef = firestore.collection('memberships').doc();
    final userId = userRef.id;

    batch2.set(userRef, {
      'id': userId,
      'name': c['name'],
      'email':
          '${(c['name'] as String).toLowerCase().replaceAll(' ', '.')}@test.com',
      'createdAt': now,
      'height': c['height'],
      'weight': c['weight'],
      'hasInjury': false,
      'currentOrganizationId': orgId,
      'currentMembershipId': memRef.id,
    });

    batch2.set(memRef, {
      'id': memRef.id,
      'userId': userId,
      'organizationId': orgId,
      'teamId': teamId,
      'role': 'coxswain',
      'isActive': true,
      'startDate': now,
      'permissions': [
        'view_team_roster',
        'view_lineups',
        'view_workouts',
        'log_team_workouts',
        'report_equipment_damage',
        'view_schedule',
      ],
      'useDefaultPermissions': true,
    });
  }

  // ════════════════════════════════════════════════════════
  // SHELLS
  // ════════════════════════════════════════════════════════
  final shells = <Map<String, dynamic>>[
    // 8+ boats
    {
      'name': 'Resolute',
      'manufacturer': 'Vespoli',
      'shellType': 'eight',
      'riggingType': 'sweep',
      'year': 2022,
    },
    {
      'name': 'Endeavor',
      'manufacturer': 'Hudson',
      'shellType': 'eight',
      'riggingType': 'sweep',
      'year': 2021,
    },
    {
      'name': 'Liberty',
      'manufacturer': 'Empacher',
      'shellType': 'eight',
      'riggingType': 'sweep',
      'year': 2023,
    },
    // 4+ boats
    {
      'name': 'Patriot',
      'manufacturer': 'Vespoli',
      'shellType': 'coxedFour',
      'riggingType': 'sweep',
      'year': 2022,
    },
    {
      'name': 'Defiant',
      'manufacturer': 'Hudson',
      'shellType': 'coxedFour',
      'riggingType': 'sweep',
      'year': 2020,
    },
    // 4- boats
    {
      'name': 'Ghost',
      'manufacturer': 'Filippi',
      'shellType': 'four',
      'riggingType': 'sweep',
      'year': 2023,
    },
    // 2- pair
    {
      'name': 'Arrow',
      'manufacturer': 'Empacher',
      'shellType': 'pair',
      'riggingType': 'sweep',
      'year': 2021,
    },
    {
      'name': 'Bolt',
      'manufacturer': 'Vespoli',
      'shellType': 'pair',
      'riggingType': 'sweep',
      'year': 2022,
    },
    // 1x singles (sculling)
    {
      'name': 'Zen',
      'manufacturer': 'Filippi',
      'shellType': 'single',
      'riggingType': 'scull',
      'year': 2023,
    },
    {
      'name': 'Dart',
      'manufacturer': 'Hudson',
      'shellType': 'single',
      'riggingType': 'scull',
      'year': 2022,
    },
    // 2x double
    {
      'name': 'Spark',
      'manufacturer': 'Vespoli',
      'shellType': 'double',
      'riggingType': 'scull',
      'year': 2021,
    },
    // 4x quad
    {
      'name': 'Cyclone',
      'manufacturer': 'Empacher',
      'shellType': 'quad',
      'riggingType': 'scull',
      'year': 2023,
    },
  ];

  for (final s in shells) {
    final ref = firestore.collection('equipment').doc();
    batch3.set(ref, {
      'id': ref.id,
      'organizationId': orgId,
      'type': 'shell',
      'name': s['name'],
      'manufacturer': s['manufacturer'],
      'year': s['year'],
      'shellType': s['shellType'],
      'riggingType': s['riggingType'],
      'status': 'available',
      'availableToAllTeams': true,
      'assignedTeamIds': [teamId],
      'createdAt': now,
      'isDamaged': false,
      'damageReports': [],
    });
  }

  // ════════════════════════════════════════════════════════
  // OARS
  // ════════════════════════════════════════════════════════
  final oars = <Map<String, dynamic>>[
    {
      'name': 'Sweep Set A',
      'manufacturer': 'Concept2',
      'oarType': 'sweep',
      'oarCount': 16,
      'bladeType': 'Smoothie2',
    },
    {
      'name': 'Sweep Set B',
      'manufacturer': 'Croker',
      'oarType': 'sweep',
      'oarCount': 12,
      'bladeType': 'Arrow',
    },
    {
      'name': 'Scull Set A',
      'manufacturer': 'Concept2',
      'oarType': 'scull',
      'oarCount': 16,
      'bladeType': 'Smoothie2',
    },
    {
      'name': 'Scull Set B',
      'manufacturer': 'Croker',
      'oarType': 'scull',
      'oarCount': 8,
      'bladeType': 'S4',
    },
  ];

  for (final o in oars) {
    final ref = firestore.collection('equipment').doc();
    batch3.set(ref, {
      'id': ref.id,
      'organizationId': orgId,
      'type': 'oar',
      'name': o['name'],
      'manufacturer': o['manufacturer'],
      'oarType': o['oarType'],
      'oarCount': o['oarCount'],
      'bladeType': o['bladeType'],
      'status': 'available',
      'availableToAllTeams': true,
      'assignedTeamIds': [teamId],
      'createdAt': now,
      'isDamaged': false,
      'damageReports': [],
    });
  }

  // ════════════════════════════════════════════════════════
  // COMMIT ALL BATCHES
  // ════════════════════════════════════════════════════════
  await batch1.commit();
  print('✅ Batch 1: 24 rowers (users + memberships)');
  await batch2.commit();
  print('✅ Batch 2: 3 coxswains (users + memberships)');
  await batch3.commit();
  print('✅ Batch 3: ${shells.length} shells + ${oars.length} oar sets');
  print(
    '🎉 Done! Total: 27 athletes, ${shells.length} shells, ${oars.length} oar sets',
  );
}
