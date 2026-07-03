import 'package:pauselock_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class BuildEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  static final List<BuildData> seedBuilds = [
    // Lash - Burst Assassin: weapon + spirit burst items
    BuildData(id: 1, heroId: 1, heroName: 'Lash', buildName: 'Burst Assassin', author: 'ProPlayer1', authorAccountId: 1001, itemIds: ['2010028405', '4104549924', '1998374645', '3270001687', '2717651715', '630839635'], items: ['Headshot Booster', 'Swift Striker', 'Mystic Burst', 'Warp Stone', 'Superior Duration', 'Echo Shard'], talents: ['Drain', 'Chain Lightning', 'Ult'], description: 'Maximize burst damage for early game kills.', upvotes: 150, downvotes: 10, winRate: 54.2, matchesPlayed: 2100, createdAt: DateTime.now().subtract(const Duration(days: 5)), isPublic: true, isFeatured: true, tags: ['Burst', 'Carry']),
    // Seven - Lightning Mage: spirit/mage items
    BuildData(id: 2, heroId: 2, heroName: 'Seven', buildName: 'Lightning Mage', author: 'ProPlayer2', authorAccountId: 1002, itemIds: ['1439347412', '380806748', '1976391348', '3261353684', '1292979587', '915014646'], items: ['Mystic Regeneration', 'Compress Cooldown', 'Cold Front', 'Superior Cooldown', 'Surge of Power', 'Transcendent Cooldown'], talents: ['Static Field', 'Thunder Strike', 'Ult'], description: 'Area damage and crowd control.', upvotes: 120, downvotes: 8, winRate: 51.8, matchesPlayed: 1800, createdAt: DateTime.now().subtract(const Duration(days: 3)), isPublic: true, isFeatured: true, tags: ['Magic', 'Poke']),
    // Infernus - Sustained DPS: weapon + vitality
    BuildData(id: 3, heroId: 3, heroName: 'Infernus', buildName: 'Sustained DPS', author: 'ProPlayer3', authorAccountId: 1003, itemIds: ['668299740', '499683006', '3696726732', '393974127', '865846625', '1282141666'], items: ['Rapid Rounds', 'Bullet Lifesteal', 'Toxic Bullets', 'Slowing Bullets', 'Leech', 'Siphon Bullets'], talents: ['Burn', 'Flame Burst', 'Ult'], description: 'High sustained damage over time.', upvotes: 95, downvotes: 5, winRate: 49.5, matchesPlayed: 3200, createdAt: DateTime.now().subtract(const Duration(days: 7)), isPublic: true, isFeatured: false, tags: ['DPS', 'Sustain']),
    // Vindicta - Crit Sniper: weapon heavy
    BuildData(id: 4, heroId: 4, heroName: 'Vindicta', buildName: 'Crit Sniper', author: 'ProPlayer4', authorAccountId: 1004, itemIds: ['3077079169', '381961617', '2152872419', '2678489038', '1396247347', '3884003354'], items: ['High-Velocity Rounds', 'Active Reload', 'Sharpshooter', 'Hollow Point', 'Lucky Shot', 'Crippling Headshot'], talents: ['Snipe', 'Venom Strike', 'Ult'], description: 'One shot one kill.', upvotes: 88, downvotes: 12, winRate: 48.7, matchesPlayed: 1500, createdAt: DateTime.now().subtract(const Duration(days: 2)), isPublic: true, isFeatured: false, tags: ['Burst', 'Sniper']),
    // Haze - Stealth Assassin: weapon + spirit
    BuildData(id: 5, heroId: 5, heroName: 'Haze', buildName: 'Stealth Assassin', author: 'ProPlayer5', authorAccountId: 1005, itemIds: ['1437614329', '98582110', '84321454', '1798666702', '2480592370', '1371725689'], items: ['Melee Lifesteal', 'Stalker', 'Quicksilver Reload', 'Shadow Weave', 'Ricochet', 'Phantom Strike'], talents: ['Shadow Strike', 'Poison Cloud', 'Ult'], description: 'Invisibility and high single target damage.', upvotes: 110, downvotes: 6, winRate: 52.1, matchesPlayed: 2800, createdAt: DateTime.now().subtract(const Duration(days: 1)), isPublic: true, isFeatured: true, tags: ['Stealth', 'Assassin']),
  ];

  Future<List<BuildData>> getBuilds(Session session, {BuildFilter? filter}) async {
    var builds = List<BuildData>.from(seedBuilds);
    if (filter?.heroId != null) {
      builds = builds.where((build) => build.heroId == filter!.heroId).toList();
    }
    if (filter?.searchQuery?.isNotEmpty ?? false) {
      final query = filter!.searchQuery!.toLowerCase();
      builds = builds.where((build) => build.buildName.toLowerCase().contains(query) || build.description.toLowerCase().contains(query)).toList();
    }
    if (filter?.featuredOnly ?? false) {
      builds = builds.where((build) => build.isFeatured).toList();
    }
    switch (filter?.sortBy) {
      case 'popularity':
        builds.sort((a, b) => b.matchesPlayed.compareTo(a.matchesPlayed));
      case 'recent':
        builds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'winRate':
      default:
        builds.sort((a, b) => b.winRate.compareTo(a.winRate));
    }
    return filter?.limit == null ? builds : builds.take(filter!.limit!).toList();
  }

  Future<BuildData?> getBuildById(Session session, {required int buildId}) async =>
      seedBuilds.where((build) => build.id == buildId).firstOrNull;

  Future<List<BuildData>> getFeaturedBuilds(Session session, {int limit = 10}) async =>
      seedBuilds.where((build) => build.isFeatured).take(limit).toList();

  Future<List<BuildData>> getBuildsByHero(Session session, {required int heroId, int limit = 10}) async =>
      seedBuilds.where((build) => build.heroId == heroId).take(limit).toList();

  Future<BuildData> createBuild(Session session, {required BuildData build}) async {
    build.id = (seedBuilds.map((item) => item.id ?? 0).fold<int>(0, (max, id) => id > max ? id : max)) + 1;
    build.createdAt = DateTime.now();
    seedBuilds.add(build);
    return build;
  }

  Future<bool> upvoteBuild(Session session, {required int buildId}) async {
    final build = seedBuilds.where((item) => item.id == buildId).firstOrNull;
    if (build == null) return false;
    build.upvotes += 1;
    return true;
  }
}
