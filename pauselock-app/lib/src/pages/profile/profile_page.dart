import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/local_storage_service.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/services/auth_service.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      _accountId = LocalStorageService.getAccountId();
      
      // If no local accountId, check for linked Steam account
      if (_accountId == null && AuthService.isLoggedIn) {
        _accountId = AuthService.currentUser?['steamAccountId'];
      }
      
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
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
    final isLoggedIn = AuthService.isLoggedIn;
    final username = AuthService.currentUser?['username'];
    final role = AuthService.currentUser?['role'];

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
            if (isLoggedIn) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(username ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.accentColor)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (role == 'admin' ? AppTheme.errorColor : AppTheme.primaryColor).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(role?.toUpperCase() ?? 'USER',
                        style: TextStyle(
                            color: role == 'admin' ? AppTheme.errorColor : AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _getDisplayName(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ] else
              Text(_accountId != null ? 'Steam ID: $_accountId' : 'Not Linked', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (!isLoggedIn) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/auth'),
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('Sign In'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (AuthService.isAdmin)
                    TextButton.icon(
                      onPressed: () => context.go('/admin'),
                      icon: const Icon(Icons.admin_panel_settings, size: 16),
                      label: const Text('Admin Panel'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      await AuthService.logout();
                      setState(() {});
                    },
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Sign Out'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ],
            if (_playerStats != null) ...[
              const SizedBox(height: 8),
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
          if (AuthService.isLoggedIn)
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.primaryColor),
              title: Text('Account Settings', style: Theme.of(context).textTheme.titleSmall),
              subtitle: const Text('Edit profile, change password, link Steam'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/account'),
              tileColor: AppTheme.surfaceColorLight.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          if (AuthService.isLoggedIn && _accountId == null) ...[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.link, color: AppTheme.accentColor),
              title: Text('Link Steam Account', style: Theme.of(context).textTheme.titleSmall),
              subtitle: const Text('Quick link your Steam to see stats'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/account'),
              tileColor: AppTheme.surfaceColorLight.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ],
      ),
    );
  }

  String _getDisplayName() {
    final user = AuthService.currentUser;
    if (user == null) return '';
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }
    return '';
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 64),
            const SizedBox(height: 16),
            Text('Failed to load profile',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_error ?? 'Something went wrong',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
