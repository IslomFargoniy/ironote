import 'package:flutter_test/flutter_test.dart';
import 'package:ironote/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const IronoteApp());
    expect(find.text('IRONOTE'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
