import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nala/screens/onboarding_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can open and dismiss the login flow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );

    await tester.tap(find.text('Masuk ke NALA'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Gunakan akun yang sudah terdaftar.'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tapAt(const Offset(12, 12));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BottomSheet), findsNothing);
  });
}
