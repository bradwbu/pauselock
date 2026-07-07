import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pauselock_server/src/generated/protocol.dart';
import 'package:pauselock_server/src/services/deadlock_api_service.dart';

const _tierOverridesFile = '/opt/pauselock/data/tier_overrides.json';
const _usersFile = '/opt/pauselock/data/users.json';
const _tokensFile = '/opt/pauselock/data/tokens.json';
const _announcementsFile = '/opt/pauselock/data/announcements.json';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final List<UserAccount> _users = [];
  final Map<String, AuthToken> _tokens = {};
  final Map<int, HeroTierOverride> _tierOverrides = {};
  final List<Map<String, dynamic>> _announcements = [];
  int _nextUserId = 1;

  void initialize() {
    _loadUsers();
    _loadTokens();
    _loadTierOverrides();
    _loadAnnouncements();
    if (_users.isEmpty) {
      _seedAdminUser();
      _saveUsers();
    }
    if (_announcements.isEmpty) {
      createAnnouncement(
        'Pauselock is currently under development and is subject to change at any time. Hero tiers are of my own opinion, but player voting will be implemented in the future so that hero tiers are a shared opinion.',
        'info',
        'system',
      );
    }
  }

  void _seedAdminUser() {
    _createUser('admin@pauselock.pro', 'admin', _hashPassword('admin123'),
        role: 'admin');
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode('pauselock_salt_$password');
    return sha256.convert(bytes).toString();
  }

  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
        List.generate(32, (_) => random.nextInt(256)));
    return base64Url.encode(bytes);
  }

  UserAccount? _createUser(String email, String username, String passwordHash,
      {String role = 'user', String firstName = '', String lastName = ''}) {
    final exists = _users.any((u) => u.email == email || u.username == username);
    if (exists) return null;
    final user = UserAccount(
      id: _nextUserId++,
      email: email,
      username: username,
      passwordHash: passwordHash,
      role: role,
      firstName: firstName,
      lastName: lastName,
    );
    _users.add(user);
    _saveUsers();
    return user;
  }

  Map<String, dynamic> register(String email, String username, String password,
      {String firstName = '', String lastName = ''}) {
    if (email.trim().isEmpty || username.trim().isEmpty || password.isEmpty) {
      return {'error': 'All fields are required'};
    }
    if (password.length < 6) {
      return {'error': 'Password must be at least 6 characters'};
    }
    if (!email.contains('@')) {
      return {'error': 'Invalid email address'};
    }
    final user = _createUser(email, username, _hashPassword(password),
        firstName: firstName, lastName: lastName);
    if (user == null) {
      return {'error': 'Email or username already exists'};
    }
    final token = _createToken(user);
    return {
      'user': user.toSafeJson(),
      'token': token.toJson(),
    };
  }

  Map<String, dynamic> login(String emailOrUsername, String password) {
    final user = _users.firstWhere(
      (u) => u.email == emailOrUsername || u.username == emailOrUsername,
      orElse: () => UserAccount(
          id: 0, email: '', username: '', passwordHash: ''),
    );
    if (user.id == 0) {
      return {'error': 'User not found'};
    }
    if (!_verifyPassword(password, user.passwordHash)) {
      return {'error': 'Invalid password'};
    }
    if (!user.isActive) {
      return {'error': 'Account is disabled'};
    }
    user.lastLogin = DateTime.now();
    final token = _createToken(user);
    return {
      'user': user.toSafeJson(),
      'token': token.toJson(),
    };
  }

  AuthToken _createToken(UserAccount user) {
    final tokenStr = _generateToken();
    final token = AuthToken(
      token: tokenStr,
      userId: user.id,
      role: user.role,
    );
    _tokens[tokenStr] = token;
    _saveTokens();
    return token;
  }

  UserAccount? validateToken(String? tokenStr) {
    if (tokenStr == null || tokenStr.isEmpty) return null;
    final token = _tokens[tokenStr];
    if (token == null || token.isExpired) {
      if (token != null) _tokens.remove(tokenStr);
      return null;
    }
    return _users.firstWhere(
      (u) => u.id == token.userId,
      orElse: () => UserAccount(
          id: 0, email: '', username: '', passwordHash: ''),
    );
  }

  bool isAdmin(UserAccount? user) =>
      user != null && (user.role == 'admin' || user.role == 'moderator');

  bool isAdminRole(UserAccount? user) =>
      user != null && user.role == 'admin';

  void logout(String tokenStr) {
    _tokens.remove(tokenStr);
    _saveTokens();
  }

  UserAccount? getUserById(int id) {
    return _users.firstWhere(
      (u) => u.id == id,
      orElse: () =>
          UserAccount(id: 0, email: '', username: '', passwordHash: ''),
    );
  }

  List<Map<String, dynamic>> listUsers() {
    return _users.map((u) => u.toSafeJson()).toList();
  }

  bool updateUserRole(int userId, String role, UserAccount? admin) {
    if (!isAdminRole(admin)) return false;
    final user = getUserById(userId);
    if (user == null || user.id == 0) return false;
    user.role = role;
    return true;
  }

  bool deleteUser(int userId, UserAccount? admin) {
    if (!isAdminRole(admin)) return false;
    final user = getUserById(userId);
    if (user == null || user.id == 0) return false;
    _users.removeWhere((u) => u.id == userId);
    _tokens.removeWhere((_, t) => t.userId == userId);
    _saveUsers();
    _saveTokens();
    return true;
  }

  Map<String, dynamic> getProfile(UserAccount user) {
    return user.toSafeJson();
  }

  Map<String, dynamic> updateProfile(UserAccount user,
      {String? username, String? email, String? firstName, String? lastName}) {
    if (username != null) {
      final nameExists =
          _users.any((u) => u.username == username && u.id != user.id);
      if (nameExists) return {'error': 'Username already taken'};
      user.username = username;
    }
    if (email != null) {
      final emailExists =
          _users.any((u) => u.email == email && u.id != user.id);
      if (emailExists) return {'error': 'Email already in use'};
      user.email = email;
    }
    if (firstName != null) user.firstName = firstName;
    if (lastName != null) user.lastName = lastName;
    _saveUsers();
    return user.toSafeJson();
  }

  Map<String, dynamic> changePassword(
      UserAccount user, String oldPassword, String newPassword) {
    if (!_verifyPassword(oldPassword, user.passwordHash)) {
      return {'error': 'Current password is incorrect'};
    }
    if (newPassword.length < 6) {
      return {'error': 'New password must be at least 6 characters'};
    }
    user.passwordHash = _hashPassword(newPassword);
    _saveUsers();
    return {'success': true, 'message': 'Password updated'};
  }

  Map<String, dynamic> linkSteamAccount(UserAccount user, int steamAccountId) {
    final alreadyLinked =
        _users.any((u) => u.steamAccountId == steamAccountId && u.id != user.id);
    if (alreadyLinked) {
      return {'error': 'This Steam account is already linked to another user'};
    }
    user.steamAccountId = steamAccountId;
    _saveUsers();
    return {'success': true, 'steamAccountId': steamAccountId};
  }

  Map<String, dynamic> unlinkSteamAccount(UserAccount user) {
    user.steamAccountId = null;
    _saveUsers();
    return {'success': true};
  }

  Map<String, dynamic>? getPublicProfile(int userId) {
    final user = getUserById(userId);
    if (user == null || user.id == 0) return null;
    return {
      'id': user.id,
      'username': user.username,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'steamAccountId': user.steamAccountId,
      'avatarUrl': user.avatarUrl,
      'role': user.role,
      'createdAt': user.createdAt.toIso8601String(),
    };
  }

  bool updateAvatarUrl(int userId, String? avatarUrl) {
    final user = getUserById(userId);
    if (user == null || user.id == 0) return false;
    user.avatarUrl = avatarUrl;
    _saveUsers();
    return true;
  }

  HeroTierOverride? getTierOverride(int heroId) => _tierOverrides[heroId];

  Map<int, HeroTierOverride> getAllTierOverrides() =>
      Map.from(_tierOverrides);

  void setTierOverride(int heroId, String tier, String? setBy) {
    _tierOverrides[heroId] = HeroTierOverride(
      heroId: heroId,
      tier: tier,
      setBy: setBy,
      setAt: DateTime.now(),
    );
    _saveTierOverrides();
  }

  void setTierOverridesBatch(Map<int, String> tiers, String? setBy) {
    final now = DateTime.now();
    for (final entry in tiers.entries) {
      _tierOverrides[entry.key] = HeroTierOverride(
        heroId: entry.key,
        tier: entry.value,
        setBy: setBy,
        setAt: now,
      );
    }
    _saveTierOverrides();
  }

  void removeTierOverride(int heroId) {
    _tierOverrides.remove(heroId);
    _saveTierOverrides();
  }

  void _loadTierOverrides() {
    try {
      final file = File(_tierOverridesFile);
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync());
      if (data is Map) {
        for (final entry in data.entries) {
          final id = int.tryParse(entry.key.toString());
          if (id == null) continue;
          final d = entry.value as Map<String, dynamic>;
          _tierOverrides[id] = HeroTierOverride(
            heroId: id,
            tier: d['tier'] ?? 'C',
            setBy: d['setBy'],
            setAt: d['setAt'] != null
                ? DateTime.tryParse(d['setAt']) ?? DateTime.now()
                : DateTime.now(),
          );
        }
        stdout.writeln('Loaded ${_tierOverrides.length} tier overrides from disk');
      }
    } catch (e) {
      stdout.writeln('Failed to load tier overrides: $e');
    }
  }

  void _saveTierOverrides() {
    try {
      final dir = Directory('/opt/pauselock/data');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final data = <String, dynamic>{};
      for (final entry in _tierOverrides.entries) {
        data['${entry.key}'] = {
          'heroId': entry.key,
          'tier': entry.value.tier,
          'setBy': entry.value.setBy,
          'setAt': entry.value.setAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };
      }
      File(_tierOverridesFile)
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      stdout.writeln('Failed to save tier overrides: $e');
    }
  }

  void _loadUsers() {
    try {
      final file = File(_usersFile);
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync());
      if (data is List) {
        for (final u in data) {
          final user = UserAccount(
            id: u['id'] ?? 0,
            email: u['email'] ?? '',
            username: u['username'] ?? '',
            passwordHash: u['passwordHash'] ?? '',
            role: u['role'] ?? 'user',
            firstName: u['firstName'] ?? '',
            lastName: u['lastName'] ?? '',
            steamAccountId: u['steamAccountId'],
            avatarUrl: u['avatarUrl'],
          );
          user.isActive = u['isActive'] ?? true;
          user.lastLogin = u['lastLogin'] != null
              ? DateTime.tryParse(u['lastLogin']) ?? DateTime.now()
              : DateTime.now();
          _users.add(user);
          if (user.id >= _nextUserId) _nextUserId = user.id + 1;
        }
        stdout.writeln('Loaded ${_users.length} users from disk');
      }
    } catch (e) {
      stdout.writeln('Failed to load users: $e');
    }
  }

  void _saveUsers() {
    try {
      final dir = Directory('/opt/pauselock/data');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final data = _users.map((u) => {
        'id': u.id,
        'email': u.email,
        'username': u.username,
        'passwordHash': u.passwordHash,
        'role': u.role,
        'firstName': u.firstName,
        'lastName': u.lastName,
        'steamAccountId': u.steamAccountId,
        'avatarUrl': u.avatarUrl,
        'isActive': u.isActive,
        'lastLogin': u.lastLogin.toIso8601String(),
      }).toList();
      File(_usersFile)
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      stdout.writeln('Failed to save users: $e');
    }
  }

  void _loadTokens() {
    try {
      final file = File(_tokensFile);
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync());
      if (data is List) {
        for (final t in data) {
          final expiresAt = t['expiresAt'] != null
              ? DateTime.tryParse(t['expiresAt'])
              : null;
          if (expiresAt == null || expiresAt.isBefore(DateTime.now())) continue;
          final token = AuthToken(
            token: t['token'] ?? '',
            userId: t['userId'] ?? 0,
            role: t['role'] ?? 'user',
          );
          _tokens[token.token] = token;
        }
        stdout.writeln('Loaded ${_tokens.length} valid tokens from disk');
      }
    } catch (e) {
      stdout.writeln('Failed to load tokens: $e');
    }
  }

  void _saveTokens() {
    try {
      final dir = Directory('/opt/pauselock/data');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final data = _tokens.entries
          .where((e) => !e.value.isExpired)
          .map((e) => {
        'token': e.key,
        'userId': e.value.userId,
        'role': e.value.role,
        'expiresAt': e.value.expiresAt.toIso8601String(),
      }).toList();
      File(_tokensFile)
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      stdout.writeln('Failed to save tokens: $e');
    }
  }

  List<Map<String, dynamic>> getAnnouncements() {
    return _announcements.where((a) => a['enabled'] == true).toList();
  }

  List<Map<String, dynamic>> getAllAnnouncements() {
    return List.from(_announcements);
  }

  Map<String, dynamic>? getAnnouncement(int id) {
    try {
      return _announcements.firstWhere((a) => a['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> createAnnouncement(
      String message, String? type, String createdBy) {
    final id = _announcements.isEmpty
        ? 1
        : (_announcements.map((a) => a['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final announcement = {
      'id': id,
      'message': message,
      'type': type ?? 'info',
      'enabled': true,
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': createdBy,
    };
    _announcements.add(announcement);
    _saveAnnouncements();
    return announcement;
  }

  Map<String, dynamic>? updateAnnouncement(
      int id, {String? message, String? type, bool? enabled}) {
    final idx = _announcements.indexWhere((a) => a['id'] == id);
    if (idx == -1) return null;
    if (message != null) _announcements[idx]['message'] = message;
    if (type != null) _announcements[idx]['type'] = type;
    if (enabled != null) _announcements[idx]['enabled'] = enabled;
    _announcements[idx]['updatedAt'] = DateTime.now().toIso8601String();
    _saveAnnouncements();
    return _announcements[idx];
  }

  bool deleteAnnouncement(int id) {
    _announcements.removeWhere((a) => a['id'] == id);
    _saveAnnouncements();
    return true;
  }

  void _loadAnnouncements() {
    try {
      final file = File(_announcementsFile);
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync());
      if (data is List) {
        for (final a in data) {
          _announcements.add(Map<String, dynamic>.from(a));
        }
        stdout.writeln('Loaded ${_announcements.length} announcements from disk');
      }
    } catch (e) {
      stdout.writeln('Failed to load announcements: $e');
    }
  }

  void _saveAnnouncements() {
    try {
      final dir = Directory('/opt/pauselock/data');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      File(_announcementsFile)
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_announcements));
    } catch (e) {
      stdout.writeln('Failed to save announcements: $e');
    }
  }
}
