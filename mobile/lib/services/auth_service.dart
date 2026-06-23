import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart' show debugPrint;

class AuthResult {
  const AuthResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class AuthService {
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }
    return 'http://127.0.0.1:3001/api';
  }

  String _responseMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
    } catch (_) {
      // Use a user-friendly fallback when the server does not return JSON.
    }
    return fallback;
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        return const AuthResult(success: true, message: 'Login berhasil');
      }

      return AuthResult(
        success: false,
        message: _responseMessage(response, 'Login gagal. Silakan coba lagi.'),
      );
    } catch (e) {
      debugPrint('Login error: $e');
      return const AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }

  Future<AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        return const AuthResult(success: true, message: 'Akun berhasil dibuat');
      }

      return AuthResult(
        success: false,
        message: _responseMessage(
          response,
          'Pendaftaran gagal. Silakan coba lagi.',
        ),
      );
    } catch (e) {
      debugPrint('Register error: $e');
      return const AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) return true;

      if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 404) {
        await prefs.remove('auth_token');
      }
      return false;
    } catch (e) {
      debugPrint('Session validation error: $e');
      return false;
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['user'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  Future<bool> updateProfile(String name, String email, {String? avatarBase64}) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final bodyData = <String, dynamic>{'name': name, 'email': email};
      if (avatarBase64 != null) {
        bodyData['avatar'] = avatarBase64;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyData),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/auth/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await logout();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }
}
