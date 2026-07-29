import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'token_storage.dart';

class ChatService {
  Future<String?> sendMessage(String message) async {
    try {
      final token = await TokenStorage.read();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'];
      } else {
        print('Failed to send chat: ${response.statusCode} - ${response.body}');
        return 'Maaf, Nala sedang mengalami gangguan teknis 😔 (Status: ${response.statusCode})';
      }
    } catch (e) {
      print('Chat API Error: $e');
      return 'Maaf, koneksi Nala terputus. Coba lagi nanti ya!';
    }
  }
}
