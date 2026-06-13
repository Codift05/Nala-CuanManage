import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class HealthService {
  Future<Map<String, dynamic>?> getHealthScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/health/score'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to get health score: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Health API Error: $e');
      return null;
    }
  }
}
