import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:isyfit/data/repositories/auth_repository.dart';
import 'package:isyfit/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeUserCredential extends Fake implements UserCredential {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login flow calls signIn', (tester) async {
    final auth = _MockAuthRepository();
    when(() => auth.signIn(any(), any()))
        .thenAnswer((_) async => _FakeUserCredential());

    await tester
        .pumpWidget(MaterialApp(home: LoginScreen(authRepository: auth)));

    await tester.enterText(find.byType(TextField).first, 'e@e.com');
    await tester.enterText(find.byType(TextField).at(1), 'pw');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    verify(() => auth.signIn('e@e.com', 'pw')).called(1);
  });
}
