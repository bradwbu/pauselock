import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/auth_service.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:shimmer/shimmer.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _selectedSection = 'dashboard';
  bool _isLoading = true;
  List<dynamic> _heroes = [];
  List<dynamic> _users = [];
  Map<String, dynamic> _tierOverrides = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    if (!AuthService.isLoggedIn || !AuthService.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auth');
      });
      return;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final heroes = await PauselockClient.getAllHeroes();
      final users = await AuthService.getUsers();
      final tierOverrides = await AuthService.getTierOverrides();
      setState(() {
        _heroes = heroes ?? [];
        _users = users;
        _tierOverrides = tierOverrides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn || !AuthService.isAdmin) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: const Center(
            child: Text('Access Denied',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 24)),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final sections = [
      {'key': 'dashboard', 'label': 'Dashboard', 'icon': Icons.dashboard},
      {'key': 'tiers', 'label': 'Hero Tiers', 'icon': Icons.leaderboard},
      {'key': 'users', 'label': 'Users', 'icon': Icons.people},
      {'key': 'heroes', 'label': 'Heroes', 'icon': Icons.shield},
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          right: BorderSide(
              color: AppTheme.textSecondary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: const Text('PAUSELOCK',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('ADMIN',
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final isSelected = section['key'] == _selectedSection;
                return ListTile(
                  leading: Icon(section['icon'] as IconData,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      size: 20),
                  title: Text(section['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      )),
                  dense: true,
                  selected: isSelected,
                  selectedTileColor:
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  onTap: () =>
                      setState(() => _selectedSection = section['key'] as String),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
              title: const Text('Logout',
                  style: TextStyle(color: AppTheme.errorColor)),
              dense: true,
              onTap: () async {
                await AuthService.logout();
                if (mounted) context.go('/');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildSection()),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
              color: AppTheme.textSecondary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Text(
            _selectedSection.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            child: Text(
              (AuthService.currentUser?['username'] ?? 'A')[0].toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text(AuthService.currentUser?['username'] ?? 'Admin',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSection() {
    if (_isLoading) {
      return Center(
        child: Shimmer.fromColors(
          baseColor: AppTheme.surfaceColorLight,
          highlightColor: AppTheme.surfaceColor,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    switch (_selectedSection) {
      case 'dashboard':
        return _buildDashboardSection();
      case 'tiers':
        return _buildTierSection();
      case 'users':
        return _buildUsersSection();
      case 'heroes':
        return _buildHeroesSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboardSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildDashboardCard('Total Heroes', '${_heroes.length}',
                  Icons.shield, AppTheme.primaryColor),
              const SizedBox(width: 16),
              _buildDashboardCard('Registered Users', '${_users.length}',
                  Icons.people, AppTheme.accentColor),
              const SizedBox(width: 16),
              _buildDashboardCard(
                  'Tier Overrides',
                  '${_tierOverrides.length}',
                  Icons.leaderboard,
                  AppTheme.successColor),
            ],
          ),
          const SizedBox(height: 24),
          Text('Quick Actions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton('Manage Tiers', () {
                setState(() => _selectedSection = 'tiers');
              }),
              _buildActionButton('Manage Users', () {
                setState(() => _selectedSection = 'users');
              }),
              _buildActionButton('View Heroes', () {
                setState(() => _selectedSection = 'heroes');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_forward, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildTierSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hero Tier Management',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text('Set S+/S/A/B/C tiers for each hero',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 24),
          ..._buildHeroTierList(),
        ],
      ),
    );
  }

  List<Widget> _buildHeroTierList() {
    const tierOptions = ['S+', 'S', 'A', 'B', 'C'];
    return _heroes.map((hero) {
      final heroId = hero['id'] ?? 0;
      final heroName = hero['name'] ?? 'Unknown';
      final currentTier = _tierOverrides['$heroId']?['tier'] ?? hero['tier'] ?? 'C';

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.glassDecorationSmall,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
              child: (hero['iconUrl'] ?? '').toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(hero['iconUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.white54)),
                    )
                  : const Icon(Icons.person, color: Colors.white54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heroName,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(hero['heroType'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            ...tierOptions.map((tier) {
              final isSelected = currentTier == tier;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  label: Text(tier,
                      style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : AppTheme.textSecondary)),
                  selected: isSelected,
                  selectedColor: _tierChipColor(tier),
                  backgroundColor: AppTheme.surfaceColorLight,
                  onSelected: (selected) async {
                    if (selected) {
                      await AuthService.setTierOverride(heroId, tier);
                      setState(() => _tierOverrides['$heroId'] = {
                            'heroId': heroId,
                            'tier': tier,
                          });
                    }
                  },
                ),
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  Color _tierChipColor(String tier) {
    switch (tier) {
      case 'S+':
        return const Color(0xFFFF4466);
      case 'S':
        return const Color(0xFFFF9900);
      case 'A':
        return const Color(0xFF00D4FF);
      case 'B':
        return const Color(0xFF00FF88);
      case 'C':
        return const Color(0xFFA0AABF);
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildUsersSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Management',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          if (_users.isEmpty)
            const Center(
              child: Text('No registered users yet.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            ..._users.map((user) {
              final username = user['username'] ?? 'Unknown';
              final email = user['email'] ?? '';
              final role = user['role'] ?? 'user';
              final userId = user['id'] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.glassDecorationSmall,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          _roleColor(role).withValues(alpha: 0.2),
                      child: Text(username[0].toUpperCase(),
                          style: TextStyle(
                              color: _roleColor(role),
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username,
                              style: Theme.of(context).textTheme.titleSmall),
                          Text(email,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _roleColor(role).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(role.toUpperCase(),
                          style: TextStyle(
                              color: _roleColor(role),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (userId != AuthService.currentUser?['id']) ...[
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'admin' || value == 'moderator' || value == 'user') {
                            await AuthService.updateUserRole(userId, value);
                            _loadData();
                          } else if (value == 'delete') {
                            await AuthService.deleteUser(userId);
                            _loadData();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'admin', child: Text('Make Admin')),
                          const PopupMenuItem(value: 'moderator', child: Text('Make Moderator')),
                          const PopupMenuItem(value: 'user', child: Text('Make User')),
                          const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete User',
                                  style: TextStyle(color: AppTheme.errorColor))),
                        ],
                        child: const Icon(Icons.more_vert,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.errorColor;
      case 'moderator':
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildHeroesSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hero Overview',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _heroes.map((hero) {
              final heroName = hero['name'] ?? 'Unknown';
              final iconUrl = hero['iconUrl'] ?? '';
              final tier = _tierOverrides['${hero['id']}']?['tier'] ?? hero['tier'] ?? 'C';
              final winRate = hero['winRate'] ?? 0;
              final heroType = hero['heroType'] ?? '';

              return GestureDetector(
                onTap: () => context.go('/heroes/${hero['id']}'),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.glassDecorationSmall.copyWith(
                    border: Border.all(
                      color: _tierChipColor(tier).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _tierChipColor(tier).withValues(alpha: 0.1),
                            ),
                            child: iconUrl.toString().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(iconUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person,
                                                color: Colors.white54)),
                                  )
                                : const Icon(Icons.person,
                                    color: Colors.white54, size: 32),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _tierChipColor(tier),
                                shape: BoxShape.circle,
                              ),
                              child: Text(tier,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(heroName,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1),
                      Text(heroType.toString().toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9)),
                      Text('${winRate.toStringAsFixed(1)}% WR',
                          style: TextStyle(
                              color: winRate >= 50
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              fontSize: 11)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
