import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/utils/firebase_error_translator.dart';

void main() {
  group('FirebaseErrorTranslator', () {
    test('translates FirebaseAuthException codes', () {
      final error = FirebaseAuthException(code: 'invalid-email');
      expect(
        FirebaseErrorTranslator.fromException(error),
        'The email address is invalid.',
      );
    });

    test('translates FirebaseException codes', () {
      final error = FirebaseException(plugin: 'firestore', code: 'permission-denied');
      expect(
        FirebaseErrorTranslator.fromException(error),
        'You do not have permission to perform this action.',
      );
    });

    test('returns default message for unknown exceptions', () {
      final error = Exception('unknown');
      expect(
        FirebaseErrorTranslator.fromException(error),
        'An unexpected error occurred. Please try again.',
      );
    });
  });
}
