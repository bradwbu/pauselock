import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/utils/formatters.dart';
import 'package:pauselock_app/src/services/local_storage_service.dart';
import 'package:shimmer/shimmer.dart';

class HeroDetailPage extends StatefulWidget {
  final int heroId;
  const HeroDetailPage({super.key, required this.heroId});

  @override
  State<HeroDetailPage> createState() => _HeroDetailPageState();
}

class _HeroDetailPageState extends State<HeroDetailPage> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  void _checkFavorite() {
    final favs = LocalStorageService.getFavoriteHeroes();
    setState(() {
      _isFavorite = favs.contains(widget.heroId);
    });
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
      await LocalStorageService.removeFavoriteHero(widget.heroId);
    } else {
      await LocalStorageService.addFavoriteHero(widget.heroId);
    }
    _checkFavorite();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Removed from favorites' : 'Added to favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Map<int, Map<String, dynamic>> _itemsCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([
              Future.value(PauselockClient.getHeroById(widget.heroId)),
              Future.value(PauselockClient.getBuildsByHero(widget.heroId)),
              PauselockClient.getAllItems(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return _buildErrorState(context);
              }
              final heroData = snapshot.data![0];
              final buildsData = snapshot.data![1] as List<dynamic>? ?? [];
              _itemsCache = (snapshot.data!.length > 2 && snapshot.data![2] is Map) 
                  ? Map<int, Map<String, dynamic>>.from(snapshot.data![2] as Map) 
                  : {};

              if (heroData == null) {
                return _buildErrorState(context);
              }

              final heroName = heroData['name'] ?? 'Unknown Hero';
              final roles =
                  (heroData['roles'] as List<dynamic>?)?.join(' / ') ??
                      'Unknown';
              final winRate = asDouble(heroData['winRate']);
              final pickRate = asDouble(heroData['pickRate']);
              final banRate = asDouble(heroData['banRate']);
              final baseHealth = asInt(heroData['baseHealth']);
              final baseMana = asInt(heroData['baseMana']);
              final baseDamageMin = asInt(heroData['baseDamageMin']);
              final baseDamageMax = asInt(heroData['baseDamageMax']);
              final baseArmor = asDouble(heroData['baseArmor']);
              final abilities = (heroData['abilities'] as List<dynamic>?) ?? [];

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/heroes'),
                    ),
                    title: Text(heroName.toString().toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge),
                    actions: [
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? AppTheme.errorColor : Colors.white,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                      child: _buildHeroHeader(context, heroName, roles, winRate,
                          pickRate, banRate)),
                  SliverToBoxAdapter(
                      child: _buildHeroStats(context, baseHealth, baseMana,
                          baseDamageMin, baseDamageMax, baseArmor)),
                  SliverToBoxAdapter(
                      child: _buildAbilities(context, abilities)),
                  SliverToBoxAdapter(
                      child: _buildPopularBuilds(context, buildsData)),
                  SliverToBoxAdapter(
                      child: _buildWinRateSection(context, winRate)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          backgroundColor: Colors.transparent,
          title: Text('Loading...'),
        ),
        SliverFillRemaining(
          child: Center(
            child: Shimmer.fromColors(
              baseColor: AppTheme.surfaceColorLight,
              highlightColor: AppTheme.surfaceColor,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load hero data',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/heroes'),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, String name, String roles,
      double winRate, double pickRate, double banRate) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.headlineSmall),
                  Text(roles, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildHeroStat(context, formatPercent(winRate),
                          'Win Rate', AppTheme.successColor),
                      const SizedBox(width: 16),
                      _buildHeroStat(context, formatPercent(pickRate),
                          'Pick Rate', AppTheme.primaryColor),
                      const SizedBox(width: 16),
                      _buildHeroStat(context, formatPercent(banRate),
                          'Ban Rate', AppTheme.accentColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(
      BuildContext context, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildHeroStats(BuildContext context, int health, int mana, int dmgMin,
      int dmgMax, double armor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BASE STATS', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCircle(context, '$health', 'Health', Colors.red),
                _buildStatCircle(context, '$mana', 'Mana', Colors.blue),
                _buildStatCircle(
                    context, '$dmgMin-$dmgMax', 'Damage', Colors.orange),
                _buildStatCircle(
                    context, armor.toStringAsFixed(1), 'Armor', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCircle(
      BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 12))),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildAbilities(BuildContext context, List<dynamic> abilities) {
    if (abilities.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ABILITIES', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: abilities.length,
              itemBuilder: (context, index) {
                final ability = abilities[index].toString();
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: AppTheme.glassDecorationSmall,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flash_on,
                            color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(ability,
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center,
                          maxLines: 2),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularBuilds(BuildContext context, List<dynamic> builds) {
    if (builds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          decoration: AppTheme.glassDecoration,
          padding: const EdgeInsets.all(20),
          child: Text('No builds available yet.',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('POPULAR BUILDS',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                    onPressed: () => context.go('/builds/${widget.heroId}'),
                    child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 12),
            ...builds.take(3).map((build) => InkWell(
                  onTap: () => context.go('/build/${build['id']}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.glassDecorationSmall,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.secondaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.build,
                              color: AppTheme.secondaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(build['buildName'] ?? 'Unknown Build',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              Text('By ${build['author'] ?? 'Unknown'}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: (() {
                                  final itemIds = (build['itemIds'] as List<dynamic>?) ?? [];
                                  final itemNames = (build['items'] as List<dynamic>?) ?? [];
                                  return List.generate(itemIds.length.clamp(0, 3), (i) {
                                    final id = itemIds[i];
                                    final intId = int.tryParse('$id') ?? 0;
                                    final item = _itemsCache[intId];
                                    final imageUrl = item?['imageUrl']?.toString() ?? '';
                                    final itemName = item?['name']?.toString() ??
                                        (i < itemNames.length ? '${itemNames[i]}' : 'Item $id');
                                    final slot = (item?['slotType'] ?? '').toString();
                                    IconData icon;
                                    if (slot == 'weapon') {
                                      icon = Icons.gps_fixed;
                                    } else if (slot == 'spirit') {
                                      icon = Icons.auto_awesome;
                                    } else if (slot == 'vitality') {
                                      icon = Icons.favorite;
                                    } else {
                                      final lower = itemName.toLowerCase();
                                      if (lower.contains('bullet') || lower.contains('round') || lower.contains('shot')) {
                                        icon = Icons.gps_fixed;
                                      } else if (lower.contains('health') || lower.contains('armor') || lower.contains('regen') || lower.contains('lifesteal')) {
                                        icon = Icons.favorite;
                                      } else if (lower.contains('spirit') || lower.contains('mystic') || lower.contains('cooldown')) {
                                        icon = Icons.auto_awesome;
                                      } else {
                                        icon = Icons.inventory_2;
                                      }
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (imageUrl.isNotEmpty)
                                            Image.network(imageUrl, width: 12, height: 12,
                                              errorBuilder: (_, __, ___) => Icon(icon, size: 12, color: AppTheme.accentColor),
                                            )
                                          else
                                            Icon(icon, size: 12, color: AppTheme.accentColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            itemName,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                })(),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatCompactNumber(build['matchesPlayed']),
                                style: const TextStyle(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.bold)),
                            Text('favorites',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

Widget _buildWinRateSection(BuildContext context, double winRate) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CURRENT PERFORMANCE',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('Current WR: ${formatPercent(winRate)}',
                    style: const TextStyle(color: AppTheme.textSecondary)),
              )),
          ],
        ),
      ),
    );
  }


}
