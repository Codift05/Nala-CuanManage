import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class BudgetService {
  static String get baseUrl => ApiConfig.baseUrl;

  final _api = ApiClient();

  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    try {
      String url = '$baseUrl/budgets';
      List<String> queryParams = [];
      if (month != null) queryParams.add('month=$month');
      if (year != null) queryParams.add('year=$year');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _api.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Budget.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load budgets');
      }
    } catch (e) {
      debugPrint('Get budgets error: $e');
      rethrow;
    }
  }

  Future<Budget?> createBudget({
    required String categoryId,
    required int amount,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _api.post(
        Uri.parse('$baseUrl/budgets'),
        body: jsonEncode({
          'categoryId': categoryId,
          'amount': amount,
          'month': month,
          'year': year,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Budget.fromJson(data['budget']);
      }
      return null;
    } catch (e) {
      debugPrint('Create budget error: $e');
      return null;
    }
  }
}
