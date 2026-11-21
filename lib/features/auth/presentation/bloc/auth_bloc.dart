import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/features/auth/domain/entities/app_user.dart';
import 'package:gigflow/features/auth/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository)
    : super(
        _repository.currentUser == null
            ? const AuthState()
            : AuthState(
                status: AuthStatus.authenticated,
                user: _repository.currentUser,
              ),
      ) {
    on<AuthSubscriptionRequested>(_onSubscribe, transformer: restartable());
    on<AuthLoginSubmitted>(_onLogin, transformer: droppable());
    on<AuthRegisterSubmitted>(_onRegister, transformer: droppable());
    on<AuthLogoutRequested>(_onLogout, transformer: droppable());
    on<AuthErrorCleared>((_, emit) => emit(state.copyWith(clearError: true)));
  }

  final AuthRepository _repository;

  Future<void> _onSubscribe(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) => emit.forEach<AppUser?>(
    _repository.authStateChanges,
    onData: (user) => user == null
        ? state.copyWith(status: AuthStatus.unauthenticated, clearUser: true)
        : state.copyWith(status: AuthStatus.authenticated, user: user),
  );

  Future<void> _onLogin(AuthLoginSubmitted e, Emitter<AuthState> emit) =>
      _submit(
        emit,
        () => _repository.signInWithEmail(
          email: e.email.trim(),
          password: e.password,
        ),
      );

  Future<void> _onRegister(AuthRegisterSubmitted e, Emitter<AuthState> emit) =>
      _submit(
        emit,
        () => _repository.registerWithEmail(
          email: e.email.trim(),
          password: e.password,
        ),
      );

  Future<void> _submit(
    Emitter<AuthState> emit,
    Future<AppUser> Function() action,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await action(); // status change arrives via authStateChanges
      emit(state.copyWith(isSubmitting: false));
    } on AuthFailure catch (failure) {
      emit(state.copyWith(isSubmitting: false, errorMessage: failure.message));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await _repository.signOut();
  }
}
