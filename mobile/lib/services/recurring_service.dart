import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_bill.dart';

class RecurringService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<RecurringBill>> getRecurringBills() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/recurring'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RecurringBill.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recurring bills');
      }
    } catch (e) {
      print('Get recurring bills error: $e');
      return [];
    }
  }

  Future<RecurringBill?> createRecurringBill({
    required String title,
    required double amount,
    required String categoryId,
    required String walletId,
    required int dueDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/recurring'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      print('Create recurring bill error: $e');
      return null;
    }
  }

  Future<bool> deleteRecurringBill(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.delete(
        Uri.parse('$baseUrl/recurring/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete recurring bill error: $e');
      return false;
    }
  }
}
