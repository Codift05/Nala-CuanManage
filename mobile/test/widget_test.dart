import 'package:flutter_test/flutter_test.dart';
import 'package:nala/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NalaApp());

    expect(find.text('NALA'), findsOneWidget);
  });
}
