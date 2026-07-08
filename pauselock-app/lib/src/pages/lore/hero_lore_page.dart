import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';

class HeroLorePage extends StatefulWidget {
  final int heroId;
  const HeroLorePage({super.key, required this.heroId});

  @override
  State<HeroLorePage> createState() => _HeroLorePageState();
}

class _HeroLorePageState extends State<HeroLorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: PauselockClient.getHeroById(widget.heroId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor));
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return _buildErrorState(context);
              }

              final hero = snapshot.data!;
              final heroName = hero['name'] ?? 'Unknown Hero';
              final heroType = hero['heroType'] ?? hero['primaryAttribute'] ?? '';
              final iconUrl = hero['iconUrl'] ?? '';
              final bannerUrl = hero['bannerPortraitUrl'] ?? hero['backgroundUrl'] ?? '';
              final verticalUrl = hero['verticalUrl'] ?? '';
              final tier = hero['tier'] ?? 'C';
              final lore = hero['lore'] ?? '';
              final playstyle = hero['playstyle'] ?? '';
              final roleDescription = hero['roleDescription'] ?? '';
              final description = hero['description'] ?? '';
              final abilities = (hero['abilities'] as List<dynamic>?) ?? [];

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/lore'),
                    ),
                    title: Text(heroName.toString().toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart),
                        tooltip: 'View Stats',
                        onPressed: () => context.go('/heroes/${widget.heroId}'),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                      child: _buildHeroBanner(
                          context, heroName, heroType, tier, iconUrl, bannerUrl, verticalUrl)),
                  if (lore.toString().isNotEmpty)
                    SliverToBoxAdapter(
                        child: _buildLoreSection(context, 'LORE', lore)),
                  if (playstyle.toString().isNotEmpty)
                    SliverToBoxAdapter(
                        child: _buildLoreSection(context, 'PLAYSTYLE', playstyle)),
                  if (roleDescription.toString().isNotEmpty)
                    SliverToBoxAdapter(
                        child: _buildLoreSection(context, 'ROLE', roleDescription)),
                  if (lore.toString().isEmpty &&
                      playstyle.toString().isEmpty &&
                      roleDescription.toString().isEmpty)
                    SliverToBoxAdapter(
                        child: _buildNoLore(context, description)),
                  if (abilities.isNotEmpty)
                    SliverToBoxAdapter(
                        child: _buildAbilitiesSection(context, abilities)),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              );
            },
          ),
        ),
      ),
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
          Text('Failed to load hero lore',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/lore'),
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
      String tier, String iconUrl, String bannerUrl, String verticalUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppTheme.glassDecoration.copyWith(
          border: Border.all(
            color: _tierColor(tier).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _tierColor(tier).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: bannerUrl.toString().isNotEmpty
                      ? Image.network(bannerUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              _buildFallbackHeroImage(iconUrl))
                      : verticalUrl.toString().isNotEmpty
                          ? Image.network(verticalUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _buildFallbackHeroImage(iconUrl))
                          : _buildFallbackHeroImage(iconUrl),
                ),
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _tierColor(tier).withValues(alpha: 0.3),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tierColor(tier).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _tierColor(tier).withValues(alpha: 0.5)),
                    ),
                    child: Text(tier,
                        style: TextStyle(
                            color: _tierColor(tier),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toString().toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      if (heroType.toString().isNotEmpty)
                        Text(heroType.toString().toUpperCase(),
                            style: TextStyle(
                                color:
                                    _tierColor(tier).withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackHeroImage(String iconUrl) {
    return Center(
      child: iconUrl.toString().isNotEmpty
          ? ClipOval(
              child: Image.network(iconUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, color: Colors.white24, size: 64)),
            )
          : const Icon(Icons.person, color: Colors.white24, size: 64),
    );
  }

  Widget _buildLoreSection(BuildContext context, String title, dynamic text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.accentColor,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              text.toString(),
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.7,
                  letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLore(BuildContext context, dynamic description) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ABOUT',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.accentColor,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              description.toString().isNotEmpty
                  ? description.toString()
                  : 'No lore information available for this hero yet.',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.7,
                  letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbilitiesSection(
      BuildContext context, List<dynamic> abilities) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ABILITIES',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.accentColor,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...abilities.map((ability) {
              final name = ability['name'] ?? ability['ability_name'] ?? 'Unknown';
              final icon = ability['icon'] ?? ability['ability_icon'] ?? '';
              final description = ability['description'] ?? ability['ability_description'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.surfaceColorLight,
                      ),
                      child: icon.toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(icon,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.star,
                                          color: AppTheme.accentColor,
                                          size: 20)),
                            )
                          : const Icon(Icons.star,
                              color: AppTheme.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          if (description.toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(description.toString(),
                                style: TextStyle(
                                    color: AppTheme.textSecondary
                                        .withValues(alpha: 0.8),
                                    fontSize: 12,
                                    height: 1.4)),
                          ],
                        ],
                      ),
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
}
