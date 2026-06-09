import 'dart:convert';
import 'dart:io';

import 'package:pauselock_server/src/services/deadlock_api_service.dart';

final _deadlockApi = DeadlockApiService();

Future<void> run(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
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
    ..add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ..add('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method == 'OPTIONS') {
    await request.response.close();
    return;
  }

  try {
    final path = request.uri.path;
    final query = request.uri.queryParameters;
    final result = switch (path) {
      '/health' => await _deadlockApi.health(),
      '/hero/all' => await _deadlockApi.getHeroes(
          limit: int.tryParse(query['limit'] ?? ''),
          sortBy: query['sortBy'],
          searchQuery: query['searchQuery'],
        ),
      '/hero/meta' => await _deadlockApi.getHeroes(
          sortBy: 'pickRate',
          limit: int.tryParse(query['limit'] ?? '10'),
        ),
      String p when p.startsWith('/hero/') =>
        await _deadlockApi.getHeroById(int.tryParse(p.split('/').last) ?? 0),
      '/build/all' => await _deadlockApi.getBuilds(
          heroId: int.tryParse(query['heroId'] ?? ''),
          limit: int.tryParse(query['limit'] ?? '20') ?? 20,
          sortBy: query['sortBy'],
          searchQuery: query['searchQuery'],
          featuredOnly: query['featuredOnly'] == 'true',
        ),
      '/build/featured' => await _deadlockApi.getBuilds(
          limit: int.tryParse(query['limit'] ?? '10') ?? 10,
          featuredOnly: true,
        ),
      String p when p.startsWith('/build/') =>
        await _deadlockApi.getBuildById(int.tryParse(p.split('/').last) ?? 0),
      '/player/search' =>
        await _deadlockApi.searchPlayers(query['query'] ?? ''),
      '/player/stats' => await _deadlockApi
          .getPlayerStats(int.tryParse(query['accountId'] ?? '') ?? 0),
      '/player/matches' => await _deadlockApi.getPlayerMatches(
          int.tryParse(query['accountId'] ?? '') ?? 0,
          limit: int.tryParse(query['limit'] ?? '20') ?? 20,
        ),
      '/stats/leaderboard' => await _deadlockApi.getLeaderboard(
          region: query['region'],
          limit: int.tryParse(query['limit'] ?? '100') ?? 100,
        ),
      '/stats/global' => await _deadlockApi.getGlobalStats(),
      _ => _notFound(path),
    };

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

_NotFound _notFound(String path) =>
    _NotFound({'error': 'Route not found', 'path': path});

Object? _json(Object? value) => value is _NotFound ? value.body : value;

class _NotFound {
  final Map<String, dynamic> body;
  _NotFound(this.body);
}
