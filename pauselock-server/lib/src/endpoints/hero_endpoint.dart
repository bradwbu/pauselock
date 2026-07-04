import 'package:pauselock_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class HeroEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  static final List<HeroData> seedHeroes = [
    HeroData(id: 1, name: 'Infernus', fullName: 'Infernus', description: 'Sustained DPS hero with fire-based abilities and strong lane presence.', heroType: 'marksman', complexity: 1, tier: 'B', tags: ['Arsonist', 'Explosive', 'Burn Rubber']),
    HeroData(id: 2, name: 'Seven', fullName: 'Seven', description: 'Powerful mage with devastating area damage and crowd control.', heroType: 'mystic', complexity: 1, tier: 'B', tags: ['Lightning', 'Control']),
    HeroData(id: 3, name: 'Vindicta', fullName: 'Vindicta', description: 'Sniper assassin with high burst damage from long range.', heroType: 'marksman', complexity: 1, tier: 'A', tags: ['Sniper', 'Burst']),
    HeroData(id: 4, name: 'Lady Geist', fullName: 'Lady Geist', description: 'Mystic hero with life-drain and manipulation abilities.', heroType: 'mystic', complexity: 2, tier: 'A', tags: ['Life Drain', 'Manipulation']),
    HeroData(id: 6, name: 'Abrams', fullName: 'Abrams', description: 'Tank hero with high durability and melee combat focus.', heroType: 'brawler', complexity: 1, tier: 'S', tags: ['Tank', 'Melee']),
    HeroData(id: 7, name: 'Wraith', fullName: 'Wraith', description: 'Marksman with card-based attacks and tactical gameplay.', heroType: 'marksman', complexity: 1, tier: 'B', tags: ['Cards', 'Tactical']),
    HeroData(id: 8, name: 'McGinnis', fullName: 'McGinnis', description: 'Mystic hero with turret deployment and area denial.', heroType: 'mystic', complexity: 1, tier: 'B', tags: ['Turrets', 'Area Denial']),
    HeroData(id: 10, name: 'Paradox', fullName: 'Paradox', description: 'Marksman with time-manipulation and complex mechanics.', heroType: 'marksman', complexity: 3, tier: 'S', tags: ['Time', 'Complex']),
    HeroData(id: 11, name: 'Dynamo', fullName: 'Dynamo', description: 'Support hero with gravity-based crowd control and utility.', heroType: 'mystic', complexity: 2, tier: 'A', tags: ['Gravity', 'Support', 'Control']),
    HeroData(id: 12, name: 'Kelvin', fullName: 'Kelvin', description: 'Brawler with ice-based abilities and strong sustain.', heroType: 'brawler', complexity: 2, tier: 'S', tags: ['Ice', 'Sustain']),
    HeroData(id: 13, name: 'Haze', fullName: 'Haze', description: 'Stealth assassin with invisibility and burst damage.', heroType: 'assassin', complexity: 1, tier: 'S', tags: ['Stealth', 'Burst', 'Assassinate']),
    HeroData(id: 14, name: 'Holliday', fullName: 'Holliday', description: 'Marksman with high mobility and versatile combat.', heroType: 'marksman', complexity: 3, tier: 'B', tags: ['Mobile', 'Versatile']),
    HeroData(id: 15, name: 'Bebop', fullName: 'Bebop', description: 'Brawler with hook mechanics and disruptive presence.', heroType: 'brawler', complexity: 2, tier: 'A', tags: ['Hook', 'Disruptor']),
    HeroData(id: 16, name: 'Calico', fullName: 'Calico', description: 'Assassin with cat-like agility and elusive gameplay.', heroType: 'assassin', complexity: 2, tier: 'A', tags: ['Agile', 'Elusive']),
    HeroData(id: 17, name: 'Grey Talon', fullName: 'Grey Talon', description: 'Marksman with arrow-based attacks and precision.', heroType: 'marksman', complexity: 2, tier: 'B', tags: ['Arrows', 'Precision']),
    HeroData(id: 18, name: 'Mo & Krill', fullName: 'Mo & Krill', description: 'Brawler duo with area control and tanky frontline.', heroType: 'brawler', complexity: 3, tier: 'A', tags: ['Duo', 'Area Control', 'Tank']),
    HeroData(id: 19, name: 'Shiv', fullName: 'Shiv', description: 'Brawler with rage mechanics and aggressive playstyle.', heroType: 'brawler', complexity: 3, tier: 'S', tags: ['Rage', 'Aggressive']),
    HeroData(id: 20, name: 'Ivy', fullName: 'Ivy', description: 'Marksman with flying mechanics and global presence.', heroType: 'marksman', complexity: 3, tier: 'A', tags: ['Flying', 'Global']),
    HeroData(id: 25, name: 'Warden', fullName: 'Warden', description: 'Brawler with lockdown and crowd control focus.', heroType: 'brawler', complexity: 2, tier: 'A', tags: ['Lockdown', 'CC']),
    HeroData(id: 27, name: 'Yamato', fullName: 'Yamato', description: 'Assassin with blade-based combat and fast kills.', heroType: 'assassin', complexity: 3, tier: 'S', tags: ['Blade', 'Fast Kill']),
    HeroData(id: 31, name: 'Lash', fullName: 'Lash', description: 'Assassin with grappling hook and high mobility.', heroType: 'assassin', complexity: 3, tier: 'S', tags: ['Grapple', 'High Mobility']),
    HeroData(id: 35, name: 'Viscous', fullName: 'Viscous', description: 'Mystic hero with goo-based abilities and unique mechanics.', heroType: 'mystic', complexity: 2, tier: 'B', tags: ['Goo', 'Unique']),
    HeroData(id: 50, name: 'Pocket', fullName: 'Pocket', description: 'Assassin with teleportation and deceptive play.', heroType: 'assassin', complexity: 2, tier: 'A', tags: ['Teleport', 'Deception']),
    HeroData(id: 52, name: 'Mirage', fullName: 'Mirage', description: 'Assassin with illusion-based combat.', heroType: 'assassin', complexity: 2, tier: 'B', tags: ['Illusion', 'Deception']),
    HeroData(id: 58, name: 'Vyper', fullName: 'Vyper', description: 'Assassin with venom-based attacks and stealth.', heroType: 'assassin', complexity: 1, tier: 'B', tags: ['Venom', 'Stealth']),
    HeroData(id: 60, name: 'Sinclair', fullName: 'Sinclair', description: 'Mystic hero with complex spell combinations.', heroType: 'mystic', complexity: 4, tier: 'S', tags: ['Spells', 'Complex', 'High Skill']),
    HeroData(id: 63, name: 'Mina', fullName: 'Mina', description: 'Marksman with versatile ranged combat.', heroType: 'marksman', complexity: 3, tier: 'A', tags: ['Ranged', 'Versatile']),
    HeroData(id: 64, name: 'Drifter', fullName: 'Drifter', description: 'Assassin with dash-based combat and slippery movement.', heroType: 'assassin', complexity: 3, tier: 'A', tags: ['Dash', 'Slippery']),
    HeroData(id: 65, name: 'Venator', fullName: 'Venator', description: 'Marksman with hunting-themed abilities.', heroType: 'marksman', complexity: 2, tier: 'B', tags: ['Hunter', 'Tracking']),
    HeroData(id: 66, name: 'Victor', fullName: 'Victor', description: 'Brawler with brawling mechanics and tankiness.', heroType: 'brawler', complexity: 2, tier: 'B', tags: ['Brawler', 'Tank']),
    HeroData(id: 67, name: 'Paige', fullName: 'Paige', description: 'Mystic hero with support and damage capabilities.', heroType: 'mystic', complexity: 1, tier: 'B', tags: ['Support', 'Damage']),
    HeroData(id: 69, name: 'The Doorman', fullName: 'The Doorman', description: 'Mystic hero with zone control and area denial.', heroType: 'mystic', complexity: 1, tier: 'B', tags: ['Zone Control', 'Area Denial']),
    HeroData(id: 72, name: 'Billy', fullName: 'Billy', description: 'Brawler with aggressive melee combat.', heroType: 'brawler', complexity: 3, tier: 'B', tags: ['Aggressive', 'Melee']),
    HeroData(id: 76, name: 'Graves', fullName: 'Graves', description: 'Marksman with shotgun-based close range.', heroType: 'marksman', complexity: 2, tier: 'B', tags: ['Shotgun', 'Close Range']),
    HeroData(id: 77, name: 'Apollo', fullName: 'Apollo', description: 'Assassin with divine-themed abilities.', heroType: 'assassin', complexity: 2, tier: 'B', tags: ['Divine', 'Burst']),
    HeroData(id: 80, name: 'Silver', fullName: 'Silver', description: 'Marksman with metallic-themed ranged attacks.', heroType: 'marksman', complexity: 1, tier: 'B', tags: ['Metal', 'Ranged']),
    HeroData(id: 81, name: 'Celeste', fullName: 'Celeste', description: 'Marksman with cosmic-themed precision.', heroType: 'marksman', complexity: 2, tier: 'B', tags: ['Cosmic', 'Precision']),
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
