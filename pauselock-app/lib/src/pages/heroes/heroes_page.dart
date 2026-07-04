import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:shimmer/shimmer.dart';

class HeroesPage extends StatefulWidget {
  const HeroesPage({super.key});

  @override
  State<HeroesPage> createState() => _HeroesPageState();
}

class _HeroesPageState extends State<HeroesPage> {
  String _selectedRole = 'All';
  String _sortBy = 'tier';
  final List<String> _roles = [
    'All',
    'Assassin',
    'Brawler',
    'Marksman',
    'Mystic',
  ];
  List<dynamic> _heroes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHeroes();
  }

  Future<void> _loadHeroes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final heroes = await PauselockClient.getAllHeroes();
      setState(() {
        _heroes = heroes ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load heroes. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredHeroes {
    var list = _heroes;
    if (_selectedRole != 'All') {
      list = list.where((h) {
        final heroType = (h['heroType'] ?? h['primaryAttribute'] ?? '').toString();
        return heroType.toLowerCase() == _selectedRole.toLowerCase();
      }).toList();
    }
    switch (_sortBy) {
      case 'winRate':
        list.sort((a, b) => (b['winRate'] ?? 0).compareTo(a['winRate'] ?? 0));
      case 'pickRate':
        list.sort((a, b) => (b['pickRate'] ?? 0).compareTo(a['pickRate'] ?? 0));
      case 'banRate':
        list.sort((a, b) => (b['banRate'] ?? 0).compareTo(a['banRate'] ?? 0));
      case 'name':
        list.sort((a, b) =>
            (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      default:
        list = _sortByTiers(list);
    }
    return list;
  }

  List<dynamic> _sortByTiers(List<dynamic> list) {
    const tierOrder = {'S+': 0, 'S': 1, 'A': 2, 'B': 3, 'C': 4};
    list.sort((a, b) {
      final aTier = tierOrder[a['tier'] ?? 'C'] ?? 4;
      final bTier = tierOrder[b['tier'] ?? 'C'] ?? 4;
      if (aTier != bTier) return aTier.compareTo(bTier);
      return (b['winRate'] ?? 0).compareTo(a['winRate'] ?? 0);
    });
    return list;
  }

  Map<String, List<dynamic>> get _tierGroups {
    final groups = <String, List<dynamic>>{};
    for (final hero in _filteredHeroes) {
      final tier = hero['tier'] ?? 'C';
      groups.putIfAbsent(tier, () => []).add(hero);
    }
    return groups;
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
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: const Text('HEROES',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadHeroes,
                  ),
                ],
              ),
              SliverToBoxAdapter(child: _buildFilterBar(context)),
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildListDelegate(
                        List.generate(9, (index) => _buildLoadingCard())),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(child: _buildErrorState())
              else if (_filteredHeroes.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else if (_sortBy == 'tier')
                ..._buildTierSections()
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildListDelegate(
                      _filteredHeroes
                          .map((hero) => _buildHeroCard(context, hero))
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTierSections() {
    final tiers = ['S+', 'S', 'A', 'B', 'C'];
    final groups = _tierGroups;
    final sections = <Widget>[];
    for (final tier in tiers) {
      final heroes = groups[tier];
      if (heroes == null || heroes.isEmpty) continue;
      sections.add(SliverToBoxAdapter(
        child: _buildTierHeader(tier, heroes.length),
      ));
      sections.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildListDelegate(
            heroes.map((hero) => _buildHeroCard(context, hero)).toList(),
          ),
        ),
      ));
      sections.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
    }
    return sections;
  }

  Widget _buildTierHeader(String tier, int count) {
    final tierColors = {
      'S+': [const Color(0xFFFF4466), const Color(0xFFFF6B8A)],
      'S': [const Color(0xFFFF9900), const Color(0xFFFFBB33)],
      'A': [const Color(0xFF00D4FF), const Color(0xFF00AAFF)],
      'B': [const Color(0xFF00FF88), const Color(0xFF00CC66)],
      'C': [const Color(0xFFA0AABF), const Color(0xFF8890AA)],
    };
    final colors = tierColors[tier] ?? [Colors.grey, Colors.grey];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(tier,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Text('$count heroes',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary)),
          const Spacer(),
          _buildTierLegend(tier),
        ],
      ),
    );
  }

  Widget _buildTierLegend(String tier) {
    final descriptions = {
      'S+': 'Overpowered',
      'S': 'Strong',
      'A': 'Balanced',
      'B': 'Below Average',
      'C': 'Weak',
    };
    return Text(descriptions[tier] ?? '',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppTheme.textSecondary, fontSize: 11));
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        children: [
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _roles.length,
              itemBuilder: (context, index) {
                final role = _roles[index];
                final isSelected = role == _selectedRole;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRole = role),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color: isSelected ? null : AppTheme.surfaceColorLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(role,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSortChip('Tier', 'tier'),
                _buildSortChip('Win Rate', 'winRate'),
                _buildSortChip('Pick Rate', 'pickRate'),
                _buildSortChip('Ban Rate', 'banRate'),
                _buildSortChip('Name', 'name'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentColor
                : AppTheme.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              )),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceColorLight,
      highlightColor: AppTheme.surfaceColor,
      child: Container(
        decoration: AppTheme.glassDecoration,
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.errorColor, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load heroes',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error ?? 'Something went wrong',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadHeroes,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined,
              color: AppTheme.textSecondary, size: 48),
          const SizedBox(height: 16),
          Text('No heroes found',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _selectedRole == 'All'
                ? 'No hero data available.'
                : 'No heroes match the "$_selectedRole" filter.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'S+':
        return const Color(0xFFFF4466);
      case 'S':
        return const Color(0xFFFF9900);
      case 'A':
        return const Color(0xFF00D4FF);
      case 'B':
        return const Color(0xFF00FF88);
      case 'C':
        return const Color(0xFFA0AABF);
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildHeroCard(BuildContext context, dynamic hero) {
    final name = hero['name'] ?? 'Unknown';
    final heroId = hero['id'] ?? 0;
    final iconUrl = hero['iconUrl'] ?? '';
    final winRate = (hero['winRate'] ?? 0).toDouble();
    final pickRate = (hero['pickRate'] ?? 0).toDouble();
    final banRate = (hero['banRate'] ?? 0).toDouble();
    final tier = hero['tier'] ?? 'C';
    final heroType = hero['heroType'] ?? hero['primaryAttribute'] ?? '';
    final matchesPlayed = hero['matchesPlayed'] ?? 0;
    final complexity = hero['complexity'] ?? 1;

    return GestureDetector(
      onTap: () => context.go('/heroes/$heroId'),
      child: Container(
        decoration: AppTheme.glassDecoration.copyWith(
          border: Border.all(
            color: _tierColor(tier).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _tierColor(tier).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  if (iconUrl.isNotEmpty)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.white54, size: 48),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.person,
                          color: Colors.white54, size: 48),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _tierColor(tier),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(tier,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      children: List.generate(
                        complexity,
                        (i) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _tierColor(tier),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(heroType.toString().toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    fontSize: 9, letterSpacing: 0.5),
                            maxLines: 1),
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMiniStat(
                                '${winRate.toStringAsFixed(1)}%',
                                'WR',
                                winRate >= 50
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor),
                            _buildMiniStat(
                                '${pickRate.toStringAsFixed(1)}%',
                                'PR',
                                AppTheme.primaryColor),
                            _buildMiniStat(
                                '${banRate.toStringAsFixed(1)}%',
                                'BR',
                                AppTheme.accentColor),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${_formatNumber(matchesPlayed)} matches',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 8)),
      ],
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return '$num';
  }
}
