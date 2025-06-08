import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:isyfit/services/auth_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthRepository repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    repository = AuthRepository(auth: mockAuth);
  });

  test('signIn delegates to FirebaseAuth', () async {
    final credential = MockUserCredential();
    when(() => mockAuth.signInWithEmailAndPassword(email: 'e', password: 'p'))
        .thenAnswer((_) async => credential);

    final result = await repository.signIn('e', 'p');

    expect(result, credential);
    verify(() =>
            mockAuth.signInWithEmailAndPassword(email: 'e', password: 'p'))
        .called(1);
  });

  test('register delegates to FirebaseAuth', () async {
    final credential = MockUserCredential();
    when(() => mockAuth.createUserWithEmailAndPassword(email: 'e', password: 'p'))
        .thenAnswer((_) async => credential);

    final result = await repository.register('e', 'p');

    expect(result, credential);
    verify(() => mockAuth.createUserWithEmailAndPassword(email: 'e', password: 'p'))
        .called(1);
  });
}
