import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../config/api_config.dart';

class BudgetService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      String url = '$baseUrl/budgets';
      List<String> queryParams = [];
      if (month != null) queryParams.add('month=$month');
      if (year != null) queryParams.add('year=$year');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
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
        return data.map((json) => Budget.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load budgets');
      }
    } catch (e) {
      print('Get budgets error: $e');
      return [];
    }
  }

  Future<Budget?> createBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/budgets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      print('Create budget error: $e');
      return null;
    }
  }
}
