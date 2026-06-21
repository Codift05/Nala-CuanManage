import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:3001/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': 'admin@nala.com', 'password': 'password123'}),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
