import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gigflow/app/router/go_router_refresh_stream.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/auth/presentation/screens/login_screen.dart';
import 'package:gigflow/features/auth/presentation/screens/register_screen.dart';
import 'package:gigflow/features/auth/presentation/screens/splash_screen.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/screens/task_dashboard_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const tasks = '/tasks';
}

typedef TaskBlocFactory = TaskBloc Function(String uid);

/// Created once (DI-owned). Redirects are driven by AuthBloc status/uid only.
class AppRouter {
  AppRouter(this._authBloc, this._taskBlocFactory)
    : _refresh = GoRouterRefreshStream(
        _authBloc.stream.map((s) => (s.status, s.user?.uid)).distinct(),
      ) {
    router = GoRouter(
      initialLocation: Routes.splash,
      refreshListenable: _refresh,
      redirect: _redirect,
      routes: [
        GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: Routes.register,
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: Routes.tasks,
          builder: (context, state) {
            final uid = _authBloc.state.user?.uid ?? '';
            return BlocProvider<TaskBloc>(
              key: ValueKey('tasks-$uid'),
              create: (_) =>
                  _taskBlocFactory(uid)..add(const TaskSubscriptionRequested()),
              child: const TaskDashboardScreen(),
            );
          },
        ),
      ],
    );
  }

  final AuthBloc _authBloc;
  final TaskBlocFactory _taskBlocFactory;
  final GoRouterRefreshStream _refresh;
  late final GoRouter router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final onAuthPage = location == Routes.login || location == Routes.register;
    return switch (_authBloc.state.status) {
      AuthStatus.unknown => location == Routes.splash ? null : Routes.splash,
      AuthStatus.unauthenticated => onAuthPage ? null : Routes.login,
      AuthStatus.authenticated =>
        (onAuthPage || location == Routes.splash) ? Routes.tasks : null,
    };
  }

  void dispose() {
    router.dispose();
    _refresh.dispose();
  }
}
