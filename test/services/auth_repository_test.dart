import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/data/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeUserCredential extends Fake implements UserCredential {}

void main() {
  group('AuthRepository', () {
    late _MockFirebaseAuth mockAuth;
    late AuthRepository repository;

    setUpAll(() {
      registerFallbackValue(_FakeUserCredential());
    });

    setUp(() {
      mockAuth = _MockFirebaseAuth();
      repository = AuthRepository(auth: mockAuth);
    });

    test('signIn delegates to FirebaseAuth', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => _FakeUserCredential());

      await repository.signIn('mail@test.com', 'pwd');

      verify(() => mockAuth.signInWithEmailAndPassword(
            email: 'mail@test.com',
            password: 'pwd',
          )).called(1);
    });

    test('register delegates to FirebaseAuth', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => _FakeUserCredential());

      await repository.register('x@test.com', 'secret');

      verify(() => mockAuth.createUserWithEmailAndPassword(
            email: 'x@test.com',
            password: 'secret',
          )).called(1);
    });
  });
}
