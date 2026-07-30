import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallet.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

class WalletService {
  // Android development uses `adb reverse tcp:3001 tcp:3001`.
  static String get baseUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    return TokenStorage.read();
  }

  Future<List<Wallet>> getWallets() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/wallets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Wallet.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load wallets');
      }
    } catch (e) {
      print('Get wallets error: $e');
      return [];
    }
  }

  Future<Wallet?> createWallet(String name, String type, int balance) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/wallets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'type': type,
          'balance': balance,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Wallet.fromJson(data['wallet']);
      }
      return null;
    } catch (e) {
      print('Create wallet error: $e');
      return null;
    }
  }
}
