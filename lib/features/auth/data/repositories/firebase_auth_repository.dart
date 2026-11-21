import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:gigflow/core/config/google_oauth.dart';
import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/core/error/firebase_error_mapper.dart';
import 'package:gigflow/features/auth/domain/entities/app_user.dart';
import 'package:gigflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_toUser);

  @override
  AppUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => _run(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) => _run(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        FirebaseErrorMapper.mapAuthErrorCode(e.code),
        code: e.code,
      );
    } catch (_) {
      throw const AuthFailure(FirebaseErrorMapper.genericAuth);
    }
  }

  bool _googleReady = false;

  /// Native Google sign-in (Android Credential Manager / iOS GIS) -> ID token
  /// -> Firebase credential. Avoids the browser redirect flow, which breaks
  /// under Chrome storage partitioning ("missing initial state").
  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final google = GoogleSignIn.instance;
      if (!_googleReady) {
        await google.initialize(
          clientId: GoogleOAuth.platformClientId,
          serverClientId: GoogleOAuth.webClientId,
        );
        _googleReady = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(FirebaseErrorMapper.googleUnavailable);
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _toUser((await _auth.signInWithCredential(credential)).user);
    } on GoogleSignInException catch (e) {
      debugPrint('GigFlow Google sign-in failed: ${e.code.name}');
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw const AuthFailure(FirebaseErrorMapper.googleUnavailable);
    } on FirebaseAuthException catch (e) {
      debugPrint('GigFlow Google credential rejected: ${e.code}');
      throw AuthFailure(
        FirebaseErrorMapper.mapAuthErrorCode(e.code),
        code: e.code,
      );
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('GigFlow Google sign-in unexpected error: ${e.runtimeType}');
      throw const AuthFailure(FirebaseErrorMapper.googleUnavailable);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Also forget the Google session so the account picker shows next time.
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  Future<AppUser> _run(Future<UserCredential> Function() call) async {
    try {
      final user = _toUser((await call()).user);
      if (user == null) {
        throw const AuthFailure(FirebaseErrorMapper.genericAuth);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        FirebaseErrorMapper.mapAuthErrorCode(e.code),
        code: e.code,
      );
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(FirebaseErrorMapper.genericAuth);
    }
  }

  static AppUser? _toUser(User? user) =>
      user == null ? null : AppUser(uid: user.uid, email: user.email ?? '');
}
