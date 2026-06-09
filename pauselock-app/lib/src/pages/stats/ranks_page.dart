import 'package:flutter/material.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';

class RanksPage extends StatelessWidget {
  const RanksPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulated ranks distribution similar to tracklock.gg
    final ranks = [
      {'name': 'Obscurus', 'color': Colors.grey, 'mmr': '0 - 1000', 'percentile': 'Bottom 20%'},
      {'name': 'Initiate', 'color': Colors.green, 'mmr': '1000 - 1400', 'percentile': 'Top 80%'},
      {'name': 'Seeker', 'color': Colors.blue, 'mmr': '1400 - 1700', 'percentile': 'Top 50%'},
      {'name': 'Alchemist', 'color': Colors.purple, 'mmr': '1700 - 2000', 'percentile': 'Top 25%'},
      {'name': 'Archon', 'color': AppTheme.primaryColor, 'mmr': '2000 - 2400', 'percentile': 'Top 10%'},
      {'name': 'Oracle', 'color': Colors.redAccent, 'mmr': '2400 - 2800', 'percentile': 'Top 3%'},
      {'name': 'Phantom', 'color': AppTheme.accentColor, 'mmr': '2800+', 'percentile': 'Top 0.5%'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MMR Rank Distribution'),
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
                    'Deadlock uses a hidden MMR system. These brackets represent the estimated skill tiers based on community data tracking.',
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
                          child: Icon(Icons.military_tech, color: rank['color'] as Color, size: 32),
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
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.trending_up, size: 14, color: Colors.white54),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Est. MMR: ${rank['mmr']}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                  ),
                                ],
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
                            rank['percentile'] as String,
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
