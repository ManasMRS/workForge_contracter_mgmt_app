import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiConfig {
  // Android Emulator:
  static const String baseUrl = 'http://10.0.2.2:1000';

  // For iOS Simulator:
  // static const String baseUrl = 'http://127.0.0.1:1000';

  // For physical device:
  // static const String baseUrl = 'http://YOUR_MAC_IP:1000';

  // For deployed backend:
  // static const String baseUrl =
  //     'https://workforge-contracter-mgmt-app.onrender.com';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(
    this.message, [
    this.statusCode,
  ]);

  @override
  String toString() {
    return message;
  }
}

class ApiService {
  final AuthService authService;

  ApiService(this.authService);

  Uri _u(String path) {
    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  Future<Map<String, String>> _headers({
    bool json = true,
  }) async {
    final headers = <String, String>{};

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    headers['Accept'] = 'application/json';

    final token = authService.token;

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    String message =
        'Request failed (${response.statusCode})';

    try {
      final body = jsonDecode(response.body);

      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      } else if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        message = response.body;
      }
    }

    throw ApiException(
      message,
      response.statusCode,
    );
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(
      _u(path),
      headers: await _headers(),
    );

    return _decode(response);
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      _u(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  Future<dynamic> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      _u(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      _u(path),
      headers: await _headers(),
    );

    return _decode(response);
  }
}