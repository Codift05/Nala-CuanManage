import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/recurring_bill.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class RecurringService {
  static String get baseUrl => ApiConfig.baseUrl;

  final _api = ApiClient();

  Future<List<RecurringBill>> getRecurringBills() async {
    try {
      final response = await _api.get(Uri.parse('$baseUrl/recurring'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RecurringBill.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recurring bills');
      }
    } catch (e) {
      debugPrint('Get recurring bills error: $e');
      rethrow;
    }
  }

  Future<RecurringBill?> createRecurringBill({
    required String title,
    required int amount,
    required String categoryId,
    required String walletId,
    required int dueDate,
  }) async {
    try {
      final response = await _api.post(
        Uri.parse('$baseUrl/recurring'),
        body: jsonEncode({
          'title': title,
          'amount': amount,
          'categoryId': categoryId,
          'walletId': walletId,
          'dueDate': dueDate,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RecurringBill.fromJson(data['bill']);
      }
      return null;
    } catch (e) {
      debugPrint('Create recurring bill error: $e');
      return null;
    }
  }

  Future<bool> deleteRecurringBill(String id) async {
    try {
      final response = await _api.delete(
        Uri.parse('$baseUrl/recurring/$id'),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete recurring bill error: $e');
      return false;
    }
  }
}
