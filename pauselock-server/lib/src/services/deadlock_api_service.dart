import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pauselock_server/src/endpoints/build_endpoint.dart';
import 'package:pauselock_server/src/endpoints/hero_endpoint.dart';
import 'package:pauselock_server/src/endpoints/player_endpoint.dart';
import 'package:pauselock_server/src/generated/protocol.dart';

class DeadlockApiService {
  DeadlockApiService({http.Client? client})
      : _client = client ?? http.Client(),
        _apiBaseUrl = Uri.parse(
          Platform.environment['DEADLOCK_API_URL'] ??
              'https://api.deadlock-api.com',
        ),
        _assetsBaseUrl = Uri.parse(
          Platform.environment['DEADLOCK_ASSETS_API_URL'] ??
              'https://assets.deadlock-api.com',
        );

  final http.Client _client;
  final Uri _apiBaseUrl;
  final Uri _assetsBaseUrl;
  final Map<String, _CacheEntry> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  Future<Map<String, dynamic>> health() async {
    final data = await _getMap(_apiBaseUrl, '/v1/info/health');
    return {
      'status': 'ok',
      'upstream': data,
    };
  }

  Future<List<Map<String, dynamic>>> getHeroes({
    int? limit,
    String? sortBy,
    List<String>? roles,
    String? searchQuery,
  }) async {
    try {
      final responses = await Future.wait([
        _getList(_assetsBaseUrl, '/v2/heroes', {'only_active': 'true'}),
        _getList(_apiBaseUrl, '/v1/analytics/hero-stats'),
        _getList(_apiBaseUrl, '/v1/analytics/hero-ban-stats'),
      ]);
      final heroes = responses[0];
      final statsByHero = {
        for (final stat in responses[1])
          if (_asInt(stat['hero_id']) > 0) _asInt(stat['hero_id']): stat,
      };
      final bansByHero = {
        for (final stat in responses[2])
          if (_asInt(stat['hero_id']) > 0) _asInt(stat['hero_id']): stat,
      };
      final totalMatches = statsByHero.values.fold<int>(
        0,
        (total, stat) => total + _asInt(stat['matches']),
      );
      final totalBans = bansByHero.values.fold<int>(
        0,
        (total, stat) => total + _asInt(stat['bans']),
      );
      final maxMatches = statsByHero.values.fold<int>(
        1,
        (max, stat) {
          final matches = _asInt(stat['matches']);
          return matches > max ? matches : max;
        },
      );

      var mapped = heroes
          .where((hero) => hero['player_selectable'] != false)
          .map((hero) => _mapHero(
                hero,
                statsByHero[_asInt(hero['id'])],
                bansByHero[_asInt(hero['id'])],
                totalMatches: totalMatches,
                totalBans: totalBans,
                maxMatches: maxMatches,
              ))
          .toList();

      if (roles?.isNotEmpty ?? false) {
        final roleSet = roles!.map((role) => role.toLowerCase()).toSet();
        mapped = mapped.where((hero) {
          final heroRoles = (hero['roles'] as List)
              .map((role) => '$role'.toLowerCase())
              .toSet();
          return heroRoles.intersection(roleSet).isNotEmpty;
        }).toList();
      }

      if (searchQuery?.isNotEmpty ?? false) {
        final query = searchQuery!.toLowerCase();
        mapped = mapped
            .where((hero) =>
                '${hero['name']}'.toLowerCase().contains(query) ||
                '${hero['fullName']}'.toLowerCase().contains(query))
            .toList();
      }

      switch (sortBy) {
        case 'winRate':
          mapped.sort((a, b) =>
              _asDouble(b['winRate']).compareTo(_asDouble(a['winRate'])));
        case 'pickRate':
        case 'popularity':
          mapped.sort((a, b) =>
              _asInt(b['matchesPlayed']).compareTo(_asInt(a['matchesPlayed'])));
        case 'banRate':
          mapped.sort((a, b) =>
              _asDouble(b['banRate']).compareTo(_asDouble(a['banRate'])));
        default:
          mapped.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
      }

      return limit == null ? mapped : mapped.take(limit).toList();
    } catch (error) {
      stderr.writeln('Deadlock hero API fallback: $error');
      return _seedHeroes(limit: limit, sortBy: sortBy);
    }
  }

  Future<Map<String, dynamic>?> getHeroById(int heroId) async {
    final heroes = await getHeroes();
    return heroes.where((hero) => hero['id'] == heroId).firstOrNull;
  }

  Future<List<Map<String, dynamic>>> getBuilds({
    int? heroId,
    int limit = 20,
    String? sortBy,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    try {
      final query = <String, String>{
        'limit': '$limit',
        'only_latest': 'true',
        'sort_direction': 'desc',
        if (heroId != null) 'hero_id': '$heroId',
        if (searchQuery?.isNotEmpty ?? false) 'search_name': searchQuery!,
        'sort_by': switch (sortBy) {
          'recent' => 'updated_at',
          'popularity' => 'favorites',
          _ => featuredOnly ? 'weekly_favorites' : 'favorites',
        },
      };
      final responses = await Future.wait([
        _getList(_apiBaseUrl, '/v1/builds', query),
        getHeroes(),
      ]);
      final heroNames = {
        for (final hero in responses[1]) _asInt(hero['id']): '${hero['name']}',
      };
      var builds = responses[0]
          .map((build) => _mapBuild(build, heroNames))
          .where((build) => build['id'] != null)
          .toList();
      builds = await _enrichBuilds(builds);
      return builds;
    } catch (error) {
      stderr.writeln('Deadlock builds API fallback: $error');
      var builds = _seedBuilds(
          heroId: heroId, limit: limit, featuredOnly: featuredOnly);
      builds = await _enrichBuilds(builds);
      return builds;
    }
  }

  Future<Map<String, dynamic>?> getBuildById(int buildId) async {
    try {
      final responses = await Future.wait([
        _getList(_apiBaseUrl, '/v1/builds', {
          'build_id': '$buildId',
          'limit': '1',
        }),
        getHeroes(),
      ]);
      final direct = responses[0];
      final heroNames = {
        for (final hero in responses[1]) _asInt(hero['id']): '${hero['name']}',
      };
      final build = direct.map((b) => _mapBuild(b, heroNames)).firstOrNull;
      if (build != null) {
        final enriched = await _enrichBuilds([build]);
        return enriched.isEmpty ? build : enriched.first;
      }
    } catch (error) {
      stderr.writeln('Deadlock build API fallback: $error');
    }
    final fallback = BuildEndpoint.seedBuilds
        .where((build) => build.id == buildId)
        .map((build) => build.toJson())
        .firstOrNull;
    if (fallback == null) return null;
    final enriched = await _enrichBuilds([fallback]);
    return enriched.isEmpty ? fallback : enriched.first;
  }

  Future<List<Map<String, dynamic>>> _enrichBuilds(List<Map<String, dynamic>> builds) async {
    try {
      final items = await _fetchItems();
      final itemsById = _buildItemsById(items);
      return builds.map((b) => _enrichBuildItems(b, itemsById)).toList();
    } catch (_) {
      return builds;
    }
  }

  Map<int, Map<String, dynamic>> _buildItemsById(List<Map<String, dynamic>> items) {
    return {for (final item in items) _asInt(item['id']): item};
  }

  Map<String, dynamic> _enrichBuildItems(
      Map<String, dynamic> build, Map<int, Map<String, dynamic>> itemsById) {
    final rawIds = (build['itemIds'] as List?) ?? [];
    final enrichedNames = <String>[];
    final enrichedDetails = <Map<String, dynamic>>[];
    for (final rawId in rawIds) {
      final id = int.tryParse('$rawId') ?? _asInt(rawId);
      final itemData = itemsById[id];
      if (itemData != null) {
        final itemName = _toItemData(itemData).name;
        enrichedNames.add(itemName);
        enrichedDetails.add({
          'id': id,
          'name': itemName,
          'imageUrl': '${itemData['image_webp'] ?? itemData['image'] ?? ''}',
          'slotType': '${itemData['item_slot_type'] ?? ''}',
          'cost': _asInt(itemData['cost']),
          'tier': _asInt(itemData['item_tier']),
        });
      } else {
        enrichedNames.add('Item $id');
        enrichedDetails.add({
          'id': id,
          'name': 'Item $id',
          'imageUrl': '',
          'slotType': '',
          'cost': 0,
          'tier': 1,
        });
      }
    }
    return {
      ...build,
      'items': enrichedNames,
      'itemDetails': enrichedDetails,
      'itemIds': rawIds.map((id) => '$id').toList(),
    };
  }

  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final players = await _getList(_apiBaseUrl, '/v1/players/steam-search', {
        'search_query': query,
      });
      return players.map(_mapSteamPlayer).toList();
    } catch (error) {
      stderr.writeln('Deadlock player search fallback: $error');
      final normalized = query.toLowerCase();
      return PlayerEndpoint.seedPlayers
          .where(
              (player) => player.playerName.toLowerCase().contains(normalized))
          .map((player) => player.toJson())
          .toList();
    }
  }

  Future<Map<String, dynamic>?> getPlayerStats(int accountId) async {
    try {
      final responses = await Future.wait([
        _getList(
            _apiBaseUrl, '/v1/players/steam', {'account_ids': '$accountId'}),
        _getList(_apiBaseUrl, '/v1/players/$accountId/match-history', {
          'only_stored_history': 'true',
        }),
        _getList(_apiBaseUrl, '/v1/players/$accountId/mmr-history'),
        getHeroes(),
      ]);
      final profile = responses[0].firstOrNull ?? {};
      final matches = responses[1];
      final mmr = responses[2];
      final heroNames = {
        for (final hero in responses[3]) _asInt(hero['id']): '${hero['name']}',
      };
      return _mapPlayerStats(accountId, profile, matches, mmr, heroNames);
    } catch (error) {
      stderr.writeln('Deadlock player stats fallback: $error');
      return PlayerEndpoint.seedPlayers
          .where((player) => player.accountId == accountId)
          .map((player) => player.toJson())
          .firstOrNull;
    }
  }

  Future<List<Map<String, dynamic>>> getPlayerMatches(int accountId,
      {int limit = 20}) async {
    final matches =
        await _getList(_apiBaseUrl, '/v1/players/$accountId/match-history', {
      'only_stored_history': 'true',
    });
    return matches.take(limit).toList();
  }

  Future<Map<String, dynamic>?> getPlayerRank(int accountId) async {
    final history =
        await _getList(_apiBaseUrl, '/v1/players/$accountId/mmr-history');
    return history.isEmpty ? null : history.last;
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({
    String? region,
    int limit = 100,
  }) async {
    final apiRegion = _mapRegion(region);
    try {
      final response = await _getMap(_apiBaseUrl, '/v1/leaderboard/$apiRegion');
      final entries = (response['entries'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) => _mapLeaderboardEntry(entry, apiRegion))
          .take(limit)
          .toList();
      return entries;
    } catch (error) {
      stderr.writeln('Deadlock leaderboard API fallback: $error');
      final players = PlayerEndpoint.seedPlayers
          .map((player) => player.toJson())
          .toList()
        ..sort((a, b) => _asInt(a['rank']).compareTo(_asInt(b['rank'])));
      return players.take(limit).toList();
    }
  }

  static const _itemUrl = 'https://api.deadlock-api.com/v1/assets/items';
  static List<Map<String, dynamic>>? _cachedItems;
  static DateTime? _itemsCachedAt;
  static const _itemCacheDuration = Duration(minutes: 10);

  Future<List<Map<String, dynamic>>> _fetchItems() async {
    if (_cachedItems != null &&
        _itemsCachedAt != null &&
        DateTime.now().difference(_itemsCachedAt!) < _itemCacheDuration) {
      return _cachedItems!;
    }
    try {
      final response = await _client.get(
        Uri.parse(_itemUrl),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = (jsonDecode(response.body) as List)
            .whereType<Map<String, dynamic>>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        _cachedItems = data;
        _itemsCachedAt = DateTime.now();
        return data;
      }
    } catch (_) {}
    return _seedItems;
  }

  Future<List<ItemData>> getItems() async {
    final items = await _fetchItems();
    return items.where((i) => _isPurchasable(i)).map(_toItemData).toList();
  }

  Future<List<ItemData>> getItemsBySlotType(String slotType) async {
    final items = await _fetchItems();
    return items
        .where((i) =>
            _isPurchasable(i) &&
            '${i['item_slot_type']}' == slotType)
        .map(_toItemData)
        .toList();
  }

  Future<List<ItemData>> getItemsByTier(int tier) async {
    final items = await _fetchItems();
    return items
        .where((i) =>
            _isPurchasable(i) && '${i['item_tier']}' == '$tier')
        .map(_toItemData)
        .toList();
  }

  Future<ItemData?> getItemById(int itemId) async {
    final items = await _fetchItems();
    final match = items.cast<Map<String, dynamic>?>().firstWhere(
        (i) => _asInt(i?['id']) == itemId,
        orElse: () => null);
    if (match == null) return null;
    return _toItemData(match);
  }

  bool _isPurchasable(Map<String, dynamic> item) {
    return item['type'] == 'upgrade' && _asInt(item['cost']) > 0;
  }

  String _cleanItemName(String raw) {
    if (raw.isEmpty) return raw;
    if (!raw.contains('_')) return raw;
    var cleaned = raw;
    for (final prefix in ['upgrade_', 'ability_', 'mod_', 'citadel_']) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length);
        break;
      }
    }
    return cleaned.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  ItemData _toItemData(Map<String, dynamic> item) {
    final rawName = '${item['name'] ?? ''}';
    final cleanName = _cleanItemName(rawName);
    return ItemData(
      id: _asInt(item['id']),
      className: '${item['class_name'] ?? ''}',
      name: cleanName,
      cost: _asInt(item['cost']),
      imageUrl: '${item['image_webp'] ?? item['image'] ?? ''}',
      slotType: '${item['item_slot_type'] ?? ''}',
      tier: _asInt(item['item_tier']),
      isActive: item['is_active_item'] == true,
    );
  }

  static List<Map<String, dynamic>> get _seedItems => [
    for (final item in [
      [1248737459, 'Ammo Scavenger', 800, 'spirit', 1],
      [1342610602, 'Close Quarters', 800, 'weapon', 1],
      [558396679, 'Enduring Spirit', 800, 'vitality', 1],
      [1548066885, 'Extended Magazine', 800, 'weapon', 1],
      [3633614685, 'Extra Health', 800, 'vitality', 1],
      [2829638276, 'Extra Regen', 800, 'vitality', 1],
      [968099481, 'Extra Spirit', 800, 'spirit', 1],
      [1672893796, 'Grit', 800, 'vitality', 1],
      [2010028405, 'Headshot Booster', 800, 'weapon', 1],
      [1710079648, 'Healing Rite', 800, 'vitality', 1],
      [3077079169, 'High-Velocity Rounds', 800, 'weapon', 1],
      [1009965641, 'Monster Rounds', 800, 'weapon', 1],
      [1998374645, 'Mystic Burst', 800, 'spirit', 1],
      [754480263, 'Mystic Expansion', 800, 'spirit', 1],
      [1439347412, 'Mystic Regeneration', 800, 'spirit', 1],
      [668299740, 'Rapid Rounds', 800, 'weapon', 1],
      [3399065363, 'Sprint Boots', 800, 'vitality', 1],
      [3713423303, 'Bullet Armor', 1600, 'vitality', 2],
      [499683006, 'Bullet Lifesteal', 1600, 'vitality', 2],
      [380806748, 'Compress Cooldown', 1600, 'spirit', 2],
      [3970837787, 'Enchanter\'s Emblem', 1600, 'vitality', 2],
      [3403085434, 'Fleetfoot', 1600, 'weapon', 2],
      [2566692615, 'Healing Booster', 1600, 'vitality', 2],
      [2858617477, 'Toughness', 1600, 'vitality', 2],
      [865846625, 'Leech', 6400, 'vitality', 4],
      [3270001687, 'Warp Stone', 3200, 'vitality', 3],
      [2717651715, 'Superior Duration', 3200, 'spirit', 3],
      [3261353684, 'Superior Cooldown', 3200, 'spirit', 3],
      [630839635, 'Echo Shard', 6400, 'spirit', 4],
      [2480592370, 'Ricochet', 6400, 'weapon', 4],
      [3696726732, 'Toxic Bullets', 3200, 'weapon', 3],
      [393974127, 'Slowing Bullets', 1600, 'weapon', 2],
      [1292979587, 'Surge of Power', 3200, 'spirit', 3],
      [915014646, 'Transcendent Cooldown', 6400, 'spirit', 4],
      [1396247347, 'Lucky Shot', 6400, 'weapon', 4],
      [3884003354, 'Crippling Headshot', 6400, 'weapon', 4],
      [1282141666, 'Siphon Bullets', 6400, 'vitality', 4],
      [2152872419, 'Sharpshooter', 3200, 'weapon', 3],
      [84321454, 'Quicksilver Reload', 1600, 'spirit', 2],
      [98582110, 'Stalker', 1600, 'weapon', 2],
      [1798666702, 'Shadow Weave', 3200, 'weapon', 3],
      [1371725689, 'Phantom Strike', 6400, 'vitality', 4],
      [1437614329, 'Melee Lifesteal', 800, 'vitality', 1],
      [811521119, 'Tesla Bullets', 3200, 'weapon', 3],
      [4104549924, 'Swift Striker', 1600, 'weapon', 2],
      [1976391348, 'Cold Front', 1600, 'spirit', 2],
      [381961617, 'Active Reload', 1600, 'weapon', 2],
      [2678489038, 'Hollow Point', 3200, 'weapon', 3],
    ])
    {
      'id': item[0],
      'class_name': '$item[0]',
      'name': item[1],
      'cost': item[2],
      'item_slot_type': item[3],
      'image_webp': '',
      'image': '',
      'item_tier': item[4],
      'is_active_item': false,
      'type': 'upgrade',
    },
  ];

  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final heroes = await _getList(_apiBaseUrl, '/v1/analytics/hero-stats');
      final totals = heroes.fold(
        {'matches': 0, 'players': 0, 'wins': 0, 'losses': 0},
        (Map<String, int> total, hero) => {
          'matches': total['matches']! + _asInt(hero['matches']),
          'players': total['players']! + _asInt(hero['players']),
          'wins': total['wins']! + _asInt(hero['wins']),
          'losses': total['losses']! + _asInt(hero['losses']),
        },
      );
      final completed = totals['wins']! + totals['losses']!;
      return {
        'activePlayers': totals['players'],
        'matchesToday': totals['matches'],
        'averageWinRate':
            completed == 0 ? 0 : _round(totals['wins']! * 100 / completed),
      };
    } catch (error) {
      stderr.writeln('Deadlock global stats fallback: $error');
      return {
        'activePlayers': 0,
        'matchesToday': 0,
        'averageWinRate': 0,
      };
    }
  }

  Future<Map<String, dynamic>?> getHeroWinRates({int? heroId}) async {
    final heroes = await getHeroes();
    if (heroId == null) {
      return {'heroes': heroes};
    }
    return heroes.where((hero) => hero['id'] == heroId).firstOrNull;
  }

  Future<Map<String, dynamic>?> getMetaBuilds(
      {int? heroId, int limit = 20}) async {
    final builds =
        await getBuilds(heroId: heroId, limit: limit, featuredOnly: true);
    return {'builds': builds};
  }

  Future<Map<String, dynamic>?> getWinRates({String? timeframe}) async {
    return getGlobalStats();
  }

  Future<dynamic> _get(Uri baseUrl, String path,
      [Map<String, String>? query]) async {
    final uri = baseUrl.replace(
      path: path,
      queryParameters: query?.isEmpty ?? true ? null : query,
    );
    final cacheKey = uri.toString();
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    final response =
        await _client.get(uri, headers: {'Accept': 'application/json'});
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'GET $uri failed with ${response.statusCode}: ${response.body}',
        uri: uri,
      );
    }
    final data = jsonDecode(response.body);
    _cache[cacheKey] = _CacheEntry(data, DateTime.now().add(_cacheDuration));
    return data;
  }

  Future<List<Map<String, dynamic>>> _getList(
    Uri baseUrl,
    String path, [
    Map<String, String>? query,
  ]) async {
    final data = await _get(baseUrl, path, query);
    return (data as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> _getMap(
    Uri baseUrl,
    String path, [
    Map<String, String>? query,
  ]) async {
    final data = await _get(baseUrl, path, query);
    return Map<String, dynamic>.from(data as Map);
  }

  Map<String, dynamic> _mapHero(
    Map<String, dynamic> hero,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? bans, {
    required int totalMatches,
    required int totalBans,
    required int maxMatches,
  }) {
    final id = _asInt(hero['id']);
    final matches = _asInt(stats?['matches']);
    final wins = _asInt(stats?['wins']);
    final losses = _asInt(stats?['losses']);
    final completed = wins + losses;
    final name = '${hero['name'] ?? 'Unknown'}';
    final description =
        (hero['description'] as Map?)?.cast<String, dynamic>() ?? const {};
    final images =
        (hero['images'] as Map?)?.cast<String, dynamic>() ?? const {};
    final startingStats =
        (hero['starting_stats'] as Map?)?.cast<String, dynamic>() ?? const {};
    final maxHealth = _statValue(startingStats['max_health']);
    final stamina = _statValue(startingStats['stamina']);
    final bulletDamage = _statValue(startingStats['bullet_damage']);
    final lightMelee = _statValue(startingStats['light_melee_damage']);
    final heavyMelee = _statValue(startingStats['heavy_melee_damage']);
    final baseMoveSpeed = _statValue(startingStats['max_move_speed']);
    final sprintSpeed = _statValue(startingStats['sprint_speed']);
    final baseHealthRegen = _statValue(startingStats['base_health_regen']);
    final bulletArmor = _statValue(startingStats['bullet_armor_damage_reduction']);
    final techArmor = _statValue(startingStats['tech_armor_damage_reduction']);
    final heroType = '${hero['hero_type'] ?? ''}';
    final complexity = _asInt(hero['complexity']);
    final tags = (hero['tags'] as List? ?? const []).map((t) => '$t').toList();

    return {
      'id': id,
      'name': name,
      'fullName': name,
      'description': description['playstyle'] ??
          description['role'] ??
          description['lore'] ??
          '',
      'iconUrl':
          images['icon_image_small_webp'] ?? images['icon_image_small'] ?? '',
      'bannerPortraitUrl':
          images['icon_hero_card_webp'] ?? images['icon_hero_card'] ?? '',
      'backgroundUrl':
          images['background_image_webp'] ?? images['background_image'] ?? '',
      'verticalUrl':
          images['top_bar_vertical_image_webp'] ?? images['top_bar_vertical_image'] ?? '',
      'roles': _heroRoles(hero),
      'primaryAttribute': heroType,
      'heroType': heroType,
      'complexity': complexity,
      'tags': tags,
      'baseHealth': maxHealth.round(),
      'baseMana': stamina.round(),
      'baseDamageMin': lightMelee.round(),
      'baseDamageMax': heavyMelee.round(),
      'baseBulletDamage': bulletDamage.round(),
      'baseArmor': bulletArmor,
      'baseMoveSpeed': _round(baseMoveSpeed),
      'sprintSpeed': _round(sprintSpeed),
      'baseHealthRegen': _round(baseHealthRegen),
      'bulletArmorReduction': bulletArmor,
      'techArmorReduction': techArmor,
      'winRate': completed == 0 ? 0 : _round(wins * 100 / completed),
      'pickRate': totalMatches == 0 ? 0 : _round(matches * 100 / totalMatches),
      'banRate':
          totalBans == 0 ? 0 : _round(_asInt(bans?['bans']) * 100 / totalBans),
      'matchesPlayed': matches,
      'popularity': (matches * 100 / maxMatches).round(),
      'abilities': _heroAbilities(hero),
    };
  }

  Map<String, dynamic> _mapBuild(
      Map<String, dynamic> wrapper, Map<int, String> heroNames) {
    final build =
        (wrapper['hero_build'] as Map?)?.cast<String, dynamic>() ?? wrapper;
    final heroId = _asInt(build['hero_id'] ?? wrapper['hero_id']);
    final favorites = _asInt(wrapper['num_favorites']);
    final weeklyFavorites = _asInt(wrapper['num_weekly_favorites']);
    return {
      'id': _asInt(build['hero_build_id']),
      'heroId': heroId,
      'heroName': heroNames[heroId] ?? 'Hero $heroId',
      'buildName': build['name'] ?? 'Untitled Build',
      'author': 'Steam ${build['author_account_id'] ?? 'Unknown'}',
      'authorAccountId': _asInt(build['author_account_id']),
      'itemIds': _extractBuildAbilityIds(build).map((id) => '$id').toList(),
      'items': _extractBuildAbilityIds(build).map((id) => 'Item $id').toList(),
      'talents': const <String>[],
      'description': build['description'] ?? '',
      'upvotes': favorites,
      'downvotes':
          _asInt(wrapper['num_ignores']) + _asInt(wrapper['num_reports']),
      'winRate': 0,
      'matchesPlayed': weeklyFavorites > 0 ? weeklyFavorites : favorites,
      'createdAt': _timestampToIso(_asInt(
          build['publish_timestamp'] ?? build['last_updated_timestamp'])),
      'isPublic': true,
      'isFeatured': weeklyFavorites > 0 || favorites > 0,
      'tags':
          (build['tags'] as List? ?? const []).map((tag) => '$tag').toList(),
    };
  }

  Map<String, dynamic> _mapSteamPlayer(Map<String, dynamic> player) => {
        'accountId': _asInt(player['account_id']),
        'playerName': player['personaname'] ?? 'Unknown',
        'avatarUrl':
            player['avatarfull'] ?? player['avatarmedium'] ?? player['avatar'],
        'profileUrl': player['profileurl'],
        'countryCode': player['countrycode'],
        'lastUpdated': player['last_updated'],
      };

  Map<String, dynamic> _mapPlayerStats(
    int accountId,
    Map<String, dynamic> profile,
    List<Map<String, dynamic>> matches,
    List<Map<String, dynamic>> mmrHistory,
    Map<int, String> heroNames,
  ) {
    final wins = matches
        .where((match) =>
            _asInt(match['match_result']) == _asInt(match['player_team']))
        .length;
    final losses = matches.length - wins;
    final kills = matches.fold<int>(
        0, (total, match) => total + _asInt(match['player_kills']));
    final deaths = matches.fold<int>(
        0, (total, match) => total + _asInt(match['player_deaths']));
    final assists = matches.fold<int>(
        0, (total, match) => total + _asInt(match['player_assists']));
    final heroCounts = <int, int>{};
    for (final match in matches) {
      final heroId = _asInt(match['hero_id']);
      heroCounts[heroId] = (heroCounts[heroId] ?? 0) + 1;
    }
    final sortedHeroes = heroCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final favoriteHeroId = sortedHeroes.isNotEmpty ? sortedHeroes.first.key : 0;
    
    final topHeroesList = sortedHeroes.take(3).map((e) => {
      'heroId': e.key,
      'heroName': heroNames[e.key] ?? 'Unknown',
      'matches': e.value,
    }).toList();
    final latestMmr =
        mmrHistory.isEmpty ? const <String, dynamic>{} : mmrHistory.last;
    final lastPlayedUnix =
        matches.isEmpty ? 0 : _asInt(matches.first['start_time']);

    return {
      'id': accountId,
      'accountId': accountId,
      'playerName': profile['personaname'] ?? 'Player $accountId',
      'avatarUrl':
          profile['avatarfull'] ?? profile['avatarmedium'] ?? profile['avatar'],
      'mmr': _asDouble(latestMmr['player_score']).round(),
      'rank': _asInt(latestMmr['rank']),
      'wins': wins,
      'losses': losses,
      'winRate': matches.isEmpty ? 0 : _round(wins * 100 / matches.length),
      'totalMatches': matches.length,
      'kills': kills,
      'deaths': deaths,
      'assists': assists,
      'kda': deaths == 0 ? kills + assists : _round((kills + assists) / deaths),
      'favoriteHero': heroNames[favoriteHeroId] ?? 'Unknown',
      'favoriteHeroId': favoriteHeroId,
      'topHeroes': topHeroesList,
      'hoursPlayed': (matches.fold<int>(0,
                  (total, match) => total + _asInt(match['match_duration_s'])) /
              3600)
          .round(),
      'lastPlayed': lastPlayedUnix == 0
          ? DateTime.now().toIso8601String()
          : DateTime.fromMillisecondsSinceEpoch(lastPlayedUnix * 1000)
              .toIso8601String(),
    };
  }

  Map<String, dynamic> _mapLeaderboardEntry(Map entry, String region) {
    final accountIds = (entry['possible_account_ids'] as List? ?? const []);
    final topHeroes = (entry['top_hero_ids'] as List? ?? const []);
    return {
      'rank': _asInt(entry['rank']),
      'accountId': accountIds.isEmpty ? 0 : _asInt(accountIds.first),
      'playerName': entry['account_name'] ?? 'Unknown',
      'mmr': _asInt(entry['badge_level']),
      'region': region,
      'heroId': topHeroes.isEmpty ? 0 : _asInt(topHeroes.first),
      'heroName': topHeroes.isEmpty ? 'Unknown' : 'Hero ${topHeroes.first}',
    };
  }

  List<String> _heroRoles(Map<String, dynamic> hero) {
    final heroType = '${hero['hero_type'] ?? ''}'.toLowerCase();
    final roles = <String>{
      switch (heroType) {
        'marksman' => 'Carry',
        'brawler' => 'Brawler',
        'assassin' => 'Assassin',
        'mystic' => 'Mystic',
        'tank' => 'Tank',
        'support' => 'Support',
        _ => 'Carry',
      },
    };
    for (final tag in (hero['tags'] as List? ?? const [])) {
      final lower = '$tag'.toLowerCase();
      if (lower.contains('support')) roles.add('Support');
      if (lower.contains('tank') || lower.contains('bruiser'))
        roles.add('Tank');
      if (lower.contains('explosive') || lower.contains('magic'))
        roles.add('Mage');
    }
    return roles.toList();
  }

  List<Map<String, dynamic>> _heroAbilities(Map<String, dynamic> hero) {
    final items = (hero['items'] as Map?)?.cast<String, dynamic>() ?? const {};
    final abilities = <Map<String, dynamic>>[];
    for (final entry in items.entries) {
      final key = entry.key;
      if (!key.startsWith('signature')) continue;
      final className = '${entry.value}';
      abilities.add({
        'key': key,
        'className': className,
        'name': _cleanAbilityName(className),
      });
    }
    return abilities;
  }

  String _cleanAbilityName(String raw) {
    if (raw.isEmpty) return raw;
    var cleaned = raw;
    for (final prefix in ['ability_', 'citadel_ability_', 'citadel_weapon_']) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length);
        break;
      }
    }
    return cleaned.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  List<int> _extractBuildAbilityIds(Map<String, dynamic> build) {
    final details =
        (build['details'] as Map?)?.cast<String, dynamic>() ?? const {};
    final categories = details['mod_categories'] as List? ?? const [];
    return categories
        .whereType<Map>()
        .expand((category) => (category['mods'] as List? ?? const []))
        .whereType<Map>()
        .map((mod) => _asInt(mod['ability_id']))
        .where((id) => id > 0)
        .toList();
  }

  List<Map<String, dynamic>> _seedHeroes({int? limit, String? sortBy}) {
    final heroes =
        HeroEndpoint.seedHeroes.map((hero) => hero.toJson()).toList();
    if (sortBy == 'pickRate' || sortBy == 'popularity') {
      heroes.sort((a, b) =>
          _asInt(b['matchesPlayed']).compareTo(_asInt(a['matchesPlayed'])));
    }
    return limit == null ? heroes : heroes.take(limit).toList();
  }

  List<Map<String, dynamic>> _seedBuilds({
    int? heroId,
    required int limit,
    required bool featuredOnly,
  }) {
    var builds =
        BuildEndpoint.seedBuilds.map((build) => build.toJson()).toList();
    if (heroId != null) {
      builds = builds.where((build) => build['heroId'] == heroId).toList();
    }
    if (featuredOnly) {
      builds = builds.where((build) => build['isFeatured'] == true).toList();
    }
    return builds.take(limit).toList();
  }

  String _mapRegion(String? region) {
    return switch (region?.toLowerCase()) {
      'eu' || 'europe' => 'Europe',
      'asia' => 'Asia',
      'sa' || 'south america' || 'samerica' => 'SAmerica',
      'oceania' || 'oce' => 'Oceania',
      _ => 'NAmerica',
    };
  }

  double _statValue(Object? stat) {
    if (stat is Map) return _asDouble(stat['value']);
    return _asDouble(stat);
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  double _round(num value) => double.parse(value.toStringAsFixed(1));

  String _timestampToIso(int timestamp) {
    if (timestamp <= 0) return DateTime.now().toIso8601String();
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
        .toIso8601String();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}
