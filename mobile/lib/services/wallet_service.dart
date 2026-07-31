import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class WalletService {
  // Android development uses `adb reverse tcp:3001 tcp:3001`.
  static String get baseUrl => ApiConfig.baseUrl;

  final _api = ApiClient();
  static List<Wallet>? _cache;
  static Future<List<Wallet>>? _loading;
  static int _generation = 0;

  List<Wallet>? get cachedWallets => _cache;

  static void clearCache() {
    _cache = null;
    _loading = null;
    _generation++;
  }

  Future<List<Wallet>> getWallets({bool refresh = false}) async {
    final cached = _cache;
    if (!refresh && cached != null) return cached;
    if (_loading case final request?) return request;

    final generation = _generation;
    final request = _fetchWallets(generation);
    _loading = request;
    try {
      return await request;
    } catch (e) {
      debugPrint('Get wallets error: $e');
      rethrow;
    } finally {
      if (identical(_loading, request)) _loading = null;
    }
  }

  Future<List<Wallet>> _fetchWallets(int generation) async {
    final response = await _api.get(Uri.parse('$baseUrl/wallets'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load wallets');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    final wallets = List<Wallet>.unmodifiable(
      data.map((json) => Wallet.fromJson(json)),
    );
    if (generation == _generation) _cache = wallets;
    return wallets;
  }

  Future<Wallet?> createWallet(String name, String type, int balance) async {
    final generation = _generation;
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
        final wallet = Wallet.fromJson(data['wallet']);
        if (generation == _generation) {
          _cache = List<Wallet>.unmodifiable([...?_cache, wallet]);
        }
        return wallet;
      }
      return null;
    } catch (e) {
      debugPrint('Create wallet error: $e');
      return null;
    }
  }
}
