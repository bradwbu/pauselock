import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/services/auth_service.dart';
import 'package:pauselock_app/src/utils/formatters.dart';
import 'package:pauselock_app/src/services/local_storage_service.dart';


class HeroDetailPage extends StatefulWidget {
  final int heroId;
  const HeroDetailPage({super.key, required this.heroId});

  @override
  State<HeroDetailPage> createState() => _HeroDetailPageState();
}

class _HeroDetailPageState extends State<HeroDetailPage> {
  bool _isFavorite = false;
  String? _userVote;
  Map<String, dynamic>? _voteStats;
  bool _isVoting = false;
  int _selectedTab = 0;
  int _selectedAbility = 0;
  Map<int, Map<String, dynamic>> _itemsCache = {};

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _loadVoteData();
  }

  void _checkFavorite() {
    final favs = LocalStorageService.getFavoriteHeroes();
    setState(() => _isFavorite = favs.contains(widget.heroId));
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

  Future<void> _loadVoteData() async {
    final stats = await AuthService.getHeroVoteStats(widget.heroId);
    if (mounted && stats != null) setState(() => _voteStats = stats);
  }

  Future<void> _vote(String tier) async {
    if (!AuthService.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to vote')),
        );
      }
      return;
    }
    setState(() => _isVoting = true);
    try {
      if (_userVote == tier) {
        await AuthService.removeHeroVote(widget.heroId);
        setState(() => _userVote = null);
      } else {
        await AuthService.voteHero(widget.heroId, tier);
        setState(() => _userVote = tier);
      }
      await _loadVoteData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to vote')),
        );
      }
    }
    if (mounted) setState(() => _isVoting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          PauselockClient.getHeroById(widget.heroId),
          PauselockClient.getBuildsByHero(widget.heroId),
          PauselockClient.getAllItems(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return _buildErrorState(context);
          }

          final heroData = snapshot.data![0];
          final buildsData = snapshot.data![1] as List<dynamic>? ?? [];
          _itemsCache = (snapshot.data!.length > 2 && snapshot.data![2] is Map)
              ? Map<int, Map<String, dynamic>>.from(snapshot.data![2] as Map)
              : {};

          if (heroData == null) return _buildErrorState(context);

          final heroName = heroData['name'] ?? 'Unknown Hero';
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
          final winRate = asDouble(heroData['winRate']);
          final pickRate = asDouble(heroData['pickRate']);
          final banRate = asDouble(heroData['banRate']);
          final matchesPlayed = heroData['matchesPlayed'] ?? 0;
          final lore = heroData['lore'] ?? '';
          final playstyle = heroData['playstyle'] ?? '';
          final roleDescription = heroData['roleDescription'] ?? '';
          final description = heroData['description'] ?? '';

          return Column(
            children: [
              _buildHeader(context, heroName, heroType, tier, complexity, iconUrl, bannerUrl, winRate, pickRate, banRate, matchesPlayed),
              _buildTabBar(context),
              Expanded(
                child: _selectedTab == 0
                    ? _buildOverviewTab(context, baseHealth, baseDamage, heavyDamage, bulletDamage, moveSpeed, sprintSpeed, healthRegen, bulletArmor, techArmor, abilities, tier, heroData['adminTier'])
                    : _selectedTab == 1
                        ? _buildBuildsTab(context, buildsData)
                        : _buildLoreTab(context, lore, playstyle, roleDescription, description),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String heroType, String tier,
      int complexity, String iconUrl, String bannerUrl, double winRate, double pickRate,
      double banRate, dynamic matchesPlayed) {
    return Container(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bannerUrl.toString().isNotEmpty)
            Image.network(bannerUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceColor))
          else
            Container(color: AppTheme.surfaceColor),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  AppTheme.backgroundColor,
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 16,
            child: Row(
              children: [
                _buildStatPill('${formatPercent(winRate)} WR', AppTheme.successColor),
                const SizedBox(width: 6),
                _buildStatPill('${formatPercent(pickRate)} PR', AppTheme.primaryColor),
                const SizedBox(width: 6),
                _buildStatPill('TIER $tier', _tierColor(tier)),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _tierColor(tier), width: 2),
                  ),
                  child: ClipOval(
                    child: iconUrl.toString().isNotEmpty
                        ? Image.network(iconUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, color: Colors.white54, size: 32))
                        : Container(
                            color: AppTheme.surfaceColorMedium,
                            child: const Icon(Icons.person, color: Colors.white54, size: 32)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(name.toString().toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleFavorite,
                            child: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? AppTheme.errorColor : AppTheme.textMuted,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (heroType.toString().isNotEmpty)
                            Text(heroType.toString().toUpperCase(),
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
                          const SizedBox(width: 8),
                          ...List.generate(complexity, (_) => Icon(Icons.star, size: 10, color: AppTheme.warningColor)),
                          const SizedBox(width: 6),
                          Text('$matchesPlayed matches',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: () => context.go('/heroes'),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = ['Overview & Abilities', 'Builds', 'Lore'];
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, int health, int lightMelee, int heavyMelee,
      int bulletDmg, double moveSpeed, double sprintSpeed, double healthRegen,
      double bulletArmor, double techArmor, List<dynamic> abilities, String tier, String? adminTier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildBaseStats(context, health, lightMelee, heavyMelee, bulletDmg, moveSpeed, sprintSpeed, healthRegen, bulletArmor, techArmor),
                      const SizedBox(height: 12),
                      _buildTierVoting(context, tier, adminTier),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildAbilitiesSection(context, abilities),
                ),
              ],
            );
          }
          return Column(
            children: [
              _buildAbilitiesSection(context, abilities),
              const SizedBox(height: 12),
              _buildBaseStats(context, health, lightMelee, heavyMelee, bulletDmg, moveSpeed, sprintSpeed, healthRegen, bulletArmor, techArmor),
              const SizedBox(height: 12),
              _buildTierVoting(context, tier, adminTier),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBaseStats(BuildContext context, int health, int lightMelee, int heavyMelee,
      int bulletDmg, double moveSpeed, double sprintSpeed, double healthRegen,
      double bulletArmor, double techArmor) {
    final stats = [
      ('Max Health', '$health', AppTheme.errorColor),
      ('Bullet Damage', '$bulletDmg', AppTheme.primaryColor),
      ('Light Melee', '$lightMelee', AppTheme.warningColor),
      ('Heavy Melee', '$heavyMelee', AppTheme.warningColor),
      ('Move Speed', '${moveSpeed.toStringAsFixed(1)} m/s', AppTheme.accentColor),
      ('Sprint Speed', '${sprintSpeed.toStringAsFixed(1)} m/s', AppTheme.accentColor),
      ('Health Regen', '${healthRegen.toStringAsFixed(1)}/s', AppTheme.successColor),
      ('Bullet Armor', '${(bulletArmor * 100).toStringAsFixed(0)}%', Colors.blue),
      ('Tech Armor', '${(techArmor * 100).toStringAsFixed(0)}%', AppTheme.secondaryColor),
    ];
    return Container(
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text('BASE STATS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          ...stats.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: i.isEven ? Colors.transparent : AppTheme.surfaceColorLight.withValues(alpha: 0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.$1, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(s.$2, style: TextStyle(color: s.$3, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAbilitiesSection(BuildContext context, List<dynamic> abilities) {
    if (abilities.isEmpty) return const SizedBox.shrink();
    final clampedIndex = _selectedAbility.clamp(0, abilities.length - 1);
    final selected = abilities[clampedIndex];
    final selectedMap = selected is Map ? selected : {'name': selected.toString()};
    final selectedName = selectedMap['name'] ?? selected.toString();
    final selectedDesc = selectedMap['description'] ?? '';
    final selectedCooldown = selectedMap['cooldown'] ?? selectedMap['Cooldown'] ?? '';
    final selectedRange = selectedMap['castRange'] ?? selectedMap['Cast Range'] ?? '';
    final selectedDuration = selectedMap['duration'] ?? selectedMap['Duration'] ?? '';

    return Container(
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text('ABILITIES', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: abilities.length,
              itemBuilder: (context, index) {
                final ability = abilities[index];
                final abilityMap = ability is Map ? ability : {'name': ability.toString()};
                final name = abilityMap['name'] ?? ability.toString();
                final iconUrl = abilityMap['icon'] ?? abilityMap['ability_icon'] ?? '';
                final isSelected = index == clampedIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAbility = index),
                  child: Container(
                    width: 64,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.15) : AppTheme.surfaceColorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 1)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: iconUrl.toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(iconUrl, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.flash_on, color: AppTheme.primaryColor, size: 18)),
                                )
                              : Icon(Icons.flash_on, color: AppTheme.primaryColor, size: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontSize: 8,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selectedName.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                if (selectedDesc.toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(selectedDesc.toString(), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5)),
                ],
                if (selectedCooldown.toString().isNotEmpty || selectedRange.toString().isNotEmpty || selectedDuration.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColorLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        if (selectedCooldown.toString().isNotEmpty)
                          _buildAbilityStat('Cooldown', '${selectedCooldown}s'),
                        if (selectedCooldown.toString().isNotEmpty && selectedRange.toString().isNotEmpty)
                          Container(width: 1, height: 14, color: AppTheme.borderColor, margin: const EdgeInsets.symmetric(horizontal: 10)),
                        if (selectedRange.toString().isNotEmpty)
                          _buildAbilityStat('Cast Range', '$selectedRange'),
                        if ((selectedCooldown.toString().isNotEmpty || selectedRange.toString().isNotEmpty) && selectedDuration.toString().isNotEmpty)
                          Container(width: 1, height: 14, color: AppTheme.borderColor, margin: const EdgeInsets.symmetric(horizontal: 10)),
                        if (selectedDuration.toString().isNotEmpty)
                          _buildAbilityStat('Duration', '${selectedDuration}s'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityStat(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTierVoting(BuildContext context, String currentTier, String? adminTier) {
    const tiers = ['S+', 'S', 'A', 'B', 'C'];
    final tierColors = {
      'S+': const Color(0xFFFF4466),
      'S': const Color(0xFFFF9900),
      'A': const Color(0xFF00D4FF),
      'B': const Color(0xFF00FF88),
      'C': const Color(0xFFA0AABF),
    };
    final totalVotes = _voteStats?['totalVotes'] ?? 0;
    final tierCounts = _voteStats?['tierCounts'] as Map<String, dynamic>? ?? {};

    return Container(
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Text('COMMUNITY TIER', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const Spacer(),
                if (adminTier != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text('Admin: $adminTier', style: TextStyle(color: AppTheme.primaryColor, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: _tierColor(currentTier).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text('Final: $currentTier', style: TextStyle(color: _tierColor(currentTier), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (totalVotes > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Text('$totalVotes vote${totalVotes == 1 ? '' : 's'}',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ),
          const SizedBox(height: 8),
          ...tiers.map((tier) {
            final count = tierCounts[tier] ?? 0;
            final pct = totalVotes > 0 ? (count / totalVotes) : 0.0;
            final isSelected = _userVote == tier;
            return GestureDetector(
              onTap: _isVoting ? null : () => _vote(tier),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                color: isSelected ? tierColors[tier]!.withValues(alpha: 0.08) : null,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(tier, style: TextStyle(color: tierColors[tier], fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppTheme.surfaceColorLight,
                          valueColor: AlwaysStoppedAnimation<Color>(tierColors[tier]!.withValues(alpha: 0.7)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 32,
                      child: Text('${(pct * 100).round()}%', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (!AuthService.isLoggedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Text('Sign in to vote', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontStyle: FontStyle.italic)),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBuildsTab(BuildContext context, List<dynamic> builds) {
    if (builds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, color: AppTheme.textMuted, size: 40),
            const SizedBox(height: 12),
            Text('No builds available yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: builds.length,
      itemBuilder: (context, index) {
        final build = builds[index];
        final details = (build['itemDetails'] as List<dynamic>?) ?? [];
        for (final detail in details) {
          if (detail is Map && detail['id'] != null) {
            final id = detail['id'] is int ? detail['id'] : int.tryParse('${detail['id']}') ?? 0;
            if (id > 0 && !_itemsCache.containsKey(id)) {
              _itemsCache[id] = Map<String, dynamic>.from(detail);
            }
          }
        }
        final itemIds = (build['itemIds'] as List<dynamic>?) ?? [];
        final itemNames = (build['items'] as List<dynamic>?) ?? [];

        return GestureDetector(
          onTap: () => context.go('/build/${build['id']}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.glassDecoration,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.build, color: AppTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(build['buildName'] ?? 'Unknown Build', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('By ${build['author'] ?? 'Unknown'}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(itemIds.length.clamp(0, 6), (i) {
                          final id = itemIds[i];
                          final intId = int.tryParse('$id') ?? 0;
                          final item = _itemsCache[intId];
                          final imageUrl = item?['imageUrl']?.toString() ?? '';
                          final itemName = item?['name']?.toString() ?? (i < itemNames.length ? '${itemNames[i]}' : 'Item');
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColorMedium,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  Image.network(imageUrl, width: 10, height: 10,
                                      errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, size: 10, color: AppTheme.textMuted))
                                else
                                  Icon(Icons.inventory_2, size: 10, color: AppTheme.textMuted),
                                const SizedBox(width: 3),
                                Text(itemName, style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatCompactNumber(build['matchesPlayed']),
                        style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('uses', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoreTab(BuildContext context, dynamic lore, dynamic playstyle, dynamic roleDescription, dynamic description) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lore.toString().isNotEmpty)
            _buildLoreSection('LORE', lore),
          if (playstyle.toString().isNotEmpty)
            _buildLoreSection('PLAYSTYLE', playstyle),
          if (roleDescription.toString().isNotEmpty)
            _buildLoreSection('ROLE', roleDescription),
          if (lore.toString().isEmpty && playstyle.toString().isEmpty && roleDescription.toString().isEmpty)
            _buildLoreSection('ABOUT', description.toString().isNotEmpty ? description : 'No lore available for this hero yet.'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.go('/lore/${widget.heroId}'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories, color: AppTheme.accentColor, size: 16),
                  const SizedBox(width: 8),
                  Text('View Full Lore Page', style: TextStyle(color: AppTheme.accentColor, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoreSection(String title, dynamic text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(text.toString(), style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 40),
          const SizedBox(height: 12),
          Text('Failed to load hero data', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => context.go('/heroes'), child: const Text('Go Back')),
        ],
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'S+': return const Color(0xFFFF4466);
      case 'S': return const Color(0xFFFF9900);
      case 'A': return const Color(0xFF00D4FF);
      case 'B': return const Color(0xFF00FF88);
      case 'C': return const Color(0xFFA0AABF);
      default: return AppTheme.textSecondary;
    }
  }
}
