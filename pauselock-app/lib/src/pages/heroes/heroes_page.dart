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
  // Updated roles based on Deadlock internal classifications
  final List<String> _roles = ['All', 'Assassin', 'Brawler', 'Marksman', 'Mystic'];
  List<dynamic> _heroes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeroes();
  }

  Future<void> _loadHeroes() async {
    setState(() => _isLoading = true);
    final heroes = await PauselockClient.getAllHeroes();
    setState(() {
      _heroes = heroes ?? [];
      _isLoading = false;
    });
  }

  List<dynamic> get _filteredHeroes {
    if (_selectedRole == 'All') return _heroes;
    return _heroes.where((h) {
      final roles = h['roles'] as List<dynamic>? ?? [];
      return roles.any((r) => r.toString().toLowerCase() == _selectedRole.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: ShaderMask(
                  shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                  child: const Text('HEROES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadHeroes,
                  ),
                ],
              ),
              SliverToBoxAdapter(child: _buildRoleFilters(context)),
              SliverToBoxAdapter(child: _buildMetaOverview(context)),
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildListDelegate(List.generate(9, (index) => _buildLoadingCard())),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildListDelegate(
                      _filteredHeroes.map((hero) => _buildHeroCard(
                        context,
                        hero['name'] ?? 'Unknown',
                        (hero['roles'] as List<dynamic>?)?.first?.toString() ?? 'Unknown',
                        '${hero['winRate'] ?? 0}%',
                        (hero['popularity'] ?? 0) > 80,
                        hero['id'] ?? 0,
                      )).toList(),
                    ),
                  ),
                ),
            ],
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
        decoration: AppTheme.glassDecoration,
      ),
    );
  }

  Widget _buildRoleFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _roles.length,
          itemBuilder: (context, index) {
            final role = _roles[index];
            final isSelected = role == _selectedRole;
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : AppTheme.surfaceColorLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(role, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetaOverview(BuildContext context) {
    if (_heroes.isEmpty) return const SizedBox.shrink();
    
    final mostPicked = _heroes.reduce((a, b) => (a['pickRate'] ?? 0) > (b['pickRate'] ?? 0) ? a : b);
    final highestWr = _heroes.reduce((a, b) => (a['winRate'] ?? 0) > (b['winRate'] ?? 0) ? a : b);
    final mostBanned = _heroes.reduce((a, b) => (a['banRate'] ?? 0) > (b['banRate'] ?? 0) ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('META OVERVIEW', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetaStat('Most Picked', mostPicked['name'] ?? 'Lash', '${mostPicked['pickRate'] ?? 18}%', mostPicked['id'] ?? 0),
                _buildMetaStat('Highest WR', highestWr['name'] ?? 'Kelvin', '${highestWr['winRate'] ?? 55.2}%', highestWr['id'] ?? 0),
                _buildMetaStat('Most Banned', mostBanned['name'] ?? 'Haze', '${mostBanned['banRate'] ?? 25}%', mostBanned['id'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaStat(String label, String value, String stat, int heroId) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor, width: 2),
          ),
          child: ClipOval(
            child: Image.network(
              'https://assets.deadlock-api.com/images/heroes/$heroId.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const Icon(Icons.person, color: Colors.white54),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
        Text(stat, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.successColor)),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, String name, String role, String winRate, bool isPopular, int heroId) {
    final wr = double.tryParse(winRate.replaceAll('%', '')) ?? 0;
    return GestureDetector(
      onTap: () => context.go('/heroes/$heroId'),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      'https://assets.deadlock-api.com/images/heroes/$heroId.png',
                      errorBuilder: (context, error, stack) => const Icon(Icons.person, color: Colors.white54),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
                    child: const Icon(Icons.star, size: 10, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(name, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(role, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(winRate, style: TextStyle(color: wr > 50 ? AppTheme.successColor : AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
