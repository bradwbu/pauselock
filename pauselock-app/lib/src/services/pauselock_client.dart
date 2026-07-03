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

  static final Map<int, Map<String, dynamic>> _itemCache = {};

  static Future<Map<int, Map<String, dynamic>>> getAllItems() async {
    if (_itemCache.isNotEmpty) return _itemCache;
    try {
      final result = await _getJson('/item/all');
      if (result is List) {
        for (var item in result) {
          if (item is Map && item['id'] != null) {
            final intId = item['id'] is int ? item['id'] : int.tryParse('${item['id']}') ?? 0;
            _itemCache[intId] = Map<String, dynamic>.from(item);
          }
        }
      }
    } catch (_) {
      try {
        final response = await http.get(Uri.parse('https://assets.deadlock-api.com/v2/items'));
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          for (var item in data) {
            if (item is Map && item['id'] != null) {
              final intId = item['id'] is int ? item['id'] : int.tryParse('${item['id']}') ?? 0;
              _itemCache[intId] = Map<String, dynamic>.from(item);
            }
          }
        }
      } catch (_) {}
    }
    return _itemCache;
  }

  static Future<List<Map<String, dynamic>>?> getItemsBySlotType(String slotType) async {
    final result = await _getJson('/item/slot/$slotType');
    if (result is List) return result.cast<Map<String, dynamic>>();
    return null;
  }

  static Future<Map<String, dynamic>?> getItemById(int itemId) async {
    final itemsCache = await getAllItems();
    return itemsCache[itemId];
  }

  static Future<Map<String, dynamic>?> getBuildById(int buildId) async {
    final result = await _getJson('/build/$buildId');
    if (result == null) return null;
    
    final map = Map<String, dynamic>.from(result as Map);
    final itemsCache = await getAllItems();
    
    if (map['itemIds'] != null) {
      final List itemIds = map['itemIds'];
      final List<Map<String, dynamic>> populatedItems = [];
      for (var id in itemIds) {
        final intId = int.tryParse('$id') ?? 0;
        final itemDetails = itemsCache[intId];
        populatedItems.add({
          'id': intId,
          'name': itemDetails?['name']?.toString() ?? 'Item $id',
          'imageUrl': itemDetails?['imageUrl']?.toString() ?? '',
          'cost': itemDetails?['cost'] ?? 0,
          'slotType': itemDetails?['slotType']?.toString() ?? '',
          'tier': itemDetails?['tier'] ?? 1,
        });
      }
      map['itemIds'] = populatedItems;
    }

    final heroes = await getAllHeroes();
    if (heroes != null && map['heroId'] != null) {
      final heroId = map['heroId'];
      final hero = heroes.firstWhere((h) => h['id'] == heroId, orElse: () => null);
      if (hero != null && hero is Map) {
        map['heroIconUrl'] = hero['iconUrl'] ?? hero['bannerPortraitUrl'];
      }
    }
    
    return map;
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
