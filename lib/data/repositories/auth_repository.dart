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

  /// Send a password reset email to the given address.
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Verify a password reset code sent via email and return the associated email.
  Future<String> verifyResetCode(String code) {
    return _auth.verifyPasswordResetCode(code);
  }

  /// Confirm the password reset with the given code and new password.
  Future<void> confirmPasswordReset(String code, String newPassword) {
    return _auth.confirmPasswordReset(code: code, newPassword: newPassword);
  }
}
