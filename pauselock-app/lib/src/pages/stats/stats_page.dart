import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';

class StatsPage extends StatefulWidget {
  final int? accountId;
  const StatsPage({super.key, this.accountId});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _playerData;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: ShaderMask(
                  shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                  child: const Text('STATS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () => context.go('/profile'),
                  ),
                ],
              ),
              SliverToBoxAdapter(child: _buildSearchSection(context)),
              if (_playerData != null) ...[
                SliverToBoxAdapter(child: _buildPlayerOverview(context)),
                SliverToBoxAdapter(child: _buildTopHeroes(context)),
                SliverToBoxAdapter(child: _buildRankedStats(context)),
                SliverToBoxAdapter(child: _buildRecentMatches(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Enter Steam ID or search player...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              onSubmitted: (_) => _searchPlayer(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _searchPlayer,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search Player'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerOverview(BuildContext context) {
    if (_playerData == null) return const SizedBox.shrink();
    final name = _playerData!['playerName'] ?? 'Unknown';
    final accountId = _playerData!['accountId'] ?? 0;
    final mmr = _playerData!['mmr'] ?? 0;
    final totalMatches = _playerData!['totalMatches'] ?? 0;
    final winRate = _playerData!['winRate'] ?? 0;
    final kda = _playerData!['kda'] ?? 0.0;
    final rank = _playerData!['rank'] ?? 0;
    
    final rankLabel = _getRankLabel(rank);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.headlineSmall),
                      Text('Steam ID: $accountId', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Rank: $rankLabel', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('MMR', '$mmr', AppTheme.primaryColor),
                _buildStatItem('Win Rate', '${winRate.toStringAsFixed(1)}%', AppTheme.successColor),
                _buildStatItem('Matches', '$totalMatches', AppTheme.textSecondary),
                _buildStatItem('K/D/A', kda.toStringAsFixed(1), AppTheme.accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getRankLabel(int rank) {
    if (rank <= 10) return 'Grandmaster';
    if (rank <= 50) return 'Master';
    if (rank <= 100) return 'Grand Champion';
    if (rank <= 500) return 'Champion';
    if (rank <= 1000) return 'Diamond';
    if (rank <= 2000) return 'Platinum';
    if (rank <= 5000) return 'Gold';
    if (rank <= 10000) return 'Silver';
    return 'Bronze';
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildTopHeroes(BuildContext context) {
    if (_playerData == null) return const SizedBox.shrink();
    final topHeroes = (_playerData!['topHeroes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (topHeroes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MOST PLAYED HEROES', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: topHeroes.map((hero) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecorationSmall,
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(hero['heroName'] ?? 'Unknown', 
                              style: Theme.of(context).textTheme.titleSmall,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('${hero['matches']} matches', 
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankedStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RANKED STATS', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildRankCard('Current Rank', 'Gold III', '3200 MMR')),
                const SizedBox(width: 12),
                Expanded(child: _buildRankCard('Peak Rank', 'Platinum I', '3450 MMR')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMiniStat('Wins', '665', Icons.check_circle, AppTheme.successColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniStat('Losses', '569', Icons.cancel, AppTheme.errorColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniStat('Win Rate', '53.9%', Icons.trending_up, AppTheme.primaryColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCard(String title, String rank, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecorationSmall,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(rank, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor)),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.glassDecorationSmall,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildRecentMatches(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RECENT MATCHES', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...List.generate(5, (index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassDecorationSmall,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? AppTheme.successColor.withValues(alpha: 0.2) : AppTheme.errorColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      index % 2 == 0 ? Icons.check : Icons.close,
                      color: index % 2 == 0 ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hero Name', style: Theme.of(context).textTheme.titleSmall),
                        Text('25 min ago', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('12/4/8', style: Theme.of(context).textTheme.titleSmall),
                      Text('K/D/A', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _searchPlayer() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _playerData = null;
    });

    // Try to find by account ID if numeric, otherwise search by name
    final accountId = int.tryParse(query);
    Map<String, dynamic>? data;
    
    if (accountId != null) {
      data = await PauselockClient.getPlayerStats(accountId);
    } else {
      // Search by name
      final results = await PauselockClient.searchPlayers(query);
      if (results != null && results.isNotEmpty) {
        // Use the first match's accountId to get full stats
        final firstMatch = results.first;
        final id = firstMatch['accountId'] as int?;
        if (id != null) {
          data = await PauselockClient.getPlayerStats(id);
        }
      }
    }

    if (data != null) {
      setState(() {
        _playerData = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        // Could show a "not found" state here
      });
    }
  }
}
