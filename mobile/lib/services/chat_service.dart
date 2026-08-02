import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'api_client.dart';

class ChatReply {
  final String message;
  final Map<String, dynamic>? transactionDraft;
  final bool fallback;

  const ChatReply({
    required this.message,
    this.transactionDraft,
    this.fallback = false,
  });
}

Map<String, dynamic>? parseTransactionDraft(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final type = value['type'];
  final amount = value['amount'];
  final walletId = value['walletId'];
  final categoryId = value['categoryId'];
  const categories = {
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
    'Income',
    'Salary',
    'Others',
  };
  if ((type != 'INCOME' && type != 'EXPENSE') ||
      amount is! int ||
      amount <= 0 ||
      amount > 1000000000000 ||
      walletId is! String ||
      walletId.isEmpty ||
      categoryId is! String ||
      !categories.contains(categoryId)) {
    return null;
  }
  final merchant = value['merchant'];
  final notes = value['notes'];
  return {
    'type': type,
    'amount': amount,
    'walletId': walletId,
    'categoryId': categoryId,
    if (merchant is String && merchant.trim().isNotEmpty)
      'merchant': merchant.trim(),
    if (notes is String && notes.trim().isNotEmpty) 'notes': notes.trim(),
  };
}

ChatReply? parseChatReply(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final reply = value['reply'];
  final fallback = value['fallback'];
  if (reply is! String || reply.trim().isEmpty || fallback is! bool) {
    return null;
  }
  return ChatReply(
    message: reply.trim(),
    transactionDraft: parseTransactionDraft(value['transactionDraft']),
    fallback: fallback,
  );
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
        return parseChatReply(jsonDecode(response.body)) ??
            const ChatReply(
              message: 'Respons Nala belum dapat diproses. Coba lagi nanti.',
              fallback: true,
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
