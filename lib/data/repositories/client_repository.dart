import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ClientRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ClientRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> fetchClientsData(
      List<String> clientIds) async {
    final futures = clientIds.map((id) async {
      final doc = await _firestore.collection('users').doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data()!..['uid'] = id;
      return data;
    });
    final results = await Future.wait(futures);
    return results.whereType<Map<String, dynamic>>().toList();
  }

  Future<String?> findClientByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .where('role', isEqualTo: 'Client')
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  Future<void> linkClientToPT(String ptUid, String clientUid) async {
    await _firestore.collection('users').doc(ptUid).update({
      'clients': FieldValue.arrayUnion([clientUid])
    });
    await _firestore.collection('users').doc(clientUid).update({
      'isSolo': false,
      'supervisorPT': ptUid,
    });
  }

  Future<void> unlinkClientFromPT(String ptUid, String clientUid) async {
    await _firestore.collection('users').doc(ptUid).update({
      'clients': FieldValue.arrayRemove([clientUid])
    });
    await _firestore.collection('users').doc(clientUid).update({
      'isSolo': true,
      'supervisorPT': FieldValue.delete(),
    });
  }

  Future<String> registerClient({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String ptUid,
    String? phone,
    String? gender,
    DateTime? dob,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'clientReg',
      options: Firebase.app().options,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    try {
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final clientUid = cred.user!.uid;

      final docData = {
        'role': 'Client',
        'email': email,
        'name': name,
        'surname': surname,
        'isSolo': false,
        'supervisorPT': ptUid,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (gender != null) 'gender': gender,
        if (dob != null) 'dateOfBirth': dob.toIso8601String(),
      };

      await _firestore.collection('users').doc(clientUid).set(docData);
      await linkClientToPT(ptUid, clientUid);
      return clientUid;
    } finally {
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    }
  }
}
