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
  int _selectedTab = 0;

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
      if (_accountId == null && AuthService.isLoggedIn) {
        _accountId = AuthService.currentUser?['steamAccountId'];
      }
      if (_accountId != null) {
        _playerStats = await PauselockClient.getPlayerStats(_accountId!);
      }
      final heroIds = LocalStorageService.getFavoriteHeroes();
      final buildIds = LocalStorageService.getFavoriteBuilds();
      final heroes = <Map<String, dynamic>>[];
      for (final id in heroIds) {
        final hero = await PauselockClient.getHeroById(id);
        if (hero != null) heroes.add(hero);
      }
      final builds = <Map<String, dynamic>>[];
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
          _error = 'Failed to load profile.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }
    if (_error != null) return _buildErrorState();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isLoggedIn = AuthService.isLoggedIn;
    final username = AuthService.currentUser?['username'];
    final role = AuthService.currentUser?['role'];
    final playerName = _playerStats != null ? _playerStats!['playerName'] ?? '' : '';
    final avatarUrl = _playerStats != null ? _playerStats!['avatarUrl'] ?? '' : '';
    final rank = _playerStats != null ? _playerStats!['rank'] ?? 0 : 0;
    final totalMatches = _playerStats != null ? _playerStats!['totalMatches'] ?? 0 : 0;
    final winRate = _playerStats != null ? _playerStats!['winRate'] ?? 0 : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: ClipOval(
              child: avatarUrl.toString().isNotEmpty
                  ? Image.network(avatarUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.white54, size: 28))
                  : Container(
                      color: AppTheme.surfaceColorMedium,
                      child: const Icon(Icons.person, color: Colors.white54, size: 28)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      playerName.toString().isNotEmpty ? playerName.toString() : 'Guest Player',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (_playerStats != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.link, color: AppTheme.textMuted, size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (isLoggedIn && username != null)
                  Text(username, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                if (isLoggedIn && role != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (role == 'admin' ? AppTheme.errorColor : AppTheme.primaryColor).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(role.toUpperCase(),
                        style: TextStyle(
                            color: role == 'admin' ? AppTheme.errorColor : AppTheme.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          if (_playerStats != null) ...[
            _buildStatBadge('$rank', 'Rank', AppTheme.primaryColor),
            const SizedBox(width: 8),
            _buildStatBadge('${winRate.round()}%', 'WR', AppTheme.successColor),
            const SizedBox(width: 8),
            _buildStatBadge('$totalMatches', 'Games', AppTheme.accentColor),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Overview', 'Heroes', 'Matches', 'Settings'];
    return Container(
      margin: const EdgeInsets.only(top: 12),
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
                padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildHeroesTab();
      case 2:
        return _buildMatchesTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildOverviewLeft()),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _buildOverviewRight()),
              ],
            );
          }
          return Column(
            children: [
              _buildOverviewLeft(),
              const SizedBox(height: 12),
              _buildOverviewRight(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewLeft() {
    final rank = _playerStats != null ? _playerStats!['rank'] ?? 0 : 0;
    final totalMatches = _playerStats != null ? _playerStats!['totalMatches'] ?? 0 : 0;
    final wins = _playerStats != null ? _playerStats!['wins'] ?? 0 : 0;
    final losses = _playerStats != null ? _playerStats!['losses'] ?? 0 : 0;
    final winRate = _playerStats != null ? _playerStats!['winRate'] ?? 0 : 0;
    final rankName = _getRankName(rank);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glassDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OVERVIEW', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (rank > 0) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('$rank', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rankName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Estimated Rank', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('W / L', '$wins / $losses', AppTheme.successColor),
                  _buildMiniStat('Win Rate', '${winRate.round()}%', AppTheme.primaryColor),
                  _buildMiniStat('Matches', '$totalMatches', AppTheme.accentColor),
                ],
              ),
            ],
          ),
        ),
        if (_favoriteHeroes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOP HEROES', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                ..._favoriteHeroes.take(5).map((hero) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(hero['iconUrl'] ?? '', width: 24, height: 24, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(width: 24, height: 24, color: AppTheme.surfaceColorMedium)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(hero['name'] ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                      GestureDetector(
                        onTap: () async {
                          await LocalStorageService.removeFavoriteHero(hero['id']);
                          _loadProfile();
                        },
                        child: Icon(Icons.close, size: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
        if (_favoriteBuilds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SAVED BUILDS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    GestureDetector(
                      onTap: () => context.go('/builds'),
                      child: Text('Browse', style: TextStyle(color: AppTheme.accentColor, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._favoriteBuilds.take(5).map((build) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => context.go('/build/${build['id']}'),
                    child: Row(
                      children: [
                        Icon(Icons.build, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(build['buildName'] ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              Text(build['heroName'] ?? '', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await LocalStorageService.removeFavoriteBuild(build['id']);
                            _loadProfile();
                          },
                          child: Icon(Icons.close, size: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOverviewRight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUICK STATS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          if (_playerStats != null) ...[
            _buildStatRow('Matches Played', '${_playerStats!['totalMatches'] ?? 0}', AppTheme.accentColor),
            _buildStatRow('Win Rate', '${(_playerStats!['winRate'] ?? 0).round()}%', AppTheme.successColor),
            _buildStatRow('KDA', _playerStats!['kda']?.toString() ?? 'N/A', AppTheme.primaryColor),
            _buildStatRow('Rank', '${_playerStats!['rank'] ?? 0}', AppTheme.warningColor),
            if (_playerStats!['badgeLevel'] != null)
              _buildStatRow('Badge Level', '${_playerStats!['badgeLevel']}', AppTheme.accentColor),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.link_off, color: AppTheme.textMuted, size: 32),
                    const SizedBox(height: 8),
                    Text('No Steam account linked', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.go('/account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceColorMedium,
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Link Account', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroesTab() {
    if (_favoriteHeroes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: AppTheme.textMuted, size: 40),
            const SizedBox(height: 12),
            Text('No favorite heroes yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.go('/heroes'),
              child: Text('Browse Heroes', style: TextStyle(color: AppTheme.accentColor, fontSize: 12)),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _favoriteHeroes.length,
      itemBuilder: (context, index) {
        final hero = _favoriteHeroes[index];
        return GestureDetector(
          onTap: () => context.go('/heroes/${hero['id']}'),
          child: Container(
            decoration: AppTheme.glassDecoration,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(hero['iconUrl'] ?? '', fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppTheme.surfaceColorMedium, child: Icon(Icons.person, color: AppTheme.textMuted, size: 24))),
                  ),
                ),
                const SizedBox(height: 6),
                Text(hero['name'] ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await LocalStorageService.removeFavoriteHero(hero['id']);
                        _loadProfile();
                      },
                      child: Icon(Icons.close, size: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    if (_accountId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, color: AppTheme.textMuted, size: 40),
            const SizedBox(height: 12),
            Text('Link your Steam account to see match history', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/account'),
              child: const Text('Link Account'),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_esports, color: AppTheme.textMuted, size: 40),
          const SizedBox(height: 12),
          Text('View full match history', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go('/stats/$_accountId'),
            child: const Text('Go to Stats'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (AuthService.isLoggedIn) ...[
            _buildSettingsTile(Icons.person_outline, 'Edit Profile', 'Change name and email', () => context.go('/account')),
            _buildSettingsTile(Icons.lock_outline, 'Change Password', 'Update your password', () => context.go('/account')),
            _buildSettingsTile(Icons.link, 'Steam Account', 'Link or unlink Steam', () => context.go('/account')),
            if (AuthService.isAdmin)
              _buildSettingsTile(Icons.admin_panel_settings, 'Admin Panel', 'Manage site content', () => context.go('/admin')),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                await AuthService.logout();
                _loadProfile();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppTheme.errorColor, size: 16),
                    const SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ] else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, color: AppTheme.textMuted, size: 40),
                  const SizedBox(height: 12),
                  Text('Sign in to manage your account', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => context.go('/auth'), child: const Text('Sign In')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.glassDecoration,
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getRankName(int rank) {
    const names = {
      2: 'Initiate', 3: 'Seeker', 4: 'Alchemist',
      5: 'Ritualist', 6: 'Emissary', 7: 'Archon',
      8: 'Oracle', 9: 'Phantom', 10: 'Ascendant', 11: 'Eternus',
    };
    return names[rank] ?? 'Unranked';
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 40),
            const SizedBox(height: 12),
            Text('Failed to load profile', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
