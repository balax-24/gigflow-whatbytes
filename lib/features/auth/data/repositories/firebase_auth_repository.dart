import 'package:firebase_auth/firebase_auth.dart';

import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/core/error/firebase_error_mapper.dart';
import 'package:gigflow/features/auth/domain/entities/app_user.dart';
import 'package:gigflow/features/auth/domain/repositories/auth_repository.dart';

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

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      return _toUser((await _auth.signInWithProvider(provider)).user);
    } on FirebaseAuthException catch (e) {
      if (FirebaseErrorMapper.isUserCancellation(e.code)) return null;
      throw AuthFailure(
        FirebaseErrorMapper.mapAuthErrorCode(e.code),
        code: e.code,
      );
    } catch (_) {
      throw const AuthFailure(FirebaseErrorMapper.genericAuth);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

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
