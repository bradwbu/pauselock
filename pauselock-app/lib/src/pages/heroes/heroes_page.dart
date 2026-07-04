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
        final heroType =
            (h['heroType'] ?? h['primaryAttribute'] ?? '').toString();
        return heroType.toLowerCase() == _selectedRole.toLowerCase();
      }).toList();
    }
    switch (_sortBy) {
      case 'winRate':
        list.sort(
            (a, b) => (b['winRate'] ?? 0).compareTo(a['winRate'] ?? 0));
      case 'pickRate':
        list.sort(
            (a, b) => (b['pickRate'] ?? 0).compareTo(a['pickRate'] ?? 0));
      case 'banRate':
        list.sort(
            (a, b) => (b['banRate'] ?? 0).compareTo(a['banRate'] ?? 0));
      case 'name':
        list.sort((a, b) => (a['name'] ?? '')
            .toString()
            .compareTo((b['name'] ?? '').toString()));
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
      backgroundColor: const Color(0xFF0D1117),
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
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
                      crossAxisCount: 6,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildListDelegate(
                        List.generate(12, (index) => _buildLoadingCard())),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(child: _buildErrorState())
              else if (_filteredHeroes.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else if (_sortBy == 'tier')
                ..._buildTierSections()
              else
                SliverToBoxAdapter(
                  child: _buildHeroWrap(_filteredHeroes),
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
      sections.add(SliverToBoxAdapter(
        child: _buildHeroWrap(heroes),
      ));
      sections.add(const SliverToBoxAdapter(child: SizedBox(height: 4)));
    }
    return sections;
  }

  Widget _buildTierHeader(String tier, int count) {
    final tierColors = {
      'S+': [const Color(0xFFFF4466), const Color(0xFFFF6B8A)],
      'S': [const Color(0xFFFF9900), const Color(0xFFFFBB33)],
      'A': [const Color(0xFF6B5CE7), const Color(0xFF8B7BF7)],
      'B': [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      'C': [const Color(0xFF6B7280), const Color(0xFF9CA3AF)],
    };
    final descriptions = {
      'S+': 'Overpowered',
      'S': 'Meta Defining',
      'A': 'Strong Picks',
      'B': 'Viable',
      'C': 'Situational',
    };
    final colors = tierColors[tier] ?? [Colors.grey, Colors.grey];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        '$tier Tier - ${descriptions[tier] ?? ''}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildHeroWrap(List<dynamic> heroes) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 14,
        children: heroes
            .map((hero) => _buildHeroCard(context, hero))
            .toList(),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        children: [
          SizedBox(
            height: 36,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color:
                          isSelected ? null : AppTheme.surfaceColorLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(role,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                color: isSelected
                    ? AppTheme.accentColor
                    : AppTheme.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
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
        decoration: BoxDecoration(
          color: AppTheme.surfaceColorLight,
          borderRadius: BorderRadius.circular(8),
        ),
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

  Color _complexityColor(String tier) {
    switch (tier) {
      case 'S+':
        return const Color(0xFF00E676);
      case 'S':
        return const Color(0xFF00E676);
      case 'A':
        return const Color(0xFF00E676);
      case 'B':
        return const Color(0xFF00E676);
      case 'C':
        return const Color(0xFFFF5252);
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildHeroCard(BuildContext context, dynamic hero) {
    final name = hero['name'] ?? 'Unknown';
    final heroId = hero['id'] ?? 0;
    final iconUrl = hero['iconUrl'] ?? '';
    return GestureDetector(
      onTap: () => context.go('/heroes/$heroId'),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: iconUrl.isNotEmpty
                        ? Image.network(
                            iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person,
                                    color: Colors.white54, size: 40),
                          )
                        : const Icon(Icons.person,
                            color: Colors.white54, size: 40),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _complexityColor(hero['tier'] ?? 'C'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
