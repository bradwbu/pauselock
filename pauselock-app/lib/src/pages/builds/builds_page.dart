import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/utils/formatters.dart';
import 'package:shimmer/shimmer.dart';

class BuildsPage extends StatefulWidget {
  final int? heroId;
  const BuildsPage({super.key, this.heroId});

  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  String _sortBy = 'winRate';
  bool _featuredOnly = false;
  List<dynamic> _featuredBuilds = [];
  List<dynamic> _allBuilds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuilds();
  }

  Future<void> _loadBuilds() async {
    setState(() => _isLoading = true);
    final featured = await PauselockClient.getFeaturedBuilds(limit: 3);
    final builds = await PauselockClient.getBuilds(filter: {
      'sortBy': _sortBy,
      'featuredOnly': _featuredOnly,
      if (widget.heroId != null) 'heroId': widget.heroId,
    });
    setState(() {
      _featuredBuilds = featured ?? [];
      _allBuilds = builds ?? [];
      _isLoading = false;
    });
  }

  List<dynamic> get _filteredBuilds {
    var builds = _allBuilds;
    if (_featuredOnly) {
      builds = builds.where((b) => b['isFeatured'] == true).toList();
    }
    if (_sortBy == 'winRate') {
      builds.sort((a, b) => (b['winRate'] ?? 0).compareTo(a['winRate'] ?? 0));
    } else if (_sortBy == 'popularity') {
      builds.sort((a, b) =>
          (b['matchesPlayed'] ?? 0).compareTo(a['matchesPlayed'] ?? 0));
    } else if (_sortBy == 'recent') {
      builds.sort(
          (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
    }
    return builds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadBuilds,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  title: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: const Text('BUILDS',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
                SliverToBoxAdapter(child: _buildFilters(context)),
                SliverToBoxAdapter(child: _buildFeaturedSection(context)),
                if (_isLoading)
                  SliverList(
                    delegate: SliverChildListDelegate([
                      _buildLoadingCard(),
                      _buildLoadingCard(),
                      _buildLoadingCard(),
                    ]),
                  )
                else
                  SliverList(
                    delegate: SliverChildListDelegate(
                      _filteredBuilds
                          .map((build) => _buildBuildCard(
                                context,
                                asInt(build['id']),
                                build['buildName'] ?? 'Unknown Build',
                                build['heroName'] ?? 'Unknown Hero',
                                formatCompactNumber(build['upvotes']),
                                '${build['matchesPlayed'] ?? 0}',
                                build['isFeatured'] ?? false,
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceColorLight,
      highlightColor: AppTheme.surfaceColor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppTheme.glassDecorationSmall,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text('Sort by:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            _buildFilterChip('Win Rate', _sortBy == 'winRate',
                () => setState(() => _sortBy = 'winRate')),
            const SizedBox(width: 8),
            _buildFilterChip('Popularity', _sortBy == 'popularity',
                () => setState(() => _sortBy = 'popularity')),
            const SizedBox(width: 8),
            _buildFilterChip('Recent', _sortBy == 'recent',
                () => setState(() => _sortBy = 'recent')),
            const Spacer(),
            FilterChip(
              label: const Text('Featured'),
              selected: _featuredOnly,
              onSelected: (val) => setState(() => _featuredOnly = val),
              backgroundColor: AppTheme.surfaceColorLight,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                  color: _featuredOnly
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        _loadBuilds();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppTheme.primaryColor : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                color:
                    selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    if (_featuredBuilds.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FEATURED BUILDS',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredBuilds.length,
              itemBuilder: (context, index) {
                final build = _featuredBuilds[index];
                return InkWell(
                  onTap: () => context.go('/build/${build['id']}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: AppTheme.glassDecoration,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                              child: Icon(Icons.build,
                                  color: Colors.white, size: 40)),
                        ),
                        const SizedBox(height: 12),
                        Text(build['buildName'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleSmall),
                        Text('By ${build['author'] ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.thumb_up,
                                size: 14, color: AppTheme.successColor),
                            const SizedBox(width: 4),
                            Text(formatCompactNumber(build['upvotes']),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.successColor)),
                            const Spacer(),
                            Text(
                                '${formatCompactNumber(build['matchesPlayed'])} weekly',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildCard(BuildContext context, int id, String name, String hero,
      String favorites, String matches, bool isFeatured) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AppTheme.glassDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield, color: Colors.white),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(name,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis),
            ),
            if (isFeatured) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('FEATURED',
                    style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle:
            Text('Hero: $hero', style: Theme.of(context).textTheme.bodySmall),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(favorites,
                style: const TextStyle(
                    color: AppTheme.successColor, fontWeight: FontWeight.bold)),
            Text('${formatCompactNumber(matches)} weekly',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        onTap: () => context.go('/build/$id'),
      ),
    );
  }
}
