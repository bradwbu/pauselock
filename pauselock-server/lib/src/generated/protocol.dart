class PlayerStats {
  int? id;
  int accountId;
  String playerName;
  int mmr;
  int rank;
  int wins;
  int losses;
  double winRate;
  int totalMatches;
  int kills;
  int deaths;
  int assists;
  double kda;
  String favoriteHero;
  int favoriteHeroId;
  int hoursPlayed;
  DateTime lastPlayed;

  PlayerStats({
    this.id,
    required this.accountId,
    required this.playerName,
    required this.mmr,
    required this.rank,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.totalMatches,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.kda,
    required this.favoriteHero,
    required this.favoriteHeroId,
    required this.hoursPlayed,
    required this.lastPlayed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'playerName': playerName,
        'mmr': mmr,
        'rank': rank,
        'wins': wins,
        'losses': losses,
        'winRate': winRate,
        'totalMatches': totalMatches,
        'kills': kills,
        'deaths': deaths,
        'assists': assists,
        'kda': kda,
        'favoriteHero': favoriteHero,
        'favoriteHeroId': favoriteHeroId,
        'hoursPlayed': hoursPlayed,
        'lastPlayed': lastPlayed.toIso8601String(),
      };
}

class HeroData {
  int? id;
  String name;
  String fullName;
  String description;
  String iconUrl;
  String bannerPortraitUrl;
  List<String> roles;
  String primaryAttribute;
  int baseHealth;
  int baseMana;
  int baseDamageMin;
  int baseDamageMax;
  double baseArmor;
  double winRate;
  int pickRate;
  int banRate;
  int matchesPlayed;
  int popularity;
  List<String> abilities;

  HeroData({
    this.id,
    required this.name,
    required this.fullName,
    required this.description,
    required this.iconUrl,
    required this.bannerPortraitUrl,
    required this.roles,
    required this.primaryAttribute,
    required this.baseHealth,
    required this.baseMana,
    required this.baseDamageMin,
    required this.baseDamageMax,
    required this.baseArmor,
    required this.winRate,
    required this.pickRate,
    required this.banRate,
    required this.matchesPlayed,
    required this.popularity,
    required this.abilities,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullName': fullName,
        'description': description,
        'iconUrl': iconUrl,
        'bannerPortraitUrl': bannerPortraitUrl,
        'roles': roles,
        'primaryAttribute': primaryAttribute,
        'baseHealth': baseHealth,
        'baseMana': baseMana,
        'baseDamageMin': baseDamageMin,
        'baseDamageMax': baseDamageMax,
        'baseArmor': baseArmor,
        'winRate': winRate,
        'pickRate': pickRate,
        'banRate': banRate,
        'matchesPlayed': matchesPlayed,
        'popularity': popularity,
        'abilities': abilities,
      };
}

class BuildData {
  int? id;
  int heroId;
  String heroName;
  String buildName;
  String author;
  int authorAccountId;
  List<String> itemIds;
  List<String> items;
  List<String> talents;
  String description;
  int upvotes;
  int downvotes;
  double winRate;
  int matchesPlayed;
  DateTime createdAt;
  bool isPublic;
  bool isFeatured;
  List<String> tags;

  BuildData({
    this.id,
    required this.heroId,
    required this.heroName,
    required this.buildName,
    required this.author,
    required this.authorAccountId,
    required this.itemIds,
    required this.items,
    required this.talents,
    required this.description,
    required this.upvotes,
    required this.downvotes,
    required this.winRate,
    required this.matchesPlayed,
    required this.createdAt,
    required this.isPublic,
    required this.isFeatured,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'heroId': heroId,
        'heroName': heroName,
        'buildName': buildName,
        'author': author,
        'authorAccountId': authorAccountId,
        'itemIds': itemIds,
        'items': items,
        'talents': talents,
        'description': description,
        'upvotes': upvotes,
        'downvotes': downvotes,
        'winRate': winRate,
        'matchesPlayed': matchesPlayed,
        'createdAt': createdAt.toIso8601String(),
        'isPublic': isPublic,
        'isFeatured': isFeatured,
        'tags': tags,
      };
}

class LeaderboardEntry {
  int rank;
  int accountId;
  String playerName;
  int mmr;
  String region;
  int heroId;
  String heroName;

  LeaderboardEntry({
    required this.rank,
    required this.accountId,
    required this.playerName,
    required this.mmr,
    required this.region,
    required this.heroId,
    required this.heroName,
  });

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'accountId': accountId,
        'playerName': playerName,
        'mmr': mmr,
        'region': region,
        'heroId': heroId,
        'heroName': heroName,
      };
}

class HeroFilter {
  List<String>? roles;
  String? primaryAttribute;
  String? searchQuery;
  int? limit;

  HeroFilter({this.roles, this.primaryAttribute, this.searchQuery, this.limit});
}

class BuildFilter {
  int? heroId;
  String? searchQuery;
  String? sortBy;
  int? limit;
  bool? featuredOnly;

  BuildFilter({
    this.heroId,
    this.searchQuery,
    this.sortBy,
    this.limit,
    this.featuredOnly,
  });
}
