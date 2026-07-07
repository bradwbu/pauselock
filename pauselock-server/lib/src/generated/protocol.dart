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
  String backgroundUrl;
  String verticalUrl;
  List<String> roles;
  String primaryAttribute;
  String heroType;
  int complexity;
  String tier;
  List<String> tags;
  int baseHealth;
  int baseMana;
  int baseDamageMin;
  int baseDamageMax;
  int baseBulletDamage;
  double baseArmor;
  double baseMoveSpeed;
  double sprintSpeed;
  double baseHealthRegen;
  double bulletArmorReduction;
  double techArmorReduction;
  double winRate;
  int pickRate;
  int banRate;
  int matchesPlayed;
  int popularity;
  List<Map<String, dynamic>> abilities;

  HeroData({
    this.id,
    required this.name,
    required this.fullName,
    required this.description,
    this.iconUrl = '',
    this.bannerPortraitUrl = '',
    this.backgroundUrl = '',
    this.verticalUrl = '',
    this.roles = const [],
    this.primaryAttribute = 'Unknown',
    this.heroType = 'Unknown',
    this.complexity = 1,
    this.tier = 'C',
    this.tags = const [],
    this.baseHealth = 0,
    this.baseMana = 0,
    this.baseDamageMin = 0,
    this.baseDamageMax = 0,
    this.baseBulletDamage = 0,
    this.baseArmor = 0,
    this.baseMoveSpeed = 0,
    this.sprintSpeed = 0,
    this.baseHealthRegen = 0,
    this.bulletArmorReduction = 0,
    this.techArmorReduction = 0,
    this.winRate = 0,
    this.pickRate = 0,
    this.banRate = 0,
    this.matchesPlayed = 0,
    this.popularity = 0,
    this.abilities = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullName': fullName,
        'description': description,
        'iconUrl': iconUrl,
        'bannerPortraitUrl': bannerPortraitUrl,
        'backgroundUrl': backgroundUrl,
        'verticalUrl': verticalUrl,
        'roles': roles,
        'primaryAttribute': primaryAttribute,
        'heroType': heroType,
        'complexity': complexity,
        'tier': tier,
        'tags': tags,
        'baseHealth': baseHealth,
        'baseMana': baseMana,
        'baseDamageMin': baseDamageMin,
        'baseDamageMax': baseDamageMax,
        'baseBulletDamage': baseBulletDamage,
        'baseArmor': baseArmor,
        'baseMoveSpeed': baseMoveSpeed,
        'sprintSpeed': sprintSpeed,
        'baseHealthRegen': baseHealthRegen,
        'bulletArmorReduction': bulletArmorReduction,
        'techArmorReduction': techArmorReduction,
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

class ItemData {
  int id;
  String className;
  String name;
  int cost;
  String imageUrl;
  String slotType;
  int tier;
  bool isActive;

  ItemData({
    required this.id,
    required this.className,
    required this.name,
    required this.cost,
    required this.imageUrl,
    required this.slotType,
    required this.tier,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'className': className,
        'name': name,
        'cost': cost,
        'imageUrl': imageUrl,
        'slotType': slotType,
        'tier': tier,
        'isActive': isActive,
      };
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

class UserAccount {
  int id;
  String email;
  String username;
  String passwordHash;
  String role;
  String firstName;
  String lastName;
  int? steamAccountId;
  String? avatarUrl;
  DateTime createdAt;
  DateTime lastLogin;
  bool isActive;

  UserAccount({
    required this.id,
    required this.email,
    required this.username,
    required this.passwordHash,
    this.role = 'user',
    this.firstName = '',
    this.lastName = '',
    this.steamAccountId,
    this.avatarUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    this.isActive = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastLogin = lastLogin ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'steamAccountId': steamAccountId,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin.toIso8601String(),
        'isActive': isActive,
      };

  Map<String, dynamic> toSafeJson() => {
        'id': id,
        'email': email,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'steamAccountId': steamAccountId,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin.toIso8601String(),
        'isActive': isActive,
      };
}

class AuthToken {
  String token;
  int userId;
  String role;
  DateTime expiresAt;

  AuthToken({
    required this.token,
    required this.userId,
    required this.role,
    DateTime? expiresAt,
  }) : expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 7));

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'role': role,
        'expiresAt': expiresAt.toIso8601String(),
      };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class HeroTierOverride {
  int heroId;
  String tier;
  String? setBy;
  DateTime? setAt;

  HeroTierOverride({
    required this.heroId,
    required this.tier,
    this.setBy,
    this.setAt,
  });

  Map<String, dynamic> toJson() => {
        'heroId': heroId,
        'tier': tier,
        'setBy': setBy,
        'setAt': setAt?.toIso8601String(),
      };
}
