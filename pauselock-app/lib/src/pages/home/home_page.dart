import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/utils/formatters.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _featuredBuilds = [];
  List<dynamic> _metaHeroes = [];
  Map<String, dynamic>? _globalStats;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final builds = await PauselockClient.getFeaturedBuilds(limit: 5);
      final heroes = await PauselockClient.getAllHeroes(filter: {'limit': 6});
      final globalStats = await PauselockClient.getGlobalStats();
      setState(() {
        _featuredBuilds = builds ?? [];
        _metaHeroes = heroes ?? [];
        _globalStats = globalStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _error != null && !_isLoading
                ? _buildErrorState()
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeroSection(context)),
                      SliverToBoxAdapter(child: _buildStatsOverview(context)),
                      SliverToBoxAdapter(child: _buildFeaturedBuilds(context)),
                      SliverToBoxAdapter(child: _buildMetaHeroes(context)),
                      SliverToBoxAdapter(child: _buildFooter(context)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'PAUSELOCK',
              style: GoogleFonts.orbitron(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 8,
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
          const SizedBox(height: 16),
          Text(
            'Track Your Deadlock Stats',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 40),
          Container(
            decoration: AppTheme.glassDecoration,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search player...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        context.go('/search?q=${Uri.encodeComponent(value.trim())}');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final q = _searchController.text.trim();
                    if (q.isNotEmpty) {
                      context.go('/search?q=${Uri.encodeComponent(q)}');
                    } else {
                      context.go('/search');
                    }
                  },
                  child: const Text('Search'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).scale(),
          const SizedBox(height: 30),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildNavCard(context, 'Stats', Icons.bar_chart, '/stats'),
              _buildNavCard(context, 'Builds', Icons.build, '/builds'),
              _buildNavCard(context, 'Heroes', Icons.shield, '/heroes'),
              _buildNavCard(
                  context, 'Leaderboard', Icons.leaderboard, '/leaderboard'),
            ],
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildNavCard(
      BuildContext context, String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration,
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 36),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context) {
    final stats = _globalStats ?? const {};
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GLOBAL STATS', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Known Players',
                      formatCompactNumber(stats['activePlayers']),
                      Icons.people)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'Analyzed Matches',
                      formatCompactNumber(stats['matchesToday']),
                      Icons.sports_esports)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'Avg Win Rate',
                      formatPercent(stats['averageWinRate']),
                      Icons.trending_up)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecorationSmall,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildFeaturedBuilds(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_featuredBuilds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FEATURED BUILDS',
                  style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                  onPressed: () => context.go('/builds'),
                  child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredBuilds.length,
              itemBuilder: (context, index) {
                final build = _featuredBuilds[index];
                return InkWell(
                  onTap: () => context.go('/build/${build['id']}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: AppTheme.glassDecoration,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColorLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                              child: Icon(Icons.build,
                                  color: AppTheme.primaryColor, size: 40)),
                        ),
                        const SizedBox(height: 12),
                        Text(build['buildName'] ?? 'Unknown Build',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(build['heroName'] ?? 'Unknown Hero',
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.thumb_up,
                                size: 16, color: AppTheme.successColor),
                            const SizedBox(width: 4),
                            Text(formatCompactNumber(build['upvotes']),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)),
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

  Widget _buildMetaHeroes(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_metaHeroes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('META HEROES',
                  style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                  onPressed: () => context.go('/heroes'),
                  child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _metaHeroes
                .map((hero) => GestureDetector(
                      onTap: () => context.go('/heroes/${hero['id']}'),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.glassDecorationSmall,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person,
                                  color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(hero['name'] ?? 'Unknown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall),
                                  Text('${hero['winRate'] ?? 0}% WR',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppTheme.successColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          '© 2026 Pauselock - Unofficial Deadlock Stats Tracker',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.errorColor, size: 64),
            const SizedBox(height: 16),
            Text('Connection Error',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_error ?? 'Something went wrong',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
