import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/auth_service.dart';
import 'package:pauselock_app/src/widgets/announcement_banner.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;
    
    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context),
            Expanded(
              child: Column(
                children: [
                  const AnnouncementBanner(),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'PAUSELOCK',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppTheme.surfaceColor,
        ),
        drawer: Drawer(
          backgroundColor: AppTheme.backgroundColor,
          child: _buildSidebar(context, isMobile: true),
        ),
        body: Column(
          children: [
            const AnnouncementBanner(),
            Expanded(child: child),
          ],
        ),
      );
    }
  }

  Widget _buildSidebar(BuildContext context, {bool isMobile = false}) {
    final isLoggedIn = AuthService.isLoggedIn;
    final isAdmin = AuthService.isAdmin;
    final username = AuthService.currentUser?['username'];

    return Container(
      width: isMobile ? double.infinity : 260,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 40, 24, 40),
              child: Row(
                children: [
                  Icon(Icons.pause_circle_filled, color: AppTheme.primaryColor, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'PAUSELOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          if (isMobile) const SizedBox(height: 40),
          
          const _SectionHeader(title: 'MENU'),
          _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.search_rounded, label: 'Search Players', route: '/search', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.leaderboard_rounded, label: 'Leaderboard', route: '/leaderboard', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.star_rounded, label: 'Ranks', route: '/ranks', currentPath: GoRouterState.of(context).uri.path),
          
          const SizedBox(height: 20),
          const _SectionHeader(title: 'GAME DATA'),
          _NavItem(icon: Icons.people_alt_rounded, label: 'Heroes', route: '/heroes', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.auto_stories_rounded, label: 'Lore', route: '/lore', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.build_circle_rounded, label: 'Builds', route: '/builds', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.emoji_events_rounded, label: 'Pro Builds', route: '/probuilds', currentPath: GoRouterState.of(context).uri.path),
          
          const SizedBox(height: 20),
          const _SectionHeader(title: 'PERSONAL'),
          _NavItem(icon: Icons.person_rounded, label: 'My Profile', route: '/profile', currentPath: GoRouterState.of(context).uri.path),
          if (isLoggedIn)
            _NavItem(icon: Icons.settings_rounded, label: 'Account Settings', route: '/account', currentPath: GoRouterState.of(context).uri.path),
          if (isAdmin)
            _NavItem(icon: Icons.admin_panel_settings, label: 'Admin Panel', route: '/admin', currentPath: GoRouterState.of(context).uri.path),
          
          const Spacer(),

          if (isLoggedIn) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      (username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      username ?? 'User',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await AuthService.logout();
                      if (context.mounted) context.go('/');
                    },
                    child: const Icon(Icons.logout, color: AppTheme.errorColor, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/auth'),
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'v1.0.0\nData provided by deadlock-api.com',
              style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
            ),
          )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentPath;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = currentPath == route || (route != '/' && currentPath.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          context.go(route);
          if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
            Navigator.pop(context); // Close drawer on mobile
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.white54,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
