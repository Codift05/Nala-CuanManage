import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_storage.dart';

class SessionExpiredException implements Exception {}

class ApiSession {
  static final expired = ValueNotifier(false);

  static Future<void> markExpired() async {
    await TokenStorage.clear();
    expired.value = true;
  }
}

class ApiClient {
  static Future<String?>? _refreshing;

  Future<http.Response> get(Uri uri) => _send('GET', uri);

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
    Duration timeout = const Duration(seconds: 10),
  }) =>
      _send('POST', uri, headers: headers, body: body, timeout: timeout);

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) =>
      _send('PUT', uri, headers: headers, body: body);

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) =>
      _send('DELETE', uri, headers: headers, body: body);

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    var token = await TokenStorage.read();
    if (token == null) {
      await ApiSession.markExpired();
      throw SessionExpiredException();
    }

    var response = await _sendOnce(
      method,
      uri,
      token,
      headers,
      body,
      timeout,
    );
    if (response.statusCode != 401 && response.statusCode != 403) {
      return response;
    }

    token = await _refreshAccessToken();
    if (token == null) {
      await ApiSession.markExpired();
      throw SessionExpiredException();
    }
    response = await _sendOnce(method, uri, token, headers, body, timeout);
    if (response.statusCode == 401 || response.statusCode == 403) {
      await ApiSession.markExpired();
      throw SessionExpiredException();
    }
    return response;
  }

  Future<http.Response> _sendOnce(
    String method,
    Uri uri,
    String token,
    Map<String, String>? headers,
    String? body,
    Duration timeout,
  ) {
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?headers,
      });
    if (body != null) request.body = body;
    return request.send().then(http.Response.fromStream).timeout(timeout);
  }

  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh() async {
    final refreshToken = await TokenStorage.readRefresh();
    if (refreshToken == null) return null;
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['accessToken'];
    final nextRefreshToken = data['refreshToken'];
    if (accessToken is! String || nextRefreshToken is! String) return null;
    await TokenStorage.writePair(accessToken, nextRefreshToken);
    return accessToken;
  }
}
