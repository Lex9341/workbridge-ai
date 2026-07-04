import 'package:flutter_test/flutter_test.dart';
import 'package:workbridge_ai_app/main.dart';

void main() {
  testWidgets('shows WorkBridge dashboard', (tester) async {
    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pumpAndSettle();

    expect(find.text('International IT readiness'), findsOneWidget);
    expect(find.text('Total jobs found'), findsOneWidget);
    expect(find.text('Selected countries'), findsOneWidget);
  });
}
