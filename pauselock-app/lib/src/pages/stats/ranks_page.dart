import 'package:flutter/material.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';

class RanksPage extends StatelessWidget {
  const RanksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ranks = [
      {'name': 'Initiate', 'tier': 2, 'color': Colors.green, 'description': 'Just starting out'},
      {'name': 'Seeker', 'tier': 3, 'color': Colors.blue, 'description': 'Learning the basics'},
      {'name': 'Alchemist', 'tier': 4, 'color': Colors.purple, 'description': 'Mixing things up'},
      {'name': 'Ritualist', 'tier': 5, 'color': Colors.teal, 'description': 'Finding their groove'},
      {'name': 'Emissary', 'tier': 6, 'color': Colors.orange, 'description': 'Reliable performers'},
      {'name': 'Archon', 'tier': 7, 'color': AppTheme.primaryColor, 'description': 'Strategic thinkers'},
      {'name': 'Oracle', 'tier': 8, 'color': Colors.redAccent, 'description': 'See the future'},
      {'name': 'Phantom', 'tier': 9, 'color': AppTheme.accentColor, 'description': 'Elusive and deadly'},
      {'name': 'Ascendant', 'tier': 10, 'color': Colors.amber, 'description': 'Rising above'},
      {'name': 'Eternus', 'tier': 11, 'color': Colors.red, 'description': 'The elite'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rank Tiers'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.accentColor),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Deadlock ranks are earned through consistent performance. Each rank has sub-tiers that you progress through.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: ranks.length,
              itemBuilder: (context, index) {
                final rank = ranks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: (rank['color'] as Color).withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: rank['color'] as Color, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: (rank['color'] as Color).withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${rank['tier']}',
                              style: TextStyle(
                                color: rank['color'] as Color,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rank['name'] as String,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: rank['color'] as Color,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rank['description'] as String,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: (rank['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Tier ${rank['tier']}',
                            style: TextStyle(
                              color: rank['color'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
