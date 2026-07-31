import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'api_client.dart';

class ChatReply {
  final String message;
  final Map<String, dynamic>? transactionDraft;

  const ChatReply({required this.message, this.transactionDraft});
}

Map<String, dynamic>? parseTransactionDraft(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final type = value['type'];
  final amount = value['amount'];
  if ((type != 'INCOME' && type != 'EXPENSE') ||
      amount is! int ||
      amount <= 0 ||
      value['walletId'] is! String ||
      value['categoryId'] is! String) {
    return null;
  }
  return value;
}

class ChatService {
  final _api = ApiClient();

  Future<ChatReply?> sendMessage(String message) async {
    try {
      final response = await _api.post(
        Uri.parse('${AuthService.baseUrl}/chat'),
        body: jsonEncode({'message': message}),
        timeout: const Duration(seconds: 12),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final draft = data['transactionDraft'];
        return ChatReply(
          message: data['reply'] as String? ?? 'Aku belum punya jawaban.',
          transactionDraft: parseTransactionDraft(draft),
        );
      } else {
        debugPrint(
          'Failed to send chat: ${response.statusCode} - ${response.body}',
        );
        return ChatReply(
          message:
              'Maaf, Nala sedang mengalami gangguan teknis 😔 (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Chat API Error: $e');
      return const ChatReply(
        message: 'Maaf, koneksi Nala terputus. Coba lagi nanti ya!',
      );
    }
  }
}
