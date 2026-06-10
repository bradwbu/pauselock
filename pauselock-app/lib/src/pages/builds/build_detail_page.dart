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

              final itemIds = (build['itemIds'] as List<dynamic>?) ?? const [];
              final tags = (build['tags'] as List<dynamic>?) ?? const [];
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
                  SliverToBoxAdapter(child: _buildDescription(context, build)),
                  SliverToBoxAdapter(child: _buildItemGrid(context, itemIds)),
                  if (tags.isNotEmpty)
                    SliverToBoxAdapter(child: _buildTags(context, tags)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> build) {
    final heroId = build['heroId'] ?? 0;
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
                      'https://assets.deadlock-api.com/images/heroes/$heroId.png',
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
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _metric(context, Icons.star,
                    formatCompactNumber(build['upvotes']), 'favorites'),
                const SizedBox(width: 16),
                _metric(context, Icons.trending_up,
                    formatCompactNumber(build['matchesPlayed']), 'weekly'),
                const SizedBox(width: 16),
                _metric(
                    context,
                    Icons.inventory_2,
                    '${((build['itemIds'] as List?) ?? const []).length}',
                    'items'),
              ],
            ),
          ],
        ),
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
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(16),
        child: Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildItemGrid(BuildContext context, List<dynamic> itemIds) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BUILD ITEMS', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: itemIds.take(48).map((itemData) {
              final id = itemData is Map ? itemData['id'] : itemData;
              final name = itemData is Map ? itemData['name'] : 'Item $id';
              
              return Container(
                width: 160,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          'https://assets.deadlock-api.com/images/items/$id.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => const Icon(Icons.category, size: 16, color: AppTheme.secondaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context, List<dynamic> tags) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) => Chip(
          label: Text('$tag'),
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
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
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () => context.go('/builds'),
              child: const Text('Back to Builds')),
        ],
      ),
    );
  }
}
