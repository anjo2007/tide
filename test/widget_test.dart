import 'package:flutter_test/flutter_test.dart';
import 'package:tide/main.dart';

void main() {
  testWidgets('Tide App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TideApp());

    // Verify that our auth screen loads and shows the "Tide" brand name.
    expect(find.text('Tide'), findsOneWidget);
  });
}
