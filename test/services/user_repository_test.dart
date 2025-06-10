import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/data/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _MockUser extends Mock implements User {}

void main() {
  group('UserRepository', () {
    late _MockFirebaseAuth auth;
    late _MockFirebaseFirestore firestore;
    late UserRepository repository;

    late _MockCollectionReference collection;
    late _MockDocumentReference docRef;
    late _MockDocumentSnapshot snapshot;
    late _MockUser user;

    setUp(() {
      auth = _MockFirebaseAuth();
      firestore = _MockFirebaseFirestore();
      repository = UserRepository(auth: auth, firestore: firestore);
      collection = _MockCollectionReference();
      docRef = _MockDocumentReference();
      snapshot = _MockDocumentSnapshot();
      user = _MockUser();
    });

    test('isCurrentUserPT returns true when role is PT', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('uid1');
      when(() => firestore.collection('users')).thenReturn(collection);
      when(() => collection.doc('uid1')).thenReturn(docRef);
      when(() => docRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.data()).thenReturn({'role': 'PT'});

      final result = await repository.isCurrentUserPT();
      expect(result, isTrue);
    });

    test('isCurrentUserPT returns false when no user', () async {
      when(() => auth.currentUser).thenReturn(null);
      final result = await repository.isCurrentUserPT();
      expect(result, isFalse);
    });

    test('fetchUserProfile returns data from firestore', () async {
      when(() => firestore.collection('users')).thenReturn(collection);
      when(() => collection.doc('uid2')).thenReturn(docRef);
      when(() => docRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.data()).thenReturn({'name': 'Foo'});

      final result = await repository.fetchUserProfile('uid2');
      expect(result, {'name': 'Foo'});
    });
  });
}
