import 'dart:convert';
import 'dart:io';

import 'package:pauselock_server/src/services/deadlock_api_service.dart';
import 'package:pauselock_server/src/services/auth_service.dart';

final _deadlockApi = DeadlockApiService();
final _auth = AuthService.instance;

Future<void> run(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  _auth.initialize();
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Pauselock API listening on http://localhost:$port');

  await for (final request in server) {
    await _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  final bodyBytes = await request.fold<List<int>>(
      <int>[], (prev, chunk) => prev..addAll(chunk));
  final parsedBody = bodyBytes.isEmpty
      ? <String, dynamic>{}
      : Map<String, dynamic>.from(jsonDecode(utf8.decode(bodyBytes)));

  request.response.headers
    ..contentType = ContentType.json
    ..add('Access-Control-Allow-Origin', '*')
    ..add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    ..add('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (request.method == 'OPTIONS') {
    await request.response.close();
    return;
  }

  try {
    final path = request.uri.path;
    final query = request.uri.queryParameters;
    final authHeader = request.headers.value('Authorization');
    final tokenStr = authHeader?.replaceFirst('Bearer ', '');
    final currentUser = _auth.validateToken(tokenStr);

    dynamic result;

    switch (path) {
      case '/health':
        result = await _deadlockApi.health();
        break;

      case '/auth/register':
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        result = _auth.register(
          parsedBody['email'] ?? '',
          parsedBody['username'] ?? '',
          parsedBody['password'] ?? '',
        );
        break;

      case '/auth/login':
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        result = _auth.login(
          parsedBody['emailOrUsername'] ?? '',
          parsedBody['password'] ?? '',
        );
        break;

      case '/auth/logout':
        if (tokenStr != null) _auth.logout(tokenStr);
        result = {'success': true};
        break;

      case '/auth/me':
        if (currentUser == null) {
          result = {'error': 'Not authenticated'};
          break;
        }
        result = _auth.getProfile(currentUser);
        break;

      case '/auth/update-profile':
        if (currentUser == null) {
          result = {'error': 'Not authenticated'};
          break;
        }
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        result = _auth.updateProfile(currentUser,
            username: parsedBody['username'], email: parsedBody['email']);
        break;

      case '/auth/change-password':
        if (currentUser == null) {
          result = {'error': 'Not authenticated'};
          break;
        }
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        result = _auth.changePassword(
            currentUser, parsedBody['oldPassword'] ?? '', parsedBody['newPassword'] ?? '');
        break;

      case '/admin/users':
        if (!_auth.isAdmin(currentUser)) {
          result = {'error': 'Admin access required'};
          break;
        }
        result = _auth.listUsers();
        break;

      case '/admin/update-role':
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        final success = _auth.updateUserRole(
            parsedBody['userId'] ?? 0, parsedBody['role'] ?? 'user', currentUser);
        result = success
            ? {'success': true}
            : {'error': 'Failed to update role'};
        break;

      case '/admin/delete-user':
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        final success =
            _auth.deleteUser(parsedBody['userId'] ?? 0, currentUser);
        result =
            success ? {'success': true} : {'error': 'Failed to delete user'};
        break;

      case '/admin/tier-overrides':
        if (!_auth.isAdmin(currentUser)) {
          result = {'error': 'Admin access required'};
          break;
        }
        result = _auth
            .getAllTierOverrides()
            .map((key, value) => MapEntry('$key', value.toJson()));
        break;

      case '/admin/set-tier':
        if (!_auth.isAdmin(currentUser)) {
          result = {'error': 'Admin access required'};
          break;
        }
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        final heroId = parsedBody['heroId'] ?? 0;
        final tier = parsedBody['tier'] ?? 'C';
        _auth.setTierOverride(heroId, tier, currentUser?.username);
        result = {'success': true};
        break;

      case '/admin/remove-tier':
        if (!_auth.isAdmin(currentUser)) {
          result = {'error': 'Admin access required'};
          break;
        }
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        _auth.removeTierOverride(parsedBody['heroId'] ?? 0);
        result = {'success': true};
        break;

      case '/admin/save-tiers':
        if (!_auth.isAdmin(currentUser)) {
          result = {'error': 'Admin access required'};
          break;
        }
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        final tiers = parsedBody['tiers'];
        if (tiers is Map) {
          final tierMap = <int, String>{};
          for (final entry in tiers.entries) {
            final id = int.tryParse('${entry.key}');
            if (id != null) {
              tierMap[id] = '${entry.value}';
            }
          }
          _auth.setTierOverridesBatch(tierMap, currentUser?.username);
          result = {'success': true, 'count': tierMap.length};
        } else {
          result = {'error': 'tiers must be a map of heroId -> tier'};
        }
        break;

      case '/hero/all':
        result = await _deadlockApi.getHeroes(
          limit: int.tryParse(query['limit'] ?? ''),
          sortBy: query['sortBy'],
          searchQuery: query['searchQuery'],
        );
        if (result is List) {
          result = _applyTierOverrides(result);
        }
        break;

      case '/hero/meta':
        result = await _deadlockApi.getHeroes(
          sortBy: 'pickRate',
          limit: int.tryParse(query['limit'] ?? '10'),
        );
        if (result is List) {
          result = _applyTierOverrides(result);
        }
        break;

      case String p when p.startsWith('/hero/'):
        result = await _deadlockApi
            .getHeroById(int.tryParse(p.split('/').last) ?? 0);
        if (result is Map) {
          final override = _auth.getTierOverride(result['id'] ?? 0);
          if (override != null) result['tier'] = override.tier;
        }
        break;

      case '/build/all':
        result = await _deadlockApi.getBuilds(
          heroId: int.tryParse(query['heroId'] ?? ''),
          limit: int.tryParse(query['limit'] ?? '20') ?? 20,
          sortBy: query['sortBy'],
          searchQuery: query['searchQuery'],
          featuredOnly: query['featuredOnly'] == 'true',
        );
        break;

      case '/build/featured':
        result = await _deadlockApi.getBuilds(
          limit: int.tryParse(query['limit'] ?? '10') ?? 10,
          featuredOnly: true,
        );
        break;

      case String p when p.startsWith('/build/'):
        result = await _deadlockApi
            .getBuildById(int.tryParse(p.split('/').last) ?? 0);
        break;

      case '/player/search':
        result =
            await _deadlockApi.searchPlayers(query['query'] ?? '');
        break;

      case '/player/stats':
        result = await _deadlockApi
            .getPlayerStats(int.tryParse(query['accountId'] ?? '') ?? 0);
        break;

      case '/player/matches':
        result = await _deadlockApi.getPlayerMatches(
          int.tryParse(query['accountId'] ?? '') ?? 0,
          limit: int.tryParse(query['limit'] ?? '20') ?? 20,
        );
        break;

      case '/stats/leaderboard':
        result = await _deadlockApi.getLeaderboard(
          region: query['region'],
          limit: int.tryParse(query['limit'] ?? '100') ?? 100,
        );
        break;

      case '/item/all':
        result = await _deadlockApi.getItems();
        break;

      case String p when p.startsWith('/item/slot/'):
        result =
            await _deadlockApi.getItemsBySlotType(p.split('/').last);
        break;

      case String p when p.startsWith('/item/tier/'):
        result = await _deadlockApi
            .getItemsByTier(int.tryParse(p.split('/').last) ?? 0);
        break;

      case String p when p.startsWith('/item/'):
        result = await _deadlockApi
            .getItemById(int.tryParse(p.split('/').last) ?? 0);
        break;

      case '/stats/global':
        result = await _deadlockApi.getGlobalStats();
        break;

      default:
        result = _notFound(path);
        break;
    }

    if (result is _NotFound) {
      request.response.statusCode = HttpStatus.notFound;
    } else if (result is Map && result.containsKey('error')) {
      final err = result['error'] as String;
      if (err.contains('Admin access') || err.contains('Not authenticated')) {
        request.response.statusCode = HttpStatus.forbidden;
      } else {
        request.response.statusCode = HttpStatus.ok;
      }
    } else {
      request.response.statusCode = HttpStatus.ok;
    }
    request.response.write(jsonEncode(_json(result)));
  } catch (error, stackTrace) {
    stderr.writeln('Request failed: $error\n$stackTrace');
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.write(jsonEncode({'error': 'Internal server error'}));
  } finally {
    await request.response.close();
  }
}

List<dynamic> _applyTierOverrides(List<dynamic> heroes) {
  for (final hero in heroes) {
    if (hero is Map) {
      final override = _auth.getTierOverride(hero['id'] ?? 0);
      if (override != null) hero['tier'] = override.tier;
    }
  }
  return heroes;
}

_NotFound _notFound(String path) =>
    _NotFound({'error': 'Route not found', 'path': path});

Object? _json(Object? value) => value is _NotFound ? value.body : value;

class _NotFound {
  final Map<String, dynamic> body;
  _NotFound(this.body);
}
