import 'package:flutter_test/flutter_test.dart';
import 'package:planova/main.dart';
// You may need to import your splash screen here for the test to recognize it
import 'package:planova/login_page/splash_screen.dart';

void main() {
  testWidgets('App starts on the assigned initial screen', (WidgetTester tester) async {
    // FIX: Pass a widget to the startScreen parameter
    await tester.pumpWidget(const PlanovaApp(startScreen: SplashScreen()));

    // Verify that the splash screen is the one being shown
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}