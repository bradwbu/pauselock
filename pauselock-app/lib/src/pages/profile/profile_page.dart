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

  void _linkAccount() async {
    final controller = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _LinkAccountDialog(controller: controller),
    );

    if (result != null && result['accountId'] != null) {
      setState(() => _isLoading = true);
      await LocalStorageService.setAccountId(result['accountId']);
      await _loadProfile();
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

class _LinkAccountDialog extends StatefulWidget {
  final TextEditingController controller;
  const _LinkAccountDialog({required this.controller});

  @override
  State<_LinkAccountDialog> createState() => _LinkAccountDialogState();
}

class _LinkAccountDialogState extends State<_LinkAccountDialog> {
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  String? _error;

  Future<void> _searchPlayers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    final numericId = int.tryParse(query.trim());
    if (numericId != null) {
      setState(() {
        _searchResults = [
          {'accountId': numericId, 'playerName': 'Steam ID: $numericId', 'avatarUrl': null}
        ];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await PauselockClient.searchPlayers(query.trim());
      setState(() {
        _isSearching = false;
        _searchResults = results ?? [];
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Search failed. Try the Steam ID directly.';
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('Link Steam Account',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enter a Steam ID or search by player name',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search player or enter Steam ID...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              onChanged: (value) => _searchPlayers(value),
              onSubmitted: (value) => _searchPlayers(value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            if (_searchResults.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final player = _searchResults[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        backgroundImage: player['avatarUrl'] != null
                            ? NetworkImage(player['avatarUrl'])
                            : null,
                        child: player['avatarUrl'] == null
                            ? const Icon(Icons.person, size: 16, color: AppTheme.primaryColor)
                            : null,
                      ),
                      title: Text(
                        player['playerName'] ?? 'Unknown',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Steam ID: ${player['accountId']}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
                      onTap: () => Navigator.pop(context, player),
                    );
                  },
                ),
              )
            else if (!_isSearching && widget.controller.text.trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Type to search or press Enter with a Steam ID',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = widget.controller.text.trim();
                    if (text.isEmpty) return;
                    final numericId = int.tryParse(text);
                    if (numericId != null) {
                      Navigator.pop(context, {
                        'accountId': numericId,
                        'playerName': 'Steam ID: $numericId',
                      });
                    } else if (_searchResults.isNotEmpty) {
                      Navigator.pop(context, _searchResults.first);
                    }
                  },
                  child: const Text('Link'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
