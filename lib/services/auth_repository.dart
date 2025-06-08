import 'package:firebase_auth/firebase_auth.dart';

/// Simple wrapper around [FirebaseAuth] to allow easier testing and
/// separation of concerns.
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Sign in with email and password.
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Create a user with email and password.
  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
