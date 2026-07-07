import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/utils/formatters.dart';

class StatsPage extends StatefulWidget {
  final int? accountId;
  const StatsPage({super.key, this.accountId});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Map<String, dynamic>? _playerData;
  List<dynamic> _recentMatches = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _suggestions = [];
  Map<int, Map<String, dynamic>> _heroMap = {};
  bool _isLoading = false;
  bool _showingResults = false;
  bool _isSearchingSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    if (widget.accountId != null) {
      _loadPlayer(widget.accountId!);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty || int.tryParse(query) != null) {
      setState(() {
        _suggestions = [];
        _isSearchingSuggestions = false;
      });
      return;
    }

    setState(() => _isSearchingSuggestions = true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.length < 2 || _searchController.text.trim() != query) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isSearchingSuggestions = false;
          });
        }
        return;
      }
      final results = await PauselockClient.searchPlayers(query);
      if (!mounted) return;
      if (results != null && results.isNotEmpty && _searchController.text.trim() == query) {
        setState(() {
          _suggestions = results.take(5).toList();
          _isSearchingSuggestions = false;
        });
      } else {
        setState(() {
          _suggestions = [];
          _isSearchingSuggestions = false;
        });
      }
    });
  }

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
              if (_showingResults && _searchResults.isNotEmpty)
                SliverToBoxAdapter(child: _buildSearchResults(context)),
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
    final showClear = _searchController.text.isNotEmpty || _suggestions.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            decoration: AppTheme.glassDecoration,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search player name or enter Steam ID...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: showClear
                        ? IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _showingResults = false;
                                _suggestions = [];
                              });
                            },
                          )
                        : null,
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
          if (_isSearchingSuggestions)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassDecoration,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                ),
              ),
            ),
          if (!_isSearchingSuggestions && _suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: AppTheme.glassDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _suggestions.map((player) {
                  final name = player['playerName'] ?? 'Unknown';
                  final accountId = player['accountId'] ?? 0;
                  final avatarUrl = player['avatarUrl'] ?? '';
                  return InkWell(
                    onTap: () {
                      _focusNode.unfocus();
                      setState(() {
                        _suggestions = [];
                        _searchResults = [];
                        _showingResults = false;
                        _isLoading = true;
                        _playerData = null;
                        _recentMatches = [];
                      });
                      _loadPlayer(accountId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.surfaceColorLight,
                            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text('Steam ID: $accountId',
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${_searchResults.length} player${_searchResults.length == 1 ? '' : 's'} found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            ..._searchResults.map((player) {
              final name = player['playerName'] ?? 'Unknown';
              final accountId = player['accountId'] ?? 0;
              final avatarUrl = player['avatarUrl'] ?? '';
              return InkWell(
                onTap: () {
                  _focusNode.unfocus();
                  setState(() {
                    _showingResults = false;
                    _searchResults = [];
                    _isLoading = true;
                  });
                  _loadPlayer(accountId);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.surfaceColorLight,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: Theme.of(context).textTheme.bodyLarge),
                            Text('Steam ID: $accountId', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPlayer(int accountId) async {
    final results = await Future.wait([
      PauselockClient.getPlayerStats(accountId),
      PauselockClient.getPlayerMatches(accountId, limit: 10),
      if (_heroMap.isEmpty) PauselockClient.getAllHeroes() else Future.value(null),
    ]);

    final data = results[0] as Map<String, dynamic>?;
    final matches = results[1] as List<dynamic>?;
    final heroes = results[2] as List<dynamic>?;

    if (heroes != null && heroes.isNotEmpty && _heroMap.isEmpty) {
      _heroMap = {
        for (final h in heroes)
          if (h is Map && h['id'] != null)
            asInt(h['id']): Map<String, dynamic>.from(h),
      };
    }

    if (data != null) {
      setState(() {
        _playerData = data;
        _recentMatches = matches ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
    final avatarUrl = _playerData!['avatarUrl'] ?? '';

    final rankLabel = formatRank(rank);

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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.person, size: 40, color: Colors.white),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                  ),
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
                final heroId = hero['heroId'] ?? 0;
                final heroData = _heroMap[heroId];
                final iconUrl = heroData?['iconUrl'] ?? '';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecorationSmall,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: iconUrl.isNotEmpty
                                  ? Image.network(
                                      iconUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.person, color: Colors.white),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.person, color: Colors.white),
                                    ),
                            ),
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
    if (_playerData == null) return const SizedBox.shrink();
    final wins = _playerData!['wins'] ?? 0;
    final losses = _playerData!['losses'] ?? 0;
    final winRate = _playerData!['winRate'] ?? 0;
    final rank = _playerData!['rank'] ?? 0;
    final mmr = _playerData!['mmr'] ?? 0;
    final totalMatches = _playerData!['totalMatches'] ?? 0;
    final rankLabel = formatRank(rank);

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
                Expanded(
                  child: _buildRankCard(
                    'Current Rank',
                    rankLabel,
                    '$mmr MMR',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRankCard(
                    'Matches',
                    '$wins W / $losses L',
                    '$totalMatches total',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMiniStat('Wins', '$wins', Icons.check_circle, AppTheme.successColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniStat('Losses', '$losses', Icons.cancel, AppTheme.errorColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniStat('Win Rate', '${winRate.toStringAsFixed(1)}%', Icons.trending_up, AppTheme.primaryColor)),
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
    if (_recentMatches.isEmpty) return const SizedBox.shrink();

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
            ..._recentMatches.take(10).map((match) {
              final heroId = asInt(match['hero_id']);
              final heroData = _heroMap[heroId];
              final heroName = heroData?['name'] ?? 'Hero #$heroId';
              final heroIcon = heroData?['iconUrl'] ?? '';
              final kills = asInt(match['player_kills']);
              final deaths = asInt(match['player_deaths']);
              final assists = asInt(match['player_assists']);
              final won = asInt(match['match_result']) == asInt(match['player_team']);
              final durationS = asInt(match['match_duration_s']);
              final durationMin = durationS ~/ 60;
              final startTime = match['start_time'];
              final DateTime? matchTime = (startTime != null && startTime is num && startTime > 0)
                  ? DateTime.fromMillisecondsSinceEpoch(startTime.toInt() * 1000)
                  : null;
              final timeAgo = matchTime != null ? _formatTimeAgo(matchTime) : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.glassDecorationSmall,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: heroIcon.isNotEmpty
                            ? Image.network(
                                heroIcon,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: BoxDecoration(
                                    color: won
                                        ? AppTheme.successColor.withValues(alpha: 0.2)
                                        : AppTheme.errorColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    won ? Icons.check : Icons.close,
                                    color: won ? AppTheme.successColor : AppTheme.errorColor,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: won
                                      ? AppTheme.successColor.withValues(alpha: 0.2)
                                      : AppTheme.errorColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  won ? Icons.check : Icons.close,
                                  color: won ? AppTheme.successColor : AppTheme.errorColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                won ? Icons.check_circle : Icons.cancel,
                                size: 14,
                                color: won ? AppTheme.successColor : AppTheme.errorColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(heroName,
                                    style: Theme.of(context).textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          Text(
                            '$durationMin min${timeAgo.isNotEmpty ? ' \u00b7 $timeAgo' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$kills/$deaths/$assists', style: Theme.of(context).textTheme.titleSmall),
                        Text('K/D/A', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime matchTime) {
    final diff = DateTime.now().difference(matchTime);
    if (diff.isNegative) return 'just now';
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _searchPlayer() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _isLoading = true;
      _playerData = null;
      _recentMatches = [];
      _searchResults = [];
      _showingResults = false;
      _suggestions = [];
    });

    final accountId = int.tryParse(query);
    if (accountId != null) {
      _loadPlayer(accountId);
      return;
    }

    final results = await PauselockClient.searchPlayers(query);
    if (results != null && results.isNotEmpty) {
      if (results.length == 1) {
        final id = results.first['accountId'] as int?;
        if (id != null) {
          _loadPlayer(id);
          return;
        }
      }
      setState(() {
        _searchResults = results;
        _showingResults = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
