import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/features/auth/domain/entities/app_user.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repo;
  const user = AppUser(uid: 'u1', email: 'rider@gig.dev');

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.currentUser).thenReturn(null);
    when(() => repo.authStateChanges).thenAnswer((_) => const Stream.empty());
  });

  test('initial state is authenticated when a cached user exists', () {
    when(() => repo.currentUser).thenReturn(user);
    expect(AuthBloc(repo).state.status, AuthStatus.authenticated);
  });

  blocTest<AuthBloc, AuthState>(
    'subscription maps stream to unauthenticated -> authenticated',
    setUp: () => when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => Stream.fromIterable([null, user])),
    build: () => AuthBloc(repo),
    act: (b) => b.add(const AuthSubscriptionRequested()),
    expect: () => [
      const AuthState(status: AuthStatus.unauthenticated),
      const AuthState(status: AuthStatus.authenticated, user: user),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'login success toggles isSubmitting',
    setUp: () => when(
      () => repo.signInWithEmail(email: 'a@b.co', password: 'pw'),
    ).thenAnswer((_) async => user),
    build: () => AuthBloc(repo),
    act: (b) =>
        b.add(const AuthLoginSubmitted(email: ' a@b.co ', password: 'pw')),
    expect: () => [const AuthState(isSubmitting: true), const AuthState()],
    verify: (_) => verify(
      () => repo.signInWithEmail(email: 'a@b.co', password: 'pw'),
    ).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'login failure exposes mapped message',
    setUp: () => when(
      () => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthFailure('Incorrect email or password.')),
    build: () => AuthBloc(repo),
    act: (b) => b.add(const AuthLoginSubmitted(email: 'a@b.co', password: 'x')),
    expect: () => [
      const AuthState(isSubmitting: true),
      const AuthState(errorMessage: 'Incorrect email or password.'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'double submit is dropped (repository called once)',
    setUp: () {
      final completer = Completer<AppUser>();
      when(
        () => repo.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => completer.future);
      Future<void>.delayed(
        const Duration(milliseconds: 20),
        () => completer.complete(user),
      );
    },
    build: () => AuthBloc(repo),
    act: (b) => b
      ..add(const AuthLoginSubmitted(email: 'a@b.co', password: 'x'))
      ..add(const AuthLoginSubmitted(email: 'a@b.co', password: 'x')),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(
      () => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'logout calls signOut',
    setUp: () => when(() => repo.signOut()).thenAnswer((_) async {}),
    build: () => AuthBloc(repo),
    act: (b) => b.add(const AuthLogoutRequested()),
    verify: (_) => verify(() => repo.signOut()).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'error cleared',
    build: () => AuthBloc(repo),
    seed: () => const AuthState(errorMessage: 'x'),
    act: (b) => b.add(const AuthErrorCleared()),
    expect: () => [const AuthState()],
  );
}
