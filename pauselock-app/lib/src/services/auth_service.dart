import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pauselock_app/src/services/local_storage_service.dart';

class AuthService {
  static Map<String, dynamic>? _currentUser;
  static String? _token;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static String? get token => _token;
  static bool get isLoggedIn => _token != null && _currentUser != null;
  static bool get isAdmin =>
      _currentUser?['role'] == 'admin' || _currentUser?['role'] == 'moderator';
  static bool get isAdminRole => _currentUser?['role'] == 'admin';

  static void initialize() {
    _token = LocalStorageService.getAuthToken();
    _currentUser = LocalStorageService.getAuthUser();
  }

  static Future<Map<String, dynamic>> register(
      String email, String username, String password) async {
    final result = await _postJson('/auth/register', {
      'email': email,
      'username': username,
      'password': password,
    });
    if (result is Map && result['token'] != null) {
      _token = result['token']['token'];
      _currentUser = Map<String, dynamic>.from(result['user'] as Map);
      LocalStorageService.saveAuthToken(_token!);
      LocalStorageService.saveAuthUser(_currentUser!);
    }
    return result is Map ? Map<String, dynamic>.from(result) : {'error': 'Registration failed'};
  }

  static Future<Map<String, dynamic>> login(
      String emailOrUsername, String password) async {
    final result = await _postJson('/auth/login', {
      'emailOrUsername': emailOrUsername,
      'password': password,
    });
    if (result is Map && result['token'] != null) {
      _token = result['token']['token'];
      _currentUser = Map<String, dynamic>.from(result['user'] as Map);
      LocalStorageService.saveAuthToken(_token!);
      LocalStorageService.saveAuthUser(_currentUser!);
    }
    return result is Map ? Map<String, dynamic>.from(result) : {'error': 'Login failed'};
  }

  static Future<void> logout() async {
    try {
      await _postJson('/auth/logout', {});
    } catch (_) {}
    _token = null;
    _currentUser = null;
    LocalStorageService.clearAuth();
  }

  static Future<Map<String, dynamic>?> refreshProfile() async {
    if (_token == null) return null;
    try {
      final result = await _getJson('/auth/me');
      if (result is Map && result['error'] == null) {
        _currentUser = Map<String, dynamic>.from(result);
        LocalStorageService.saveAuthUser(_currentUser!);
        return _currentUser;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> updateProfile(
      {String? username, String? email}) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    return await _postJson('/auth/update-profile', body);
  }

  static Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    return await _postJson('/auth/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  static Future<List<dynamic>> getUsers() async {
    final result = await _getJson('/admin/users');
    if (result is List) return result;
    return <dynamic>[];
  }

  static Future<Map<String, dynamic>> updateUserRole(
      int userId, String role) async {
    return await _postJson('/admin/update-role', {
      'userId': userId,
      'role': role,
    });
  }

  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    return await _postJson('/admin/delete-user', {
      'userId': userId,
    });
  }

  static Future<Map<String, dynamic>> getTierOverrides() async {
    final result = await _getJson('/admin/tier-overrides');
    if (result is Map) return Map<String, dynamic>.from(result);
    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> setTierOverride(
      int heroId, String tier) async {
    return await _postJson('/admin/set-tier', {
      'heroId': heroId,
      'tier': tier,
    });
  }

  static Future<Map<String, dynamic>> removeTierOverride(int heroId) async {
    return await _postJson('/admin/remove-tier', {
      'heroId': heroId,
    });
  }

  static Future<Map<String, dynamic>> saveAllTiers(
      Map<int, String> tierMap) async {
    final tiersJson = tierMap.map((k, v) => MapEntry('$k', v));
    return await _postJson('/admin/save-tiers', {
      'tiers': tiersJson,
    });
  }

  static Future<dynamic> _getJson(String path) async {
    try {
      final uri = _buildUri(path);
      final headers = <String, String>{
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {'error': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<dynamic> _postJson(
      String path, Map<String, dynamic> body) async {
    try {
      final uri = _buildUri(path);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };
      final response =
          await http.post(uri, headers: headers, body: jsonEncode(body));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {'error': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Uri _buildUri(String path) {
    final base = Uri.base;
    String baseApi;
    if (base.host == 'localhost') {
      baseApi = 'http://localhost:8080';
    } else {
      baseApi = '${base.origin}/api';
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseApi/$cleanPath');
  }
}
