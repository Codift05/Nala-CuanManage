import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class TransactionService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<TransactionItem>> getTransactions({int? limit}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      String url = '$baseUrl/transactions';
      if (limit != null) {
        url += '?limit=$limit';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Get transactions error: $e');
      return [];
    }
  }

  Future<TransactionItem?> createTransaction({
    required String walletId,
    required String type,
    required double amount,
    String? categoryId,
    String? merchant,
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'walletId': walletId,
          'type': type,
          'amount': amount,
          if (categoryId != null) 'categoryId': categoryId,
          if (merchant != null) 'merchant': merchant,
          if (notes != null) 'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TransactionItem.fromJson(data['transaction']);
      }
      return null;
    } catch (e) {
      print('Create transaction error: $e');
      return null;
    }
  }
}
