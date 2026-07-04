import 'dart:convert';
import 'dart:io';

import 'package:pauselock_server/src/services/deadlock_api_service.dart';
import 'package:pauselock_server/src/services/auth_service.dart';
import 'package:pauselock_server/src/generated/protocol.dart';

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
        final body = await _readBody(request);
        result = _auth.register(
          body['email'] ?? '',
          body['username'] ?? '',
          body['password'] ?? '',
        );
        break;

      case '/auth/login':
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        final body = await _readBody(request);
        result = _auth.login(
          body['emailOrUsername'] ?? '',
          body['password'] ?? '',
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
        final body = await _readBody(request);
        result = _auth.updateProfile(currentUser,
            username: body['username'], email: body['email']);
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
        final body = await _readBody(request);
        result = _auth.changePassword(
            currentUser, body['oldPassword'] ?? '', body['newPassword'] ?? '');
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
        final body = await _readBody(request);
        final success = _auth.updateUserRole(
            body['userId'] ?? 0, body['role'] ?? 'user', currentUser);
        result = success
            ? {'success': true}
            : {'error': 'Failed to update role'};
        break;

      case '/admin/delete-user':
        if (request.method != 'POST') {
          result = {'error': 'POST required'};
          break;
        }
        final body = await _readBody(request);
        final success =
            _auth.deleteUser(body['userId'] ?? 0, currentUser);
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
        final body = await _readBody(request);
        final heroId = body['heroId'] ?? 0;
        final tier = body['tier'] ?? 'C';
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
        final body = await _readBody(request);
        _auth.removeTierOverride(body['heroId'] ?? 0);
        result = {'success': true};
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

    request.response.statusCode =
        result is _NotFound ? HttpStatus.notFound : HttpStatus.ok;
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

Future<Map<String, dynamic>> _readBody(HttpRequest request) async {
  try {
    final body = await request.first;
    if (body.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(body)));
  } catch (_) {
    return {};
  }
}

_NotFound _notFound(String path) =>
    _NotFound({'error': 'Route not found', 'path': path});

Object? _json(Object? value) => value is _NotFound ? value.body : value;

class _NotFound {
  final Map<String, dynamic> body;
  _NotFound(this.body);
}
