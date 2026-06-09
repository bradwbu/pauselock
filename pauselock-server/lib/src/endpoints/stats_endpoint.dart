import 'package:serverpod/serverpod.dart';
import 'package:pauselock_server/src/generated/protocol.dart';
import 'package:pauselock_server/src/services/deadlock_api_service.dart';

class StatsEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<Map<String, dynamic>?> getGlobalStats(Session session) async {
    final service = DeadlockApiService();
    return await service.getWinRates();
  }

  Future<Map<String, dynamic>?> getHeroWinRates(Session session,
      {int? heroId}) async {
    final service = DeadlockApiService();
    return await service.getHeroWinRates(heroId: heroId);
  }

  Future<List<LeaderboardEntry>> getLeaderboard(
    Session session, {
    String? region,
    int limit = 100,
  }) async {
    final service = DeadlockApiService();
    final data = await service.getLeaderboard(region: region, limit: limit);

    try {
      return data
          .map((e) => LeaderboardEntry(
                rank: e['rank'] ?? 0,
                accountId: e['accountId'] ?? 0,
                playerName: e['playerName'] ?? 'Unknown',
                mmr: e['mmr'] ?? 0,
                region: e['region'] ?? 'unknown',
                heroId: e['heroId'] ?? 0,
                heroName: e['heroName'] ?? 'Unknown',
              ))
          .toList();
    } catch (e) {
      session.log('Error parsing leaderboard: $e', level: LogLevel.error);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMetaSnapshot(Session session) async {
    final service = DeadlockApiService();
    return await service.getMetaBuilds();
  }
}
