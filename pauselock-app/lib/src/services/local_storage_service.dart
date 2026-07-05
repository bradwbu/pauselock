import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyAccountId = 'accountId';
  static const String _keyFavBuilds = 'favoriteBuilds';
  static const String _keyFavHeroes = 'favoriteHeroes';
  static const String _keyAuthToken = 'authToken';
  static const String _keyAuthUser = 'authUser';
  static const String _keyDismissedAnnouncements = 'dismissedAnnouncements';

  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static int? getAccountId() {
    final id = _prefs.getInt(_keyAccountId);
    return id == 0 ? null : id;
  }

  static Future<void> setAccountId(int? id) async {
    if (id == null) {
      await _prefs.remove(_keyAccountId);
    } else {
      await _prefs.setInt(_keyAccountId, id);
    }
  }

  static List<int> getFavoriteBuilds() {
    final list = _prefs.getStringList(_keyFavBuilds) ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();
  }

  static Future<void> addFavoriteBuild(int buildId) async {
    final list = getFavoriteBuilds();
    if (!list.contains(buildId)) {
      list.add(buildId);
      await _prefs.setStringList(_keyFavBuilds, list.map((e) => e.toString()).toList());
    }
  }

  static Future<void> removeFavoriteBuild(int buildId) async {
    final list = getFavoriteBuilds();
    list.remove(buildId);
    await _prefs.setStringList(_keyFavBuilds, list.map((e) => e.toString()).toList());
  }

  static List<int> getFavoriteHeroes() {
    final list = _prefs.getStringList(_keyFavHeroes) ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();
  }

  static Future<void> addFavoriteHero(int heroId) async {
    final list = getFavoriteHeroes();
    if (!list.contains(heroId)) {
      list.add(heroId);
      await _prefs.setStringList(_keyFavHeroes, list.map((e) => e.toString()).toList());
    }
  }

  static Future<void> removeFavoriteHero(int heroId) async {
    final list = getFavoriteHeroes();
    list.remove(heroId);
    await _prefs.setStringList(_keyFavHeroes, list.map((e) => e.toString()).toList());
  }

  static String? getAuthToken() => _prefs.getString(_keyAuthToken);

  static Map<String, dynamic>? getAuthUser() {
    final json = _prefs.getString(_keyAuthUser);
    if (json == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAuthToken(String token) async {
    await _prefs.setString(_keyAuthToken, token);
  }

  static Future<void> saveAuthUser(Map<String, dynamic> user) async {
    await _prefs.setString(_keyAuthUser, jsonEncode(user));
  }

  static Future<void> clearAuth() async {
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyAuthUser);
  }

  static Set<int> getDismissedAnnouncements() {
    final list = _prefs.getStringList(_keyDismissedAnnouncements) ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toSet();
  }

  static Future<void> dismissAnnouncement(int id) async {
    final set = getDismissedAnnouncements();
    set.add(id);
    await _prefs.setStringList(
        _keyDismissedAnnouncements, set.map((e) => e.toString()).toList());
  }
}
