import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallet.dart';

class WalletService {
  // Use 10.0.2.2 for Android emulator to connect to localhost
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
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

  Future<Wallet?> createWallet(String name, String type, double balance) async {
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
