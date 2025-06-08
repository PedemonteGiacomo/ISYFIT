import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:isyfit/services/user_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late UserRepository repository;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocRef;
  late MockDocumentSnapshot mockDocSnap;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    repository = UserRepository(auth: mockAuth, firestore: mockFirestore);
    mockCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockDocSnap = MockDocumentSnapshot();
    mockUser = MockUser();

    when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
    when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
  });

  group('isCurrentUserPT', () {
    test('returns false when no current user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final result = await repository.isCurrentUserPT();
      expect(result, isFalse);
    });

    test('returns true when user role is PT', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('123');
      when(() => mockDocSnap.data()).thenReturn({'role': 'PT'});

      final result = await repository.isCurrentUserPT();
      expect(result, isTrue);
      verify(() => mockCollection.doc('123')).called(1);
    });
  });

  test('fetchUserProfile returns document data', () async {
    when(() => mockDocSnap.data()).thenReturn({'name': 'John'});

    final result = await repository.fetchUserProfile('u1');

    expect(result, {'name': 'John'});
    verify(() => mockCollection.doc('u1')).called(1);
  });
}
