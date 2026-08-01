import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nala/main.dart';
import 'package:nala/screens/edit_profile_screen.dart';
import 'package:nala/screens/login_screen.dart';
import 'package:nala/screens/reset_password_screen.dart';
import 'package:nala/screens/onboarding_screen.dart';
import 'package:nala/screens/register_screen.dart';
import 'package:nala/widgets/load_error_view.dart';
import 'package:nala/widgets/main_shell.dart';

void main() {
  testWidgets('Load error offers a working retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: LoadErrorView(onRetry: () => retried = true),
    ));

    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
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
