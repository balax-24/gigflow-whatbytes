import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/core/error/firebase_error_mapper.dart';

void main() {
  const cases = <String, String>{
    'invalid-credential':
        'Incorrect email or password. Please check your credentials and try again.',
    'wrong-password':
        'Incorrect email or password. Please check your credentials and try again.',
    'INVALID_LOGIN_CREDENTIALS':
        'Incorrect email or password. Please check your credentials and try again.',
    'user-not-found': 'No account found with this email address.',
    'invalid-email': 'Please enter a valid email address.',
    'missing-email': 'Please enter a valid email address.',
    'missing-password': 'Please enter your password.',
    'channel-error': 'Please enter both your email and password.',
    'email-already-in-use':
        'An account with this email already exists. Try signing in instead.',
    'weak-password':
        'Password is too weak. Use at least 6 characters including a letter and a number.',
    'user-disabled': 'This account has been disabled. Please contact support.',
    'too-many-requests':
        'Too many failed attempts. Please wait a moment and try again.',
    'network-request-failed':
        'No internet connection. Check your network and try again.',
    'operation-not-allowed':
        'Email/password sign-in is not enabled for this app.',
  };

  group('FirebaseErrorMapper.mapAuthErrorCode', () {
    cases.forEach((code, message) {
      test('maps $code', () {
        expect(FirebaseErrorMapper.mapAuthErrorCode(code), message);
      });
    });

    test('falls back for unknown codes', () {
      expect(
        FirebaseErrorMapper.mapAuthErrorCode('something-new'),
        FirebaseErrorMapper.genericAuth,
      );
    });
  });
}
