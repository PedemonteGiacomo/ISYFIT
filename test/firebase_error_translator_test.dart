import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/utils/firebase_error_translator.dart';

void main() {
  group('FirebaseErrorTranslator.fromException', () {
    test('translates FirebaseAuthException codes', () {
      final error = FirebaseAuthException(code: 'invalid-email');
      expect(
        FirebaseErrorTranslator.fromException(error),
        'The email address is invalid.',
      );
    });

    test('translates generic FirebaseException codes', () {
      final error =
          FirebaseException(plugin: 'firestore', code: 'permission-denied');
      expect(
        FirebaseErrorTranslator.fromException(error),
        'You do not have permission to perform this action.',
      );
    });

    test('handles unknown errors gracefully', () {
      final error = Exception('oops');
      expect(
        FirebaseErrorTranslator.fromException(error),
        'An unexpected error occurred. Please try again.',
      );
    });
  });
}
