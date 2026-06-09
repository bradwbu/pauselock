import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';

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
              child: ClipRRect(
                child: child,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
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
        body: child,
      );
    }
  }

  Widget _buildSidebar(BuildContext context, {bool isMobile = false}) {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              child: Row(
                children: [
                  Icon(Icons.pause_circle_filled, color: AppTheme.primaryColor, size: 32),
                  const SizedBox(width: 12),
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
          
          _SectionHeader(title: 'MENU'),
          _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.search_rounded, label: 'Search Players', route: '/search', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.leaderboard_rounded, label: 'Leaderboard', route: '/leaderboard', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.star_rounded, label: 'Ranks', route: '/ranks', currentPath: GoRouterState.of(context).uri.path),
          
          const SizedBox(height: 20),
          _SectionHeader(title: 'GAME DATA'),
          _NavItem(icon: Icons.people_alt_rounded, label: 'Heroes', route: '/heroes', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.build_circle_rounded, label: 'Builds', route: '/builds', currentPath: GoRouterState.of(context).uri.path),
          _NavItem(icon: Icons.emoji_events_rounded, label: 'Pro Builds', route: '/probuilds', currentPath: GoRouterState.of(context).uri.path),
          
          const SizedBox(height: 20),
          _SectionHeader(title: 'PERSONAL'),
          _NavItem(icon: Icons.person_rounded, label: 'My Profile', route: '/profile', currentPath: GoRouterState.of(context).uri.path),
          
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
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
