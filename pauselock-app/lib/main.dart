import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/pages/home/home_page.dart';
import 'package:pauselock_app/src/pages/stats/stats_page.dart';
import 'package:pauselock_app/src/pages/builds/build_detail_page.dart';
import 'package:pauselock_app/src/pages/builds/builds_page.dart';
import 'package:pauselock_app/src/pages/heroes/heroes_page.dart';
import 'package:pauselock_app/src/pages/heroes/hero_detail_page.dart';
import 'package:pauselock_app/src/pages/profile/profile_page.dart';
import 'package:pauselock_app/src/pages/stats/leaderboard_page.dart';
import 'package:pauselock_app/src/pages/stats/ranks_page.dart';
import 'package:pauselock_app/src/pages/builds/pro_builds_page.dart';
import 'package:pauselock_app/src/pages/players/player_search_page.dart';
import 'package:pauselock_app/src/pages/auth/auth_page.dart';
import 'package:pauselock_app/src/pages/account/account_settings_page.dart';
import 'package:pauselock_app/src/pages/admin/admin_dashboard_page.dart';
import 'package:pauselock_app/src/widgets/main_layout.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/services/local_storage_service.dart';
import 'package:pauselock_app/src/services/auth_service.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService.initialize();
  AuthService.initialize();
  
  String apiUrl = 'http://localhost:8080/';
  if (kIsWeb) {
    final baseUri = Uri.base;
    if (baseUri.host != 'localhost') {
      apiUrl = '${baseUri.origin}/api/';
    }
  }
  PauselockClient.initialize(apiUrl);

  runApp(const PauselockApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
    GoRoute(
        path: '/admin', builder: (context, state) => const AdminDashboardPage()),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
        GoRoute(
          path: '/stats/:accountId',
          builder: (context, state) => StatsPage(
            accountId: int.tryParse(state.pathParameters['accountId'] ?? ''),
          ),
        ),
        GoRoute(path: '/builds', builder: (context, state) => const BuildsPage()),
        GoRoute(path: '/probuilds', builder: (context, state) => const ProBuildsPage()),
        GoRoute(path: '/ranks', builder: (context, state) => const RanksPage()),
        GoRoute(
          path: '/build/:buildId',
          builder: (context, state) => BuildDetailPage(
            buildId: int.tryParse(state.pathParameters['buildId'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/builds/:heroId',
          builder: (context, state) => BuildsPage(
            heroId: int.tryParse(state.pathParameters['heroId'] ?? ''),
          ),
        ),
        GoRoute(path: '/heroes', builder: (context, state) => const HeroesPage()),
        GoRoute(
          path: '/heroes/:heroId',
          builder: (context, state) => HeroDetailPage(
            heroId: int.tryParse(state.pathParameters['heroId'] ?? '') ?? 0,
          ),
        ),
        GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        GoRoute(
            path: '/account',
            builder: (context, state) => const AccountSettingsPage()),
        GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardPage()),
        GoRoute(
          path: '/search',
          builder: (context, state) => PlayerSearchPage(
            initialQuery: state.uri.queryParameters['q'],
          ),
        ),
      ],
    ),
  ],
);

class PauselockApp extends StatelessWidget {
  const PauselockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pauselock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
