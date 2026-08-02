import 'package:flutter_test/flutter_test.dart';
import 'package:nala/services/chat_service.dart';

void main() {
  test('AI Coach accepts the documented success and fallback envelopes', () {
    final success = parseChatReply({
      'reply': 'Periksa draft berikut.',
      'fallback': false,
      'transactionDraft': {
        'type': 'EXPENSE',
        'amount': 25000,
        'walletId': 'wallet-1',
        'categoryId': 'Food',
        'merchant': ' Kantin ',
        'unexpected': 'must not cross the boundary',
      },
    });
    final fallback = parseChatReply({
      'reply': 'Layanan AI sedang tidak tersedia.',
      'fallback': true,
      'transactionDraft': null,
    });

    expect(success?.message, 'Periksa draft berikut.');
    expect(success?.fallback, isFalse);
    expect(success?.transactionDraft, {
      'type': 'EXPENSE',
      'amount': 25000,
      'walletId': 'wallet-1',
      'categoryId': 'Food',
      'merchant': 'Kantin',
    });
    expect(fallback?.fallback, isTrue);
    expect(fallback?.transactionDraft, isNull);
  });

  test('AI Coach rejects malformed envelopes and unsafe drafts', () {
    expect(parseChatReply({'reply': '', 'fallback': false}), isNull);
    expect(parseChatReply({'reply': 'Halo', 'fallback': 'false'}), isNull);

    final response = parseChatReply({
      'reply': 'Draft tidak aman dibuang.',
      'fallback': false,
      'transactionDraft': {
        'type': 'EXPENSE',
        'amount': 25000,
        'walletId': 'wallet-1',
        'categoryId': 'SYSTEM_OVERRIDE',
      },
    });
    expect(response, isNotNull);
    expect(response?.transactionDraft, isNull);
  });
}
