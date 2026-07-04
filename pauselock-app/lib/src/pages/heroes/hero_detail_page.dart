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
          content: Text(
              _isFavorite ? 'Removed from favorites' : 'Added to favorites'),
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
              _itemsCache = (snapshot.data!.length > 2 &&
                      snapshot.data![2] is Map)
                  ? Map<int, Map<String, dynamic>>.from(
                      snapshot.data![2] as Map)
                  : {};

              if (heroData == null) {
                return _buildErrorState(context);
              }

              final heroName = heroData['name'] ?? 'Unknown Hero';
              final winRate = asDouble(heroData['winRate']);
              final pickRate = asDouble(heroData['pickRate']);
              final banRate = asDouble(heroData['banRate']);
              final iconUrl = heroData['iconUrl'] ?? '';
              final bannerUrl = heroData['bannerPortraitUrl'] ?? '';
              final tier = heroData['tier'] ?? 'C';
              final heroType = heroData['heroType'] ?? heroData['primaryAttribute'] ?? '';
              final complexity = heroData['complexity'] ?? 1;
              final baseHealth = asInt(heroData['baseHealth']);
              final baseDamage = asInt(heroData['baseDamageMin']);
              final heavyDamage = asInt(heroData['baseDamageMax']);
              final bulletDamage = asInt(heroData['baseBulletDamage']);
              final moveSpeed = asDouble(heroData['baseMoveSpeed']);
              final sprintSpeed = asDouble(heroData['sprintSpeed']);
              final healthRegen = asDouble(heroData['baseHealthRegen']);
              final bulletArmor = asDouble(heroData['bulletArmorReduction']);
              final techArmor = asDouble(heroData['techArmorReduction']);
              final abilities = (heroData['abilities'] as List<dynamic>?) ?? [];
              final matchesPlayed = heroData['matchesPlayed'] ?? 0;
              final description = heroData['description'] ?? '';

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
                          _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isFavorite ? AppTheme.errorColor : Colors.white,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                      child: _buildHeroBanner(
                          context, heroName, heroType, tier, complexity,
                          iconUrl, bannerUrl)),
                  SliverToBoxAdapter(
                      child: _buildHeroStatsRow(
                          context, winRate, pickRate, banRate, matchesPlayed)),
                  if (description.toString().isNotEmpty)
                    SliverToBoxAdapter(
                        child: _buildDescription(context, description)),
                  SliverToBoxAdapter(
                      child: _buildBaseStats(
                          context, baseHealth, baseDamage, heavyDamage,
                          bulletDamage, moveSpeed, sprintSpeed,
                          healthRegen, bulletArmor, techArmor)),
                  SliverToBoxAdapter(
                      child: _buildAbilities(context, abilities)),
                  SliverToBoxAdapter(
                      child: _buildPopularBuilds(context, buildsData)),
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
          const Icon(Icons.error_outline,
              color: AppTheme.errorColor, size: 48),
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

  Widget _buildHeroBanner(BuildContext context, String name, String heroType,
      String tier, int complexity, String iconUrl, String bannerUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppTheme.glassDecoration.copyWith(
          border: Border.all(
            color: _tierColor(tier).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _tierColor(tier).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: bannerUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Image.network(bannerUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildFallbackHeroImage(iconUrl)),
                        )
                      : _buildFallbackHeroImage(iconUrl),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tierColor(tier),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('TIER $tier',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text('$complexity/4',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(heroType.toString().toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackHeroImage(String iconUrl) {
    return Center(
      child: iconUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(iconUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, color: Colors.white54, size: 64)),
            )
          : const Icon(Icons.person, color: Colors.white54, size: 64),
    );
  }

  Widget _buildHeroStatsRow(BuildContext context, double winRate,
      double pickRate, double banRate, dynamic matchesPlayed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn(
                formatPercent(winRate), 'Win Rate', AppTheme.successColor),
            _buildStatColumn(
                formatPercent(pickRate), 'Pick Rate', AppTheme.primaryColor),
            _buildStatColumn(
                formatPercent(banRate), 'Ban Rate', AppTheme.accentColor),
            _buildStatColumn(
                formatCompactNumber(matchesPlayed), 'Matches', Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(16),
        child: Text(description,
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildBaseStats(
      BuildContext context, int health, int lightMelee, int heavyMelee,
      int bulletDmg, double moveSpeed, double sprintSpeed,
      double healthRegen, double bulletArmor, double techArmor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BASE STATS',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildStatGrid([
              _StatData('$health', 'Health', Colors.red),
              _StatData('$bulletDmg', 'Bullet Dmg', Colors.orange),
              _StatData('$lightMelee', 'Light Melee', Colors.amber),
              _StatData('$heavyMelee', 'Heavy Melee', Colors.deepOrange),
              _StatData(moveSpeed.toStringAsFixed(1), 'Move Speed', Colors.cyan),
              _StatData(sprintSpeed.toStringAsFixed(1), 'Sprint', Colors.teal),
              _StatData(healthRegen.toStringAsFixed(1), 'Regen/s', Colors.green),
              _StatData('${(bulletArmor * 100).toStringAsFixed(0)}%', 'Bullet Armor', Colors.blue),
              _StatData('${(techArmor * 100).toStringAsFixed(0)}%', 'Tech Armor', Colors.purple),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(List<_StatData> stats) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: stat.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: stat.color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.value,
                  style: TextStyle(
                      color: stat.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Text(stat.label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 9)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAbilities(BuildContext context, List<dynamic> abilities) {
    if (abilities.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ABILITIES', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...abilities.map((ability) {
              final abilityMap = ability is Map
                  ? ability
                  : {'name': ability.toString(), 'className': ''};
              final name = abilityMap['name'] ?? ability.toString();
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
                        color:
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flash_on,
                          color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(name,
                          style: Theme.of(context).textTheme.titleSmall),
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

  Widget _buildPopularBuilds(BuildContext context, List<dynamic> builds) {
    if (builds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: AppTheme.glassDecoration,
          padding: const EdgeInsets.all(20),
          child: Text('No builds available yet.',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(16),
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
            ...builds.take(3).map((build) {
              final details =
                  (build['itemDetails'] as List<dynamic>?) ?? [];
              for (final detail in details) {
                if (detail is Map && detail['id'] != null) {
                  final id = detail['id'] is int
                      ? detail['id']
                      : int.tryParse('${detail['id']}') ?? 0;
                  if (id > 0 && !_itemsCache.containsKey(id)) {
                    _itemsCache[id] = Map<String, dynamic>.from(detail);
                  }
                }
              }
              return InkWell(
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
                            color: AppTheme.secondaryColor
                                .withValues(alpha: 0.2),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                              Text('By ${build['author'] ?? 'Unknown'}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: (() {
                                  final itemIds =
                                      (build['itemIds'] as List<dynamic>?) ?? [];
                                  final itemNames =
                                      (build['items'] as List<dynamic>?) ?? [];
                                  return List.generate(
                                      itemIds.length.clamp(0, 3), (i) {
                                    final id = itemIds[i];
                                    final intId =
                                        int.tryParse('$id') ?? 0;
                                    final item = _itemsCache[intId];
                                    final imageUrl =
                                        item?['imageUrl']?.toString() ?? '';
                                    final itemName = item?['name']
                                            ?.toString() ??
                                        (i < itemNames.length
                                            ? '${itemNames[i]}'
                                            : 'Item $id');
                                    final slot =
                                        (item?['slotType'] ?? '')
                                            .toString();
                                    IconData icon;
                                    if (slot == 'weapon') {
                                      icon = Icons.gps_fixed;
                                    } else if (slot == 'spirit') {
                                      icon = Icons.auto_awesome;
                                    } else if (slot == 'vitality') {
                                      icon = Icons.favorite;
                                    } else {
                                      icon = Icons.inventory_2;
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (imageUrl.isNotEmpty)
                                            Image.network(imageUrl,
                                                width: 12,
                                                height: 12,
                                                errorBuilder: (_, __,
                                                        ___) =>
                                                    Icon(icon,
                                                        size: 12,
                                                        color: AppTheme
                                                            .accentColor))
                                          else
                                            Icon(icon,
                                                size: 12,
                                                color:
                                                    AppTheme.accentColor),
                                          const SizedBox(width: 4),
                                          Text(itemName,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme
                                                      .textSecondary)),
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
                            Text(
                                formatCompactNumber(
                                    build['matchesPlayed']),
                                style: const TextStyle(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.bold)),
                            Text('favorites',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall),
                          ],
                        ),
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
}

class _StatData {
  final String value;
  final String label;
  final Color color;
  const _StatData(this.value, this.label, this.color);
}
