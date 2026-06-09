import 'dart:convert';

import 'package:http/http.dart' as http;

class PauselockClient {
  static late Uri _serverUri;

  static void initialize(String serverUrl) {
    _serverUri = Uri.parse(serverUrl.endsWith('/') ? serverUrl : '$serverUrl/');
  }

  static Future<Map<String, dynamic>?> getPlayerStats(int accountId) async {
    final result = await _getJson('/player/stats', {'accountId': '$accountId'});
    return result as Map<String, dynamic>?;
  }

  static Future<List<dynamic>?> searchPlayers(String query) async {
    final result = await _getJson('/player/search', {'query': query});
    return result as List<dynamic>?;
  }

  static Future<List<dynamic>?> getAllHeroes(
      {Map<String, dynamic>? filter}) async {
    final result = await _getJson('/hero/all', _stringParams(filter));
    return result as List<dynamic>?;
  }

  static Future<Map<String, dynamic>?> getHeroById(int heroId) async {
    final result = await _getJson('/hero/$heroId');
    return result as Map<String, dynamic>?;
  }

  static Future<List<dynamic>?> getBuilds(
      {Map<String, dynamic>? filter}) async {
    final result = await _getJson('/build/all', _stringParams(filter));
    return result as List<dynamic>?;
  }

  static Future<List<dynamic>?> getBuildsByHero(int heroId) async {
    final result =
        await _getJson('/build/all', {'heroId': '$heroId', 'limit': '10'});
    return result as List<dynamic>?;
  }

  static Future<Map<String, dynamic>?> getBuildById(int buildId) async {
    final result = await _getJson('/build/$buildId');
    return result as Map<String, dynamic>?;
  }

  static Future<List<dynamic>?> getFeaturedBuilds({int limit = 10}) async {
    final result = await _getJson('/build/featured', {'limit': '$limit'});
    return result as List<dynamic>?;
  }

  static Future<List<dynamic>?> getLeaderboard(
      {String? region, int limit = 100}) async {
    final result = await _getJson('/stats/leaderboard', {
      if (region != null) 'region': region,
      'limit': '$limit',
    });
    return result as List<dynamic>?;
  }

  static Future<Map<String, dynamic>?> getGlobalStats() async {
    final result = await _getJson('/stats/global');
    return result as Map<String, dynamic>?;
  }

  static Future<dynamic> _getJson(String path,
      [Map<String, String>? query]) async {
    try {
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      var uri = _serverUri.resolve(cleanPath);
      if (query != null && query.isNotEmpty) {
        uri = uri.replace(queryParameters: query);
      }
      final response =
          await http.get(uri, headers: {'Accept': 'application/json'});
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _stringParams(Map<String, dynamic>? values) {
    if (values == null) return {};
    return values.map((key, value) => MapEntry(key, '$value'));
  }
}
