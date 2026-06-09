import 'package:pauselock_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class BuildEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  static final List<BuildData> seedBuilds = [
    BuildData(id: 1, heroId: 1, heroName: 'Lash', buildName: 'Burst Assassin', author: 'ProPlayer1', authorAccountId: 1001, itemIds: ['1', '2', '3'], items: ['Phase Boots', 'Rupture', 'Vitality'], talents: ['1', '2', '3'], description: 'Maximize burst damage for early game kills.', upvotes: 150, downvotes: 10, winRate: 54.2, matchesPlayed: 2100, createdAt: DateTime.now().subtract(const Duration(days: 5)), isPublic: true, isFeatured: true, tags: ['Burst', 'Carry']),
    BuildData(id: 2, heroId: 2, heroName: 'Seven', buildName: 'Lightning Mage', author: 'ProPlayer2', authorAccountId: 1002, itemIds: ['4', '5', '6'], items: ['Magic Boots', 'Polaris', 'Energy'], talents: ['1', '2', '3'], description: 'Area damage and crowd control.', upvotes: 120, downvotes: 8, winRate: 51.8, matchesPlayed: 1800, createdAt: DateTime.now().subtract(const Duration(days: 3)), isPublic: true, isFeatured: true, tags: ['Magic', 'Poke']),
    BuildData(id: 3, heroId: 3, heroName: 'Infernus', buildName: 'Sustained DPS', author: 'ProPlayer3', authorAccountId: 1003, itemIds: ['7', '8', '9'], items: ['Accelerator', 'Piercing', 'Damage'], talents: ['1', '2', '3'], description: 'High sustained damage over time.', upvotes: 95, downvotes: 5, winRate: 49.5, matchesPlayed: 3200, createdAt: DateTime.now().subtract(const Duration(days: 7)), isPublic: true, isFeatured: false, tags: ['DPS', 'Sustain']),
    BuildData(id: 4, heroId: 4, heroName: 'Vindicta', buildName: 'Crit Sniper', author: 'ProPlayer4', authorAccountId: 1004, itemIds: ['10', '11', '12'], items: ['Sniper Rifle', 'Scope', 'Damage'], talents: ['1', '2', '3'], description: 'One shot one kill.', upvotes: 88, downvotes: 12, winRate: 48.7, matchesPlayed: 1500, createdAt: DateTime.now().subtract(const Duration(days: 2)), isPublic: true, isFeatured: false, tags: ['Burst', 'Sniper']),
    BuildData(id: 5, heroId: 5, heroName: 'Haze', buildName: 'Stealth Assassin', author: 'ProPlayer5', authorAccountId: 1005, itemIds: ['13', '14', '15'], items: ['Speed', 'Stealth', 'Dagger'], talents: ['1', '2', '3'], description: 'Invisibility and high single target damage.', upvotes: 110, downvotes: 6, winRate: 52.1, matchesPlayed: 2800, createdAt: DateTime.now().subtract(const Duration(days: 1)), isPublic: true, isFeatured: true, tags: ['Stealth', 'Assassin']),
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
