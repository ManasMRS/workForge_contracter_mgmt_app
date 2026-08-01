import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Change this to your deployed backend URL.
/// Use 10.0.2.2 instead of localhost when running on the Android emulator.
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:1000';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

/// Thin wrapper around http that automatically:
///  - prefixes ApiConfig.baseUrl
///  - attaches `Authorization: Bearer <token>` for the CURRENTLY signed-in user
///  - decodes JSON / surfaces backend error messages
///
/// Because the token always belongs to whoever is currently logged in
/// (AuthService clears it fully on logout), every list/detail call the
/// app makes is automatically scoped to that user's own data by the
/// backend (`userId: req.user.id` in every controller).
class ApiService {
  final AuthService authService;
  ApiService(this.authService);

  Uri _u(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = authService.token;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) message = body['error'];
    } catch (_) {}
    throw ApiException(message, res.statusCode);
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(_u(path), headers: await _headers());
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_u(path),
        headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(_u(path),
        headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_u(path), headers: await _headers());
    return _decode(res);
  }
}
