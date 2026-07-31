import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class WalletService {
  // Android development uses `adb reverse tcp:3001 tcp:3001`.
  static String get baseUrl => ApiConfig.baseUrl;

  final _api = ApiClient();

  Future<List<Wallet>> getWallets() async {
    try {
      final response = await _api.get(Uri.parse('$baseUrl/wallets'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Wallet.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load wallets');
      }
    } catch (e) {
      debugPrint('Get wallets error: $e');
      rethrow;
    }
  }

  Future<Wallet?> createWallet(String name, String type, int balance) async {
    try {
      final response = await _api.post(
        Uri.parse('$baseUrl/wallets'),
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
      debugPrint('Create wallet error: $e');
      return null;
    }
  }
}
