import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pauselock_server/src/generated/protocol.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final List<UserAccount> _users = [];
  final Map<String, AuthToken> _tokens = {};
  final Map<int, HeroTierOverride> _tierOverrides = {};
  int _nextUserId = 1;

  void initialize() {
    _seedAdminUser();
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
      {String role = 'user'}) {
    final exists = _users.any((u) => u.email == email || u.username == username);
    if (exists) return null;
    final user = UserAccount(
      id: _nextUserId++,
      email: email,
      username: username,
      passwordHash: passwordHash,
      role: role,
    );
    _users.add(user);
    return user;
  }

  Map<String, dynamic> register(String email, String username, String password) {
    if (email.trim().isEmpty || username.trim().isEmpty || password.isEmpty) {
      return {'error': 'All fields are required'};
    }
    if (password.length < 6) {
      return {'error': 'Password must be at least 6 characters'};
    }
    if (!email.contains('@')) {
      return {'error': 'Invalid email address'};
    }
    final user = _createUser(email, username, _hashPassword(password));
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
    return true;
  }

  Map<String, dynamic> getProfile(UserAccount user) {
    return user.toSafeJson();
  }

  Map<String, dynamic> updateProfile(
      UserAccount user, {String? username, String? email}) {
    if (username != null) user.username = username;
    if (email != null) user.email = email;
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
    return {'success': true, 'message': 'Password updated'};
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
  }

  void removeTierOverride(int heroId) {
    _tierOverrides.remove(heroId);
  }
}
