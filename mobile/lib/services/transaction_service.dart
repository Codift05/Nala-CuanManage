import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class TransactionService {
  static String get baseUrl => ApiConfig.baseUrl;

  final _api = ApiClient();

  Future<List<TransactionItem>> getTransactions({int? limit}) async {
    try {
      final transactions = <TransactionItem>[];
      String? cursor;
      do {
        final uri =
            Uri.parse('$baseUrl/transactions').replace(queryParameters: {
          'limit': '${limit ?? 100}',
          if (cursor != null) 'cursor': cursor,
        });
        final response = await _api.get(uri);
        if (response.statusCode != 200) {
          throw Exception('Failed to load transactions');
        }

        final page = parseTransactionPage(jsonDecode(response.body));
        transactions.addAll(page.items);
        cursor = limit == null ? page.nextCursor : null;
      } while (cursor != null);
      return transactions;
    } catch (e) {
      debugPrint('Get transactions error: $e');
      rethrow;
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
      final response = await _api.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {
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
      final response = await _api.post(
        Uri.parse('$baseUrl/transactions/scan'),
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
      final response = await _api.put(
        Uri.parse('$baseUrl/transactions/$id'),
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

({List<TransactionItem> items, String? nextCursor}) parseTransactionPage(
  dynamic value,
) {
  final body = value as Map<String, dynamic>;
  final data = body['data'] as List<dynamic>;
  final pagination = body['pagination'] as Map<String, dynamic>;
  return (
    items: data
        .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    nextCursor: pagination['nextCursor'] as String?,
  );
}

String createIdempotencyKey() {
  final random = Random.secure();
  return 'nala-${DateTime.now().microsecondsSinceEpoch}-'
      '${random.nextInt(0x7fffffff).toRadixString(16)}';
}
