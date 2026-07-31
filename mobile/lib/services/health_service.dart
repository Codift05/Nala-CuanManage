import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'api_client.dart';

class HealthService {
  final _api = ApiClient();

  Future<Map<String, dynamic>?> getHealthScore() async {
    try {
      final response = await _api.get(
        Uri.parse('${AuthService.baseUrl}/health/score'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to get health score: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Health API Error: $e');
      return null;
    }
  }
}
