import 'package:pauselock_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class HeroEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  static final List<HeroData> seedHeroes = [
    HeroData(id: 1, name: 'Lash', fullName: 'Lash', description: 'Agile assassin with high mobility.', iconUrl: '', bannerPortraitUrl: '', roles: ['Carry'], primaryAttribute: 'Agility', baseHealth: 650, baseMana: 300, baseDamageMin: 52, baseDamageMax: 58, baseArmor: 4.5, winRate: 54.2, pickRate: 18, banRate: 15, matchesPlayed: 12500, popularity: 95, abilities: ['Grapple', 'Stings', 'Parasite']),
    HeroData(id: 2, name: 'Seven', fullName: 'Seven', description: 'Powerful mage with area damage.', iconUrl: '', bannerPortraitUrl: '', roles: ['Mage'], primaryAttribute: 'Intellect', baseHealth: 600, baseMana: 450, baseDamageMin: 48, baseDamageMax: 55, baseArmor: 3.0, winRate: 51.8, pickRate: 14, banRate: 8, matchesPlayed: 9800, popularity: 82, abilities: ['Lightning', 'Static', 'Storm']),
    HeroData(id: 3, name: 'Infernus', fullName: 'Infernus', description: 'Sustained DPS hero with fire.', iconUrl: '', bannerPortraitUrl: '', roles: ['Carry'], primaryAttribute: 'Agility', baseHealth: 680, baseMana: 280, baseDamageMin: 50, baseDamageMax: 62, baseArmor: 4.0, winRate: 49.5, pickRate: 12, banRate: 10, matchesPlayed: 8400, popularity: 75, abilities: ['Burn', 'Flame', 'Inferno']),
    HeroData(id: 4, name: 'Vindicta', fullName: 'Vindicta', description: 'Sniper assassin with high burst.', iconUrl: '', bannerPortraitUrl: '', roles: ['Assassin'], primaryAttribute: 'Agility', baseHealth: 580, baseMana: 260, baseDamageMin: 55, baseDamageMax: 65, baseArmor: 2.5, winRate: 48.7, pickRate: 10, banRate: 20, matchesPlayed: 7000, popularity: 70, abilities: ['Shot', 'Venom', 'Snipe']),
    HeroData(id: 5, name: 'Haze', fullName: 'Haze', description: 'Stealth assassin with invisibility.', iconUrl: '', bannerPortraitUrl: '', roles: ['Assassin'], primaryAttribute: 'Agility', baseHealth: 590, baseMana: 290, baseDamageMin: 53, baseDamageMax: 60, baseArmor: 3.2, winRate: 52.1, pickRate: 11, banRate: 25, matchesPlayed: 7700, popularity: 78, abilities: ['Smoke', 'Slice', 'Shadow']),
    HeroData(id: 6, name: 'Abrams', fullName: 'Abrams', description: 'Tank hero with high durability.', iconUrl: '', bannerPortraitUrl: '', roles: ['Tank'], primaryAttribute: 'Vitality', baseHealth: 850, baseMana: 200, baseDamageMin: 45, baseDamageMax: 52, baseArmor: 6.5, winRate: 50.3, pickRate: 13, banRate: 5, matchesPlayed: 9100, popularity: 80, abilities: ['Shield', 'Bash', 'Rage']),
    HeroData(id: 7, name: 'Dynamo', fullName: 'Dynamo', description: 'Support hero with crowd control.', iconUrl: '', bannerPortraitUrl: '', roles: ['Support'], primaryAttribute: 'Intellect', baseHealth: 620, baseMana: 500, baseDamageMin: 40, baseDamageMax: 48, baseArmor: 3.5, winRate: 47.8, pickRate: 8, banRate: 4, matchesPlayed: 5600, popularity: 55, abilities: ['Orb', 'Gravity', 'Warp']),
    HeroData(id: 8, name: 'Kelvin', fullName: 'Kelvin', description: 'Support hero with healing.', iconUrl: '', bannerPortraitUrl: '', roles: ['Support'], primaryAttribute: 'Intellect', baseHealth: 640, baseMana: 420, baseDamageMin: 42, baseDamageMax: 50, baseArmor: 3.8, winRate: 51.2, pickRate: 9, banRate: 6, matchesPlayed: 6300, popularity: 60, abilities: ['Ice', 'Freeze', 'Heal']),
    HeroData(id: 9, name: 'Mo & Krill', fullName: 'Mo & Krill', description: 'Tank hero with area control.', iconUrl: '', bannerPortraitUrl: '', roles: ['Tank'], primaryAttribute: 'Vitality', baseHealth: 820, baseMana: 220, baseDamageMin: 44, baseDamageMax: 54, baseArmor: 5.5, winRate: 49.9, pickRate: 7, banRate: 3, matchesPlayed: 4900, popularity: 45, abilities: ['Burrow', 'Spike', 'Swarm']),
  ];

  Future<List<HeroData>> getAllHeroes(Session session, {HeroFilter? filter}) async {
    var heroes = List<HeroData>.from(seedHeroes);
    if (filter?.roles?.isNotEmpty ?? false) {
      heroes = heroes.where((h) => filter!.roles!.any(h.roles.contains)).toList();
    }
    if (filter?.primaryAttribute?.isNotEmpty ?? false) {
      heroes = heroes.where((h) => h.primaryAttribute == filter!.primaryAttribute).toList();
    }
    if (filter?.searchQuery?.isNotEmpty ?? false) {
      final query = filter!.searchQuery!.toLowerCase();
      heroes = heroes.where((h) => h.name.toLowerCase().contains(query) || h.fullName.toLowerCase().contains(query)).toList();
    }
    return filter?.limit == null ? heroes : heroes.take(filter!.limit!).toList();
  }

  Future<HeroData?> getHeroById(Session session, {required int heroId}) async =>
      seedHeroes.where((hero) => hero.id == heroId).firstOrNull;

  Future<HeroData?> getHeroByName(Session session, {required String name}) async =>
      seedHeroes.where((hero) => hero.name.toLowerCase() == name.toLowerCase()).firstOrNull;

  Future<List<HeroData>> getMetaHeroes(Session session, {int limit = 10}) async {
    final heroes = List<HeroData>.from(seedHeroes)..sort((a, b) => b.pickRate.compareTo(a.pickRate));
    return heroes.take(limit).toList();
  }

  Future<List<HeroData>> getBestWinRateHeroes(Session session, {int limit = 10, int minMatches = 100}) async {
    final heroes = seedHeroes.where((hero) => hero.matchesPlayed >= minMatches).toList()
      ..sort((a, b) => b.winRate.compareTo(a.winRate));
    return heroes.take(limit).toList();
  }
}
