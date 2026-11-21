abstract final class FirebaseErrorMapper {
  static const genericAuth = 'Authentication failed. Please try again.';
  static const badCredentials =
      'Incorrect email or password. Please check your credentials and try again.';

  static String mapAuthErrorCode(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'invalid-login-credentials' ||
    'INVALID_LOGIN_CREDENTIALS' => badCredentials,
    'user-not-found' => 'No account found with this email address.',
    'invalid-email' || 'missing-email' => 'Please enter a valid email address.',
    'missing-password' => 'Please enter your password.',
    'channel-error' => 'Please enter both your email and password.',
    'email-already-in-use' =>
      'An account with this email already exists. Try signing in instead.',
    'weak-password' || 'password-does-not-meet-requirements' =>
      'Password is too weak. Use at least 6 characters including a letter and a number.',
    'user-disabled' =>
      'This account has been disabled. Please contact support.',
    'too-many-requests' =>
      'Too many failed attempts. Please wait a moment and try again.',
    'network-request-failed' || 'web-network-request-failed' =>
      'No internet connection. Check your network and try again.',
    'operation-not-allowed' =>
      'Email/password sign-in is not enabled for this app.',
    'account-exists-with-different-credential' =>
      'This email already uses password sign-in. Sign in with your password instead.',
    'web-internal-error' || 'web-storage-unsupported' =>
      "Google sign-in couldn't finish. Check your connection and try again.",
    'popup-blocked' || 'web-context-already-presented' =>
      'Google sign-in could not open. Please try again.',
    'provider-disabled' || 'invalid-oauth-client-id' || 'app-not-authorized' =>
      'Google sign-in is not available right now. Use email and password.',
    _ => genericAuth,
  };

  /// User closed the Google sheet/browser: not an error worth showing.
  static bool isUserCancellation(String code) => const {
    'canceled',
    'cancelled',
    'web-context-canceled',
    'web-context-cancelled',
    'popup-closed-by-user',
    'user-cancelled',
  }.contains(code);
}
