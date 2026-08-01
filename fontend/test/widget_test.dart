import 'package:flutter_test/flutter_test.dart';

// Import your app entry point
import 'package:workforge/main.dart';
// Import your SplashScreen to find it in the test
import 'package:workforge/screens/splash_screen.dart';

void main() {
  testWidgets('App renders SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ContractorApp());

    // Verify that the SplashScreen is present.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}