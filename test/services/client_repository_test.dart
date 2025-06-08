import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:isyfit/services/client_repository.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late ClientRepository repository;
  late MockCollectionReference collection;

  setUp(() {
    firestore = MockFirebaseFirestore();
    auth = MockFirebaseAuth();
    repository = ClientRepository(firestore: firestore, auth: auth);
    collection = MockCollectionReference();
    when(() => firestore.collection('users')).thenReturn(collection);
  });

  group('fetchClientsData', () {
    test('returns existing client data with uid', () async {
      final docRef = MockDocumentReference();
      final docSnap1 = MockDocumentSnapshot();
      final docSnap2 = MockDocumentSnapshot();

      when(() => collection.doc('1')).thenReturn(docRef);
      when(() => collection.doc('2')).thenReturn(docRef);
      when(() => docRef.get()).thenAnswer((_) async => docSnap1).thenAnswer((_) async => docSnap2);
      when(() => docSnap1.exists).thenReturn(true);
      when(() => docSnap1.data()).thenReturn({'name': 'Alice'});
      when(() => docSnap2.exists).thenReturn(false);

      final result = await repository.fetchClientsData(['1', '2']);

      expect(result.length, 1);
      expect(result.first['name'], 'Alice');
      expect(result.first['uid'], '1');
    });
  });

  group('findClientByEmail', () {
    test('returns first document id when found', () async {
      final query1 = MockQuery();
      final query2 = MockQuery();
      final query3 = MockQuery();
      final snapshot = MockQuerySnapshot();
      final doc = MockQueryDocumentSnapshot();

      when(() => collection.where('email', isEqualTo: 'a@test.com')).thenReturn(query1);
      when(() => query1.where('role', isEqualTo: 'Client')).thenReturn(query2);
      when(() => query2.limit(1)).thenReturn(query3);
      when(() => query3.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.docs).thenReturn([doc]);
      when(() => doc.id).thenReturn('doc1');

      final result = await repository.findClientByEmail('a@test.com');

      expect(result, 'doc1');
    });

    test('returns null when no match', () async {
      final query1 = MockQuery();
      final query2 = MockQuery();
      final query3 = MockQuery();
      final snapshot = MockQuerySnapshot();

      when(() => collection.where('email', isEqualTo: 'a@test.com')).thenReturn(query1);
      when(() => query1.where('role', isEqualTo: 'Client')).thenReturn(query2);
      when(() => query2.limit(1)).thenReturn(query3);
      when(() => query3.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.docs).thenReturn([]);

      final result = await repository.findClientByEmail('a@test.com');

      expect(result, isNull);
    });
  });

  test('linkClientToPT updates documents', () async {
    final ptDoc = MockDocumentReference();
    final clientDoc = MockDocumentReference();

    when(() => collection.doc('pt')).thenReturn(ptDoc);
    when(() => collection.doc('client')).thenReturn(clientDoc);
    when(() => ptDoc.update(any())).thenAnswer((_) async {});
    when(() => clientDoc.update(any())).thenAnswer((_) async {});

    await repository.linkClientToPT('pt', 'client');

    verify(() => ptDoc.update({'clients': FieldValue.arrayUnion(['client'])})).called(1);
    verify(() => clientDoc.update({'isSolo': false, 'supervisorPT': 'pt'})).called(1);
  });

  test('unlinkClientFromPT updates documents', () async {
    final ptDoc = MockDocumentReference();
    final clientDoc = MockDocumentReference();

    when(() => collection.doc('pt')).thenReturn(ptDoc);
    when(() => collection.doc('client')).thenReturn(clientDoc);
    when(() => ptDoc.update(any())).thenAnswer((_) async {});
    when(() => clientDoc.update(any())).thenAnswer((_) async {});

    await repository.unlinkClientFromPT('pt', 'client');

    verify(() => ptDoc.update({'clients': FieldValue.arrayRemove(['client'])})).called(1);
    verify(() => clientDoc.update({'isSolo': true, 'supervisorPT': FieldValue.delete()})).called(1);
  });
}
