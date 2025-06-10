import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<bool> isCurrentUserPT() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['role'] == 'PT';
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }
}
