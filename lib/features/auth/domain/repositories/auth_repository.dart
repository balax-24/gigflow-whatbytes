import 'package:gigflow/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  /// Throws AuthFailure with a user-facing message.
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Throws AuthFailure with a user-facing message.
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  });

  /// Sends a password-reset email. Throws AuthFailure with a user-facing message.
  Future<void> sendPasswordReset({required String email});

  /// Google sign-in via Firebase's provider flow.
  /// Returns null if the user cancelled. Throws AuthFailure on errors.
  Future<AppUser?> signInWithGoogle();

  Future<void> signOut();
}
