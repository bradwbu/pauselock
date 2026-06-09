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
  final List<String> _roles = ['All', 'Carry', 'Support', 'Tank', 'Assassin', 'Mage'];
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
                _buildMetaStat('Most Picked', _heroes.isNotEmpty ? _heroes.reduce((a, b) => (a['pickRate'] ?? 0) > (b['pickRate'] ?? 0) ? a : b)['name'] ?? 'Lash' : 'Lash', '${_heroes.isNotEmpty ? _heroes.reduce((a, b) => (a['pickRate'] ?? 0) > (b['pickRate'] ?? 0) ? a : b)['pickRate'] ?? 18 : 18}%'),
                _buildMetaStat('Highest WR', _heroes.isNotEmpty ? _heroes.reduce((a, b) => (a['winRate'] ?? 0) > (b['winRate'] ?? 0) ? a : b)['name'] ?? 'Kelvin' : 'Kelvin', '${_heroes.isNotEmpty ? _heroes.reduce((a, b) => (a['winRate'] ?? 0) > (b['winRate'] ?? 0) ? a : b)['winRate'] ?? 55.2 : 55.2}%'),
                _buildMetaStat('Most Banned', _heroes.isNotEmpty ? _heroes.reduce((a, b) => (a['banRate'] ?? 0) > (b['banRate'] ?? 0) ? a : b)['name'] ?? 'Haze' : 'Haze', '${_heroes.isNotEmpty ? _heroes.reduce((a, b) => (a['banRate'] ?? 0) > (b['banRate'] ?? 0) ? a : b)['banRate'] ?? 25 : 25}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaStat(String label, String value, String stat) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.primaryColor)),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
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
            Text(name, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
            Text(role, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(winRate, style: TextStyle(color: wr > 50 ? AppTheme.successColor : AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

