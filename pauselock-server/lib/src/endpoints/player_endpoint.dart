import 'package:pauselock_server/src/generated/protocol.dart';
import 'package:pauselock_server/src/services/deadlock_api_service.dart';
import 'package:serverpod/serverpod.dart';

class PlayerEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  static final List<PlayerStats> seedPlayers = [
    PlayerStats(
        id: 1,
        accountId: 1001,
        playerName: 'ProGamer123',
        mmr: 3520,
        rank: 1,
        wins: 665,
        losses: 569,
        winRate: 53.9,
        totalMatches: 1234,
        kills: 8500,
        deaths: 4200,
        assists: 5100,
        kda: 2.1,
        favoriteHero: 'Lash',
        favoriteHeroId: 1,
        hoursPlayed: 450,
        lastPlayed: DateTime.now().subtract(const Duration(hours: 2))),
    PlayerStats(
        id: 2,
        accountId: 1002,
        playerName: 'ShadowStrike',
        mmr: 3450,
        rank: 2,
        wins: 620,
        losses: 580,
        winRate: 51.7,
        totalMatches: 1200,
        kills: 7800,
        deaths: 4500,
        assists: 4800,
        kda: 1.9,
        favoriteHero: 'Seven',
        favoriteHeroId: 2,
        hoursPlayed: 420,
        lastPlayed: DateTime.now().subtract(const Duration(hours: 5))),
    PlayerStats(
        id: 3,
        accountId: 1003,
        playerName: 'InfernoMaster',
        mmr: 3380,
        rank: 3,
        wins: 600,
        losses: 590,
        winRate: 50.4,
        totalMatches: 1190,
        kills: 7200,
        deaths: 4800,
        assists: 4400,
        kda: 1.8,
        favoriteHero: 'Infernus',
        favoriteHeroId: 3,
        hoursPlayed: 400,
        lastPlayed: DateTime.now().subtract(const Duration(hours: 8))),
    PlayerStats(
        id: 4,
        accountId: 1004,
        playerName: 'SniperWolf',
        mmr: 3300,
        rank: 4,
        wins: 580,
        losses: 540,
        winRate: 51.8,
        totalMatches: 1120,
        kills: 6900,
        deaths: 4100,
        assists: 3900,
        kda: 2.0,
        favoriteHero: 'Vindicta',
        favoriteHeroId: 4,
        hoursPlayed: 380,
        lastPlayed: DateTime.now().subtract(const Duration(days: 1))),
    PlayerStats(
        id: 5,
        accountId: 1005,
        playerName: 'GhostBlade',
        mmr: 3250,
        rank: 5,
        wins: 560,
        losses: 530,
        winRate: 51.4,
        totalMatches: 1090,
        kills: 6500,
        deaths: 4000,
        assists: 3700,
        kda: 1.9,
        favoriteHero: 'Haze',
        favoriteHeroId: 5,
        hoursPlayed: 360,
        lastPlayed: DateTime.now().subtract(const Duration(days: 1))),
  ];

  Future<PlayerStats?> getPlayerStats(Session session,
          {required int accountId}) async =>
      seedPlayers.where((player) => player.accountId == accountId).firstOrNull;

  Future<List<PlayerStats>> searchPlayers(Session session,
      {required String query}) async {
    final normalized = query.toLowerCase();
    return seedPlayers
        .where((player) => player.playerName.toLowerCase().contains(normalized))
        .take(20)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPlayerMatches(Session session,
      {required int accountId, int limit = 20}) async {
    final service = DeadlockApiService();
    return service.getPlayerMatches(accountId, limit: limit);
  }

  Future<Map<String, dynamic>?> getPlayerRank(Session session,
      {required int accountId}) async {
    final service = DeadlockApiService();
    return service.getPlayerRank(accountId);
  }
}
