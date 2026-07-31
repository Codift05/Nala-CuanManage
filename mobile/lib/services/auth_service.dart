import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart' show debugPrint;
import '../config/api_config.dart';
import 'token_storage.dart';
import 'api_client.dart';
import 'wallet_service.dart';

class AuthResult {
  const AuthResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class PasswordResetRequestResult extends AuthResult {
  const PasswordResetRequestResult({
    required super.success,
    required super.message,
    this.developmentToken,
  });

  final String? developmentToken;
}

class RegistrationResult extends AuthResult {
  const RegistrationResult({
    required super.success,
    required super.message,
    this.developmentVerificationToken,
  });

  final String? developmentVerificationToken;
}

class CurrentUserResult {
  const CurrentUserResult({
    required this.success,
    required this.message,
    this.user,
    this.sessionExpired = false,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? user;
  final bool sessionExpired;
}

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;
  final _api = ApiClient();

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
        body: jsonEncode({
          'email': email,
          'password': password,
          'deviceName': 'NALA Mobile',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        WalletService.clearCache();
        await TokenStorage.writePair(data['accessToken'], data['refreshToken']);
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

  Future<RegistrationResult> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'deviceName': 'NALA Mobile',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RegistrationResult(
          success: true,
          message: data['message'] as String? ?? 'Akun berhasil dibuat',
          developmentVerificationToken: data['verificationToken'] as String?,
        );
      }

      return RegistrationResult(
        success: false,
        message: _responseMessage(
          response,
          'Pendaftaran gagal. Silakan coba lagi.',
        ),
      );
    } catch (e) {
      debugPrint('Register error: $e');
      return const RegistrationResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }

  Future<AuthResult> verifyEmail(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
      return AuthResult(
        success: response.statusCode == 200,
        message: _responseMessage(response, 'Gagal memverifikasi email.'),
      );
    } catch (e) {
      debugPrint('Verify email error: $e');
      return const AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }

  Future<PasswordResetRequestResult> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PasswordResetRequestResult(
        success: response.statusCode == 200,
        message: data['message'] as String? ?? 'Permintaan reset diproses.',
        developmentToken: data['resetToken'] as String?,
      );
    } catch (e) {
      debugPrint('Request password reset error: $e');
      return const PasswordResetRequestResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }

  Future<AuthResult> resetPassword(String token, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'password': password}),
      );
      return AuthResult(
        success: response.statusCode == 200,
        message: _responseMessage(response, 'Gagal mereset password.'),
      );
    } catch (e) {
      debugPrint('Reset password error: $e');
      return const AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }

  Future<void> logout() async {
    final token = await TokenStorage.read();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Local logout must still succeed when the server is unavailable.
      }
    }
    await TokenStorage.clear();
    WalletService.clearCache();
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await TokenStorage.readRefresh();
    if (refreshToken == null) return null;

    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/refresh'),
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

  Future<bool> isLoggedIn() async {
    try {
      final token = await TokenStorage.read().timeout(
        const Duration(seconds: 3),
      );
      if (token == null || token.isEmpty) return false;

      var response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) return true;

      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshedToken = await _refreshAccessToken();
        if (refreshedToken != null) {
          response = await http.get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {'Authorization': 'Bearer $refreshedToken'},
          ).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) return true;
        }
        await TokenStorage.clear();
      }
      return false;
    } catch (e) {
      debugPrint('Session validation error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final result = await getCurrentUserResult();
    return result.user;
  }

  Future<CurrentUserResult> getCurrentUserResult() async {
    try {
      final response = await _api.get(
        Uri.parse('$baseUrl/auth/me'),
      );

      if (response.statusCode != 200) {
        return CurrentUserResult(
          success: false,
          message: _responseMessage(
            response,
            'Profil belum dapat dimuat. Silakan coba lagi.',
          ),
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = data['user'];
      if (user is! Map<String, dynamic>) {
        return const CurrentUserResult(
          success: false,
          message: 'Data profil dari server tidak valid.',
        );
      }

      return CurrentUserResult(
        success: true,
        message: 'Profil berhasil dimuat',
        user: user,
      );
    } on SessionExpiredException {
      return const CurrentUserResult(
        success: false,
        message: 'Sesi telah berakhir. Silakan masuk kembali.',
        sessionExpired: true,
      );
    } catch (e) {
      debugPrint('Get current user error: $e');
      return const CurrentUserResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }

  Future<AuthResult> updateProfile(
    String name,
    String email, {
    String? avatarBase64,
  }) async {
    try {
      final bodyData = <String, dynamic>{'name': name, 'email': email};
      if (avatarBase64 != null) {
        bodyData['avatar'] = avatarBase64;
      }

      final response = await _api.put(
        Uri.parse('$baseUrl/auth/profile'),
        body: jsonEncode(bodyData),
      );

      return AuthResult(
        success: response.statusCode == 200,
        message: _responseMessage(
          response,
          response.statusCode == 200
              ? 'Profil berhasil diperbarui'
              : 'Gagal memperbarui profil',
        ),
      );
    } catch (e) {
      debugPrint('Update profile error: $e');
      return const AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }

  Future<AuthResult> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await _api.put(
        Uri.parse('$baseUrl/auth/password'),
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      return AuthResult(
        success: response.statusCode == 200,
        message: _responseMessage(
          response,
          response.statusCode == 200
              ? 'Password berhasil diubah'
              : 'Gagal mengubah password',
        ),
      );
    } catch (e) {
      debugPrint('Change password error: $e');
      return const AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }

  Future<AuthResult> deleteAccount(String password) async {
    try {
      final response = await _api.delete(
        Uri.parse('$baseUrl/auth/me'),
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        await logout();
      }
      return AuthResult(
        success: response.statusCode == 200,
        message: _responseMessage(
          response,
          response.statusCode == 200
              ? 'Akun berhasil dihapus'
              : 'Gagal menghapus akun',
        ),
      );
    } catch (e) {
      debugPrint('Delete account error: $e');
      return const AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server NALA.',
      );
    }
  }
}
