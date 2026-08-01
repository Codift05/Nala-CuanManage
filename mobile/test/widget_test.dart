import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nala/main.dart';
import 'package:nala/screens/add_transaction_screen.dart';
import 'package:nala/screens/edit_profile_screen.dart';
import 'package:nala/screens/login_screen.dart';
import 'package:nala/screens/reset_password_screen.dart';
import 'package:nala/screens/onboarding_screen.dart';
import 'package:nala/screens/register_screen.dart';
import 'package:nala/services/token_storage.dart';
import 'package:nala/services/biometric_service.dart';
import 'package:nala/services/chat_service.dart';
import 'package:nala/services/transaction_service.dart';
import 'package:nala/services/api_client.dart';
import 'package:nala/widgets/load_error_view.dart';
import 'package:nala/widgets/main_shell.dart';
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

  testWidgets('Load error offers a working retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: LoadErrorView(onRetry: () => retried = true),
    ));

    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
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

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NalaApp());

    expect(find.text('NALA · DANA KELOLA'), findsOneWidget);
  });

  testWidgets('Welcome screen fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );

    expect(
        find.text('Uang lebih tertata,\nhidup terasa ringan.'), findsOneWidget);
    expect(find.text('Masuk ke NALA'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).resizeToAvoidBottomInset,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Welcome opens Login and Register as bottom sheets',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );
    final headline = find.text('Uang lebih tertata,\nhidup terasa ringan.');
    final headlineSize = tester.widget<Text>(headline).style?.fontSize;

    await tester.tap(find.text('Masuk ke NALA'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Gunakan akun yang sudah terdaftar.'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(390, 540));
    await tester.pump();
    expect(tester.widget<Text>(headline).style?.fontSize, headlineSize);

    Navigator.pop(tester.element(find.byType(BottomSheet)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.binding.setSurfaceSize(const Size(390, 620));
    await tester.pump();
    expect(tester.widget<Text>(headline).style?.fontSize, headlineSize);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pump();
    await tester.tap(find.text('Daftar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Buat akun NALA'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Register screen fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: RegisterScreen()),
    );

    expect(find.text('Buat akun'), findsWidgets);
    expect(find.text('Sudah punya akun?'), findsOneWidget);
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

  testWidgets('Reset password screen fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: ResetPasswordScreen(token: 'test-token')),
    );

    expect(find.text('Buat password baru'), findsOneWidget);
    expect(find.text('Simpan password baru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back from a secondary main tab returns to Beranda',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pump(const Duration(seconds: 9));

    tester
        .widget<GestureDetector>(find.byKey(const ValueKey('main-nav-3')))
        .onTap!();
    await tester.pump();
    expect(find.byKey(const ValueKey('main-tab-3')), findsOneWidget);

    final popScope = tester.widget<Widget>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    ) as dynamic;
    popScope.onPopInvokedWithResult(false, null);
    await tester.pump();
    expect(find.byKey(const ValueKey('main-tab-0')), findsOneWidget);
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
