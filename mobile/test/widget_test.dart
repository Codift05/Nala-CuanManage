import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nala/main.dart';
import 'package:nala/screens/add_transaction_screen.dart';
import 'package:nala/screens/edit_profile_screen.dart';
import 'package:nala/screens/login_screen.dart';
import 'package:nala/screens/onboarding_screen.dart';
import 'package:nala/services/token_storage.dart';
import 'package:nala/services/chat_service.dart';
import 'package:nala/services/transaction_service.dart';
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

  test('Legacy auth token migrates to secure storage', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'auth_token': 'legacy-token'});

    expect(await TokenStorage.read(), 'legacy-token');
    expect(
      (await SharedPreferences.getInstance()).containsKey('auth_token'),
      isFalse,
    );
    expect(await TokenStorage.read(), 'legacy-token');
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

  test('Transaction idempotency keys are unique and API-safe', () {
    final first = createIdempotencyKey();
    final second = createIdempotencyKey();

    expect(first, isNot(second));
    expect(first.length, inInclusiveRange(16, 128));
    expect(RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(first), isTrue);
  });

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NalaApp());

    expect(find.text('NALA'), findsOneWidget);
  });

  testWidgets('Welcome screen fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );

    expect(find.text('Halo, selamat datang!'), findsOneWidget);
    expect(find.text('Masuk ke Nala'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login screen fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('Selamat datang kembali.'), findsOneWidget);
    expect(find.text('Gunakan biometrik'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit profile validates name and email before saving',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: EditProfileScreen(
          user: {
            'name': 'Nala User',
            'email': 'user@nala.com',
          },
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'A');
    await tester.enterText(fields.at(1), 'email-tidak-valid');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    expect(find.text('Nama minimal 2 karakter'), findsOneWidget);
    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
