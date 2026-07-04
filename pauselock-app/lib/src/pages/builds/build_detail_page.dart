import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/services/local_storage_service.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/utils/formatters.dart';

class BuildDetailPage extends StatefulWidget {
  final int buildId;

  const BuildDetailPage({super.key, required this.buildId});

  @override
  State<BuildDetailPage> createState() => _BuildDetailPageState();
}

class _BuildDetailPageState extends State<BuildDetailPage> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  void _checkFavorite() {
    final favs = LocalStorageService.getFavoriteBuilds();
    setState(() {
      _isFavorite = favs.contains(widget.buildId);
    });
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
      await LocalStorageService.removeFavoriteBuild(widget.buildId);
    } else {
      await LocalStorageService.addFavoriteBuild(widget.buildId);
    }
    _checkFavorite();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Removed from saved builds' : 'Added to saved builds'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: PauselockClient.getBuildById(widget.buildId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
              }
              final build = snapshot.data;
              if (snapshot.hasError || build == null) {
                return _buildError(context);
              }

              final items = (build['itemIds'] as List<dynamic>?) ?? const [];
              final tags = (build['tags'] as List<dynamic>?) ?? const [];
              final totalCost = items.fold<int>(0, (sum, item) {
                if (item is Map) return sum + (item['cost'] ?? 0) as int;
                return sum;
              });

              final weaponItems = _filterBySlot(items, 'weapon');
              final spiritItems = _filterBySlot(items, 'spirit');
              final vitalityItems = _filterBySlot(items, 'vitality');
              final otherItems = _filterOther(items, ['weapon', 'spirit', 'vitality']);

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/builds');
                        }
                      },
                    ),
                    title: Text(
                      '${build['heroName'] ?? 'Hero'} Build',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.star : Icons.star_border,
                          color: _isFavorite ? AppTheme.primaryColor : Colors.white,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(child: _buildHeader(context, build)),
                  SliverToBoxAdapter(child: _buildStats(context, build, items.length, totalCost)),
                  SliverToBoxAdapter(child: _buildDescription(context, build)),
                  if (weaponItems.isNotEmpty)
                    SliverToBoxAdapter(child: _buildSlotSection(context, 'Weapon', Icons.gps_fixed, AppTheme.primaryColor, weaponItems)),
                  if (spiritItems.isNotEmpty)
                    SliverToBoxAdapter(child: _buildSlotSection(context, 'Spirit', Icons.auto_awesome, AppTheme.secondaryColor, spiritItems)),
                  if (vitalityItems.isNotEmpty)
                    SliverToBoxAdapter(child: _buildSlotSection(context, 'Vitality', Icons.favorite, AppTheme.successColor, vitalityItems)),
                  if (otherItems.isNotEmpty)
                    SliverToBoxAdapter(child: _buildSlotSection(context, 'Other', Icons.category, AppTheme.accentColor, otherItems)),
                  if (tags.isNotEmpty)
                    SliverToBoxAdapter(child: _buildTags(context, tags)),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterBySlot(List<dynamic> items, String slotType) {
    return items.whereType<Map<String, dynamic>>().where((item) {
      final slot = '${item['slotType'] ?? ''}'.toLowerCase();
      return slot == slotType;
    }).toList();
  }

  List<Map<String, dynamic>> _filterOther(List<dynamic> items, List<String> excludeSlots) {
    final excludeSet = excludeSlots.map((s) => s.toLowerCase()).toSet();
    return items.whereType<Map<String, dynamic>>().where((item) {
      final slot = '${item['slotType'] ?? ''}'.toLowerCase();
      return slot.isNotEmpty && !excludeSet.contains(slot);
    }).toList();
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> build) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      build['heroIconUrl'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(build['buildName'] ?? 'Untitled Build',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                          '${build['heroName'] ?? 'Unknown Hero'} · ${build['author'] ?? 'Unknown Author'}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (build['heroId'] != null)
                  TextButton.icon(
                    onPressed: () => context.go('/heroes/${build['heroId']}'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View Hero'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, Map<String, dynamic> build, int itemCount, int totalCost) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _metric(context, Icons.star,
              formatCompactNumber(build['upvotes']), 'favorites'),
          const SizedBox(width: 12),
          _metric(context, Icons.trending_up,
              formatCompactNumber(build['matchesPlayed']), 'weekly'),
          const SizedBox(width: 12),
          _metric(context, Icons.percent,
              formatPercent(build['winRate']), 'win rate'),
          const SizedBox(width: 12),
          _metric(context, Icons.attach_money,
              formatCompactNumber(totalCost), 'total cost'),
        ],
      ),
    );
  }

  Widget _metric(
      BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.glassDecorationSmall,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context, Map<String, dynamic> build) {
    final description = '${build['description'] ?? ''}'.trim();
    if (description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(16),
        child: Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildSlotSection(
      BuildContext context, String slotName, IconData slotIcon, Color slotColor, List<Map<String, dynamic>> items) {
    final totalSlotCost = items.fold<int>(0, (sum, item) => sum + (item['cost'] ?? 0) as int);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(slotIcon, color: slotColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '$slotName (${items.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: slotColor),
              ),
              const Spacer(),
              Text(
                '${formatCompactNumber(totalSlotCost)} souls',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: slotColor.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) => _buildItemCard(context, item, slotColor)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item, Color slotColor) {
    final name = item['name']?.toString() ?? 'Unknown Item';
    final imageUrl = item['imageUrl']?.toString() ?? '';
    final cost = item['cost'] ?? 0;
    final tier = item['tier'] ?? 1;

    final tierColor = switch (tier) {
      1 => Colors.grey,
      2 => AppTheme.primaryColor,
      3 => AppTheme.secondaryColor,
      4 => AppTheme.accentColor,
      _ => Colors.grey,
    };

    return Container(
      width: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tierColor.withValues(alpha: 0.5), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Icon(Icons.category, size: 20, color: tierColor),
                    )
                  : Icon(Icons.category, size: 20, color: tierColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _tierBadge(tier, tierColor),
                    const SizedBox(width: 6),
                    Text(
                      '${formatCompactNumber(cost)}s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierBadge(int tier, Color color) {
    final labels = {1: 'I', 2: 'II', 3: 'III', 4: 'IV'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        labels[tier] ?? '$tier',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTags(BuildContext context, List<dynamic> tags) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) => Chip(
          label: Text('$tag'),
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          labelStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        )).toList(),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load build',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Build #${widget.buildId} not found',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () => context.go('/builds'),
              child: const Text('Back to Builds')),
        ],
      ),
    );
  }
}
