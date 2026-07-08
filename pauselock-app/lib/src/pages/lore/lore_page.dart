import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:shimmer/shimmer.dart';

class LorePage extends StatefulWidget {
  const LorePage({super.key});

  @override
  State<LorePage> createState() => _LorePageState();
}

class _LorePageState extends State<LorePage> {
  String _selectedRole = 'All';
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
    list.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
    return list;
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
                  child: const Text('HERO LORE',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(child: _buildRoleTabs(context)),
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Shimmer.fromColors(
                    baseColor: AppTheme.surfaceColorLight,
                    highlightColor: AppTheme.surfaceColor,
                    child: Container(
                      height: 300,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.accentColor, size: 48),
                          const SizedBox(height: 16),
                          Text(_error!,
                              style: const TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadHeroes,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildLoreCard(context, _filteredHeroes[index]),
                      childCount: _filteredHeroes.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _roles
            .map((role) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _selectedRole = role),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: role == _selectedRole
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceColorLight,
                        foregroundColor: role == _selectedRole
                            ? Colors.white
                            : AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(role, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLoreCard(BuildContext context, dynamic hero) {
    final heroId = hero['id'] ?? 0;
    final heroName = hero['name'] ?? 'Unknown';
    final heroType = hero['heroType'] ?? '';
    final bannerUrl = hero['bannerPortraitUrl'] ?? hero['verticalUrl'] ?? '';
    final lore = hero['lore'] ?? '';
    final playstyle = hero['playstyle'] ?? '';
    final description = hero['description'] ?? '';
    final tier = hero['tier'] ?? 'C';
    final teaser = lore.isNotEmpty
        ? lore
        : playstyle.isNotEmpty
            ? playstyle
            : description;
    final hasLore = teaser.toString().isNotEmpty;

    return GestureDetector(
      onTap: () => context.go('/lore/$heroId'),
      child: Container(
        decoration: AppTheme.glassDecoration,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerUrl.toString().isNotEmpty)
                    Image.network(
                      bannerUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.surfaceColorLight,
                        child: const Center(
                          child: Icon(Icons.person, color: Colors.white24, size: 48),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surfaceColorLight,
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white24, size: 48),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildTierBadge(tier),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(heroName.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1)),
                        if (heroType.toString().isNotEmpty)
                          Text(heroType.toString().toUpperCase(),
                              style: TextStyle(
                                  color: AppTheme.accentColor.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: hasLore
                    ? Text(
                        teaser.toString(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      )
                    : Center(
                        child: Text(
                          'No lore available',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge(String tier) {
    final tierColors = {
      'S+': const Color(0xFFFF4466),
      'S': const Color(0xFFFF9900),
      'A': const Color(0xFF00D4FF),
      'B': const Color(0xFF00FF88),
      'C': const Color(0xFFA0AABF),
    };
    final color = tierColors[tier] ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(tier,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
