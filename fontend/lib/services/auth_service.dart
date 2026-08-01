import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'local_db_service.dart';

/// Owns the current session's JWT + user info.
///
/// CRITICAL for the "each user sees only their own data" requirement:
///  - `token` is held only in memory + secure storage, never cached globally.
///  - `logout()` wipes secure storage completely before any new signup/login,
///    so switching accounts on the same device can never leak the previous
///    user's cached token into a new session.
///  - Every ApiService call reads `authService.token` fresh, so as soon as
///    a different user logs in, all subsequent requests use their token and
///    the backend (`userId: req.user.id`) returns only their records.
class AuthService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';

  String? _token;
  String? _email;
  bool _initialized = false;

  String? get token => _token;
  String? get email => _email;
  bool get isLoggedIn => _token != null;
  bool get initialized => _initialized;

  Future<void> loadSession() async {
    _token = await _storage.read(key: _tokenKey);
    _email = await _storage.read(key: _emailKey);
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveSession(String token, String email) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
    _token = token;
    _email = email;
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 201) {
      throw ApiException(body['error'] ?? 'Signup failed', res.statusCode);
    }
    await _saveSession(body['token'], email);
  }

  Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw ApiException(body['error'] ?? body['message'] ?? 'Login failed',
          res.statusCode);
    }
    await _saveSession(body['token'], email);
  }

  /// Fully wipes this device's stored session AND locally cached/offline
  /// data so the next signup/login starts a clean slate — no previous
  /// user's token, cached records, or queued offline edits can bleed
  /// into the next session.
  Future<void> logout() async {
    await _storage.deleteAll();
    await LocalDbService.instance.clearAll();
    _token = null;
    _email = null;
    notifyListeners();
  }
}
