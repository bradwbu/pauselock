import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/local_storage_service.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int? _accountId;
  Map<String, dynamic>? _playerStats;
  List<Map<String, dynamic>> _favoriteHeroes = [];
  List<Map<String, dynamic>> _favoriteBuilds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    _accountId = LocalStorageService.getAccountId();
    
    if (_accountId != null) {
      _playerStats = await PauselockClient.getPlayerStats(_accountId!);
    } else {
      _playerStats = null;
    }

    final heroIds = LocalStorageService.getFavoriteHeroes();
    final buildIds = LocalStorageService.getFavoriteBuilds();

    final List<Map<String, dynamic>> heroes = [];
    for (final id in heroIds) {
      final hero = await PauselockClient.getHeroById(id);
      if (hero != null) heroes.add(hero);
    }

    final List<Map<String, dynamic>> builds = [];
    for (final id in buildIds) {
      final build = await PauselockClient.getBuildById(id);
      if (build != null) builds.add(build);
    }

    if (mounted) {
      setState(() {
        _favoriteHeroes = heroes;
        _favoriteBuilds = builds;
        _isLoading = false;
      });
    }
  }

  void _linkAccount() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Link Steam Account', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter Steam ID or exact name',
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Link'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      final query = result.trim();
      final numericId = int.tryParse(query);
      
      int? foundId;
      if (numericId != null) {
        foundId = numericId;
      } else {
        final players = await PauselockClient.searchPlayers(query);
        if (players != null && players.isNotEmpty) {
          foundId = players.first['accountId'];
        }
      }

      if (foundId != null) {
        await LocalStorageService.setAccountId(foundId);
        await _loadProfile();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account not found.')),
          );
        }
      }
    }
  }

  void _unlinkAccount() async {
    await LocalStorageService.setAccountId(null);
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/'),
                    ),
                    title: ShaderMask(
                      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                      child: const Text('PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadProfile,
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(child: _buildProfileHeader(context)),
                  SliverToBoxAdapter(child: _buildSavedBuilds(context)),
                  SliverToBoxAdapter(child: _buildFavoriteHeroes(context)),
                  SliverToBoxAdapter(child: _buildAccountActions(context)),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: _playerStats != null && _playerStats!['avatarUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(_playerStats!['avatarUrl'], fit: BoxFit.cover),
                        )
                      : const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                if (_accountId == null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_playerStats != null ? _playerStats!['playerName'] : 'Guest Player', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(_accountId != null ? 'Steam ID: $_accountId' : 'Not Linked', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (_playerStats != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text('Rank: ${_playerStats!['rank'] ?? 0}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_esports, size: 16, color: AppTheme.accentColor),
                        const SizedBox(width: 4),
                        Text('${_playerStats!['totalMatches'] ?? 0} matches', style: const TextStyle(color: AppTheme.accentColor, fontSize: 12)),
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

  Widget _buildSavedBuilds(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SAVED BUILDS', style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: () => context.go('/builds'), child: const Text('Browse')),
              ],
            ),
            const SizedBox(height: 12),
            if (_favoriteBuilds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No saved builds yet.', style: TextStyle(color: Colors.white54)),
              )
            else
              ..._favoriteBuilds.map((build) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.glassDecorationSmall,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.build, color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/build/${build['id']}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(build['buildName'] ?? 'Unknown', style: Theme.of(context).textTheme.titleSmall),
                            Text(build['heroName'] ?? 'Unknown Hero', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppTheme.errorColor,
                      onPressed: () async {
                        await LocalStorageService.removeFavoriteBuild(build['id']);
                        _loadProfile();
                      },
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteHeroes(BuildContext context) {
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
                Text('FAVORITE HEROES', style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: () => context.go('/heroes'), child: const Text('Browse')),
              ],
            ),
            const SizedBox(height: 12),
            if (_favoriteHeroes.isEmpty)
              const Text('No favorite heroes yet.', style: TextStyle(color: Colors.white54))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _favoriteHeroes.map((hero) => GestureDetector(
                  onTap: () => context.go('/heroes/${hero['id']}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: AppTheme.glassDecorationSmall,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: hero['iconUrl'] != null && hero['iconUrl'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(hero['iconUrl'], fit: BoxFit.cover),
                              )
                            : const Icon(Icons.person, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(hero['name'] ?? 'Unknown', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () async {
                            await LocalStorageService.removeFavoriteHero(hero['id']);
                            _loadProfile();
                          },
                          child: const Icon(Icons.close, size: 14, color: AppTheme.errorColor),
                        )
                      ],
                    ),
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_accountId == null)
            ListTile(
              leading: const Icon(Icons.link, color: AppTheme.primaryColor),
              title: Text('Link Steam Account', style: Theme.of(context).textTheme.titleSmall),
              trailing: const Icon(Icons.chevron_right),
              onTap: _linkAccount,
              tileColor: AppTheme.surfaceColorLight.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )
          else
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: Text('Unlink Account', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.errorColor)),
              onTap: _unlinkAccount,
              tileColor: AppTheme.surfaceColorLight.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
        ],
      ),
    );
  }
}
