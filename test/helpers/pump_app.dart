import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/app/theme/app_theme.dart';
import 'package:gigflow/app/theme/theme_cubit.dart';
import 'package:gigflow/core/services/connectivity_cubit.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_cubit.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    AuthBloc? authBloc,
    TaskBloc? taskBloc,
    TaskFilterCubit? filterCubit,
    ThemeCubit? themeCubit,
    ConnectivityCubit? connectivityCubit,
    ThemeData? theme,
  }) async {
    final theme0 = themeCubit ?? MockThemeCubit();
    if (themeCubit == null) {
      when(() => theme0.state).thenReturn(ThemeMode.dark);
    }
    final conn = connectivityCubit ?? MockConnectivityCubit();
    if (connectivityCubit == null) when(() => conn.state).thenReturn(true);
    await pumpWidget(
      RepositoryProvider<TaskRepository>.value(
        value: MockTaskRepository(),
        child: MultiBlocProvider(
          providers: [
            if (authBloc != null) BlocProvider<AuthBloc>.value(value: authBloc),
            if (taskBloc != null) BlocProvider<TaskBloc>.value(value: taskBloc),
            if (filterCubit != null)
              BlocProvider<TaskFilterCubit>.value(value: filterCubit),
            BlocProvider<ThemeCubit>.value(value: theme0),
            BlocProvider<ConnectivityCubit>.value(value: conn),
          ],
          child: MaterialApp(theme: theme ?? AppTheme.dark(), home: child),
        ),
      ),
    );
  }
}
