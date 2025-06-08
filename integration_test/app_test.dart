import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:isyfit/main.dart';
import 'package:isyfit/screens/login_screen.dart';
import 'package:isyfit/screens/base_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app smoke test', (tester) async {
    final auth = MockFirebaseAuth();
    await tester.pumpWidget(const IsyFitApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    // After splash the auth gate should load login or base screen.
    final isLogin = find.byType(LoginScreen).evaluate().isNotEmpty;
    final isBase = find.byType(BaseScreen).evaluate().isNotEmpty;
    expect(isLogin || isBase, true);
  });
}
