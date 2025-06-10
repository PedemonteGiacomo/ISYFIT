import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the Firebase authentication state as a Riverpod [StreamProvider].
final authStateProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());
