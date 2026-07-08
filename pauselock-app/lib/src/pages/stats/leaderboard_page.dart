import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/utils/formatters.dart';
import 'package:shimmer/shimmer.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String _selectedRegion = 'Global';
  List<dynamic> _entries = [];
  bool _isLoading = true;
  Map<int, Map<String, dynamic>> _heroMap = {};

  @override
  void initState() {
    super.initState();
    _loadHeroes();
    _loadLeaderboard();
  }

  Future<void> _loadHeroes() async {
    final heroes = await PauselockClient.getAllHeroes();
    if (heroes != null && mounted) {
      final map = <int, Map<String, dynamic>>{};
      for (final h in heroes) {
        final id = h['id'] ?? h['heroId'];
        if (id != null) map[id as int] = Map<String, dynamic>.from(h);
      }
      setState(() => _heroMap = map);
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    final region = _selectedRegion == 'Global' ? null : _selectedRegion;
    final data =
        await PauselockClient.getLeaderboard(region: region, limit: 20);
    setState(() {
      _entries = data ?? [];
      _isLoading = false;
    });
  }

  List<dynamic> get _topThree {
    return _entries.take(3).toList();
  }

  List<dynamic> get _remaining {
    return _entries.skip(3).take(17).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadLeaderboard,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                  title: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: const Text('LEADERBOARD',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverToBoxAdapter(child: _buildRegionTabs(context)),
                if (_isLoading)
                  SliverToBoxAdapter(
                    child: Shimmer.fromColors(
                      baseColor: AppTheme.surfaceColorLight,
                      highlightColor: AppTheme.surfaceColor,
                      child: Container(
                        height: 200,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(child: _buildTopPlayers(context)),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      _remaining
                          .map((entry) => _buildLeaderboardRow(
                                context,
                                entry['rank'] ?? 0,
                                entry['playerName'] ?? 'Unknown',
                                entry['mmr'] ?? 0,
                                entry['region'] ?? 'Unknown',
                                entry['avatarUrl'] ?? '',
                                entry['heroId'] ?? 0,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['Global', 'EU', 'NA', 'Asia']
            .map((region) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedRegion != region) {
                          setState(() => _selectedRegion = region);
                          _loadLeaderboard();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: region == _selectedRegion
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceColorLight,
                        foregroundColor: region == _selectedRegion
                            ? Colors.white
                            : AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(region, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTopPlayers(BuildContext context) {
    if (_topThree.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: Text('No data available')),
      );
    }
    final players = _topThree.length >= 3 ? _topThree : List.from(_topThree);
    while (players.length < 3) {
      players.add({
        'rank': players.length + 1,
        'playerName': 'TBD',
        'mmr': 0,
        'region': 'Unknown'
      });
    }
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
              child: _buildTopPlayerCard(
                  context,
                  (players[1]['rank'] ?? 2).toString(),
                  players[1]['playerName'] ?? 'Unknown',
                  (players[1]['mmr'] ?? 0).toString(),
                  AppTheme.secondaryColor,
                  avatarUrl: players[1]['avatarUrl'] ?? '',
                  heroId: players[1]['heroId'] ?? 0)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              child: _buildTopPlayerCard(
                  context,
                  (players[0]['rank'] ?? 1).toString(),
                  players[0]['playerName'] ?? 'Unknown',
                  (players[0]['mmr'] ?? 0).toString(),
                  AppTheme.primaryColor,
                  isFirst: true,
                  avatarUrl: players[0]['avatarUrl'] ?? '',
                  heroId: players[0]['heroId'] ?? 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: _buildTopPlayerCard(
                  context,
                  (players[2]['rank'] ?? 3).toString(),
                  players[2]['playerName'] ?? 'Unknown',
                  (players[2]['mmr'] ?? 0).toString(),
                  AppTheme.accentColor,
                  avatarUrl: players[2]['avatarUrl'] ?? '',
                  heroId: players[2]['heroId'] ?? 0)),
        ],
      ),
    );
  }

  Widget _buildTopPlayerCard(
      BuildContext context, String rank, String name, String mmr, Color color,
      {bool isFirst = false, String avatarUrl = '', int heroId = 0}) {
    final size = isFirst ? 50.0 : 40.0;
    final hero = _heroMap[heroId];
    final heroIconUrl = hero?['iconUrl'] ?? '';
    return Container(
      decoration: AppTheme.glassDecoration,
      padding: EdgeInsets.all(isFirst ? 20 : 16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size + 6,
                height: size + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: color.withValues(alpha: 0.2),
                            child: Center(
                                child: Text(rank,
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isFirst ? 20 : 16))),
                          ),
                        )
                      : Container(
                          color: color.withValues(alpha: 0.2),
                          child: Center(
                              child: Text(rank,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isFirst ? 20 : 16))),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (heroIconUrl.isNotEmpty) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(heroIconUrl, width: 24, height: 24, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ],
          Text(formatRank(mmr),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(
      BuildContext context, int rank, String name, int mmr, String region, String avatarUrl, int heroId) {
    final hero = _heroMap[heroId];
    final heroIconUrl = hero?['iconUrl'] ?? '';
    final heroName = hero?['name'] ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: AppTheme.glassDecorationSmall,
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
          ),
          child: ClipOval(
            child: avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      child: Center(
                          child: Text('$rank',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12))),
                    ),
                  )
                : Container(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: Center(
                        child: Text('$rank',
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))),
                  ),
          ),
        ),
        title: Text(name, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Row(
          children: [
            Text(region, style: Theme.of(context).textTheme.bodySmall),
            if (heroIconUrl.isNotEmpty) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.network(heroIconUrl, width: 16, height: 16, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
              ),
              if (heroName.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(heroName, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatRank(mmr),
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            Text('Rank', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
