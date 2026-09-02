import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aahar_ai/main.dart';

void main() {
  testWidgets('AaharAiApp builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AaharAiApp(),
      ),
    );
    expect(find.text('AaharAi'), findsWidgets);
  });
}
