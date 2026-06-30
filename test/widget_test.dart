import 'package:flutter_test/flutter_test.dart';
import 'package:examen_flutter/main.dart';

void main() {
  testWidgets('BadWallet app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BadWalletApp());
    expect(find.byType(BadWalletApp), findsOneWidget);
  });
}
