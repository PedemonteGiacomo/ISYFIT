import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:isyfit/screens/login_screen.dart';
import 'package:isyfit/screens/base_screen.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('successful login navigates to BaseScreen', (tester) async {
      final auth = MockFirebaseAuth();
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(auth: auth)),
      );

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.byType(BaseScreen), findsOneWidget);
    });
  });
}
