import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

class TransactionService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    return TokenStorage.read();
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
      debugPrint('Get transactions error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createTransaction({
    required String walletId,
    required String type,
    required int amount,
    String? categoryId,
    String? merchant,
    String? notes,
    String? idempotencyKey,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Idempotency-Key': idempotencyKey ?? createIdempotencyKey(),
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'transaction': TransactionItem.fromJson(data['transaction']),
          'warning': data['warning'],
          'replayed': data['replayed'] == true,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Create transaction error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> scanReceipt(String base64Image) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/transactions/scan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'imageBase64': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Scan receipt error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Scan receipt exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateTransaction({
    required String id,
    required String walletId,
    required String type,
    required int amount,
    String? categoryId,
    String? merchant,
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$id'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'transaction': TransactionItem.fromJson(data['transaction']),
          'warning': data['warning'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Update transaction error: $e');
      return null;
    }
  }
}

String createIdempotencyKey() {
  final random = Random.secure();
  return 'nala-${DateTime.now().microsecondsSinceEpoch}-'
      '${random.nextInt(0x7fffffff).toRadixString(16)}';
}
