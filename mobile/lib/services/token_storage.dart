import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class TokenStorage {
  static const _key = 'auth_token';
  static const _secure = FlutterSecureStorage();

  static Future<String?> read() async {
    final token = await _secure.read(key: _key);
    if (token != null) return token;

    final preferences = await SharedPreferences.getInstance();
    final legacyToken = preferences.getString(_key);
    if (legacyToken != null) {
      await _secure.write(key: _key, value: legacyToken);
      await preferences.remove(_key);
    }
    return legacyToken;
  }

  static Future<void> write(String token) async {
    await _secure.write(key: _key, value: token);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }

  static Future<void> clear() async {
    await _secure.delete(key: _key);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
