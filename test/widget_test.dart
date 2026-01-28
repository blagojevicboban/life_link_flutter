
import 'package:flutter_test/flutter_test.dart';

import 'package:life_link/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LifeLinkApp());

    // Verify 'LIFELINK' text is present on the Dashboard
    expect(find.text('LIFELINK'), findsOneWidget);
  });
}
