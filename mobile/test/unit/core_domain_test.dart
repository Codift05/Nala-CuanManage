import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nala/main.dart';
import 'package:nala/screens/add_transaction_screen.dart';
import 'package:nala/services/token_storage.dart';
import 'package:nala/services/biometric_service.dart';
import 'package:nala/services/chat_service.dart';
import 'package:nala/services/transaction_service.dart';
import 'package:nala/services/api_client.dart';
import 'package:nala/models/transaction.dart';
import 'package:nala/models/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Rupiah formatter adds Indonesian thousands separators', () {
    final formatter = RupiahInputFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '10000',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );

    expect(result.text, '10.000');
    expect(result.selection.baseOffset, 6);
  });

  test('Add transaction uses the shared horizontal route', () {
    final route = addTransactionRoute<void>();

    expect(route, isA<PageRouteBuilder<void>>());
    expect(route.transitionDuration, const Duration(milliseconds: 360));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 300));
  });

  test('Legacy auth token migrates to secure storage', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'auth_token': 'legacy-token'});

    expect(await TokenStorage.read(), 'legacy-token');
    expect(
      (await SharedPreferences.getInstance()).containsKey('auth_token'),
      isFalse,
    );
    expect(await TokenStorage.read(), 'legacy-token');
    await TokenStorage.clear();
  });

  test('Access and refresh tokens share the secure session lifecycle',
      () async {
    FlutterSecureStorage.setMockInitialValues({});

    await TokenStorage.writePair('access-token', 'refresh-token');
    expect(await TokenStorage.read(), 'access-token');
    expect(await TokenStorage.readRefresh(), 'refresh-token');

    await TokenStorage.clear();
    expect(await TokenStorage.read(), isNull);
    expect(await TokenStorage.readRefresh(), isNull);
  });

  test('Biometric unlock remains opt-in', () async {
    SharedPreferences.setMockInitialValues({});
    final biometrics = BiometricService();

    expect(await biometrics.isEnabled(), isFalse);
    await biometrics.setEnabled(true);
    expect(await biometrics.isEnabled(), isTrue);
    await biometrics.setEnabled(false);
    expect(await biometrics.isEnabled(), isFalse);
  });

  test('Expired sessions are broadcast to the app shell', () async {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'expired'});
    ApiSession.expired.value = false;

    await ApiSession.markExpired();

    expect(ApiSession.expired.value, isTrue);
    expect(await TokenStorage.read(), isNull);
    ApiSession.expired.value = false;
  });
  test('AI transaction draft rejects unsafe payloads', () {
    expect(
      parseTransactionDraft({
        'type': 'EXPENSE',
        'amount': 25000,
        'walletId': 'wallet-1',
        'categoryId': 'Food',
      }),
      isNotNull,
    );
    expect(
      parseTransactionDraft({
        'type': 'EXPENSE',
        'amount': -1,
        'walletId': 'wallet-1',
        'categoryId': 'Food',
      }),
      isNull,
    );
  });

  test('Money models preserve whole rupiah values', () {
    final wallet = Wallet.fromJson({
      'id': 'wallet-1',
      'name': 'Dompet Utama',
      'type': 'CASH',
      'balance': 1000000000000,
    });
    final transaction = TransactionItem.fromJson({
      'id': 'tx-1',
      'walletId': 'wallet-1',
      'type': 'EXPENSE',
      'amount': 25000,
      'date': '2026-07-30T00:00:00.000Z',
    });

    expect(wallet.balance, isA<int>());
    expect(wallet.balance, 1000000000000);
    expect(transaction.amount, 25000);
  });

  test('Transaction page preserves items and next cursor', () {
    final page = parseTransactionPage({
      'data': [
        {
          'id': 'tx-1',
          'walletId': 'wallet-1',
          'type': 'EXPENSE',
          'amount': 1000,
          'date': '2026-07-31T10:00:00.000Z',
        },
      ],
      'pagination': {'nextCursor': 'next-page'},
    });

    expect(page.items.single.id, 'tx-1');
    expect(page.nextCursor, 'next-page');
  });

  test('Transaction idempotency keys are unique and API-safe', () {
    final first = createIdempotencyKey();
    final second = createIdempotencyKey();

    expect(first, isNot(second));
    expect(first.length, inInclusiveRange(16, 128));
    expect(RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(first), isTrue);
  });

  test('Password reset routes accept web and NALA deep links', () {
    expect(
      passwordResetTokenFromRoute('/reset-password?token=web-token'),
      'web-token',
    );
    expect(
      passwordResetTokenFromRoute('nala://reset-password?token=app-token'),
      'app-token',
    );
    expect(passwordResetTokenFromRoute('/reset-password'), isNull);
  });

  test('Email verification routes accept web and NALA deep links', () {
    expect(
      emailVerificationTokenFromRoute('/verify-email?token=web-token'),
      'web-token',
    );
    expect(
      emailVerificationTokenFromRoute('nala://verify-email?token=app-token'),
      'app-token',
    );
    expect(emailVerificationTokenFromRoute('/verify-email'), isNull);
  });
}
