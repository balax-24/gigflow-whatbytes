import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gigflow/app/theme/app_theme.dart';
import 'package:gigflow/app/theme/app_theme_option.dart';
import 'package:gigflow/app/theme/theme_cubit.dart';
import 'package:gigflow/core/services/connectivity_cubit.dart';
import 'package:gigflow/core/widgets/ambient_mesh_background.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_cubit.dart';
import 'package:go_router/go_router.dart';

class GigFlowApp extends StatelessWidget {
  const GigFlowApp({
    super.key,
    required this.router,
    required this.authBloc,
    required this.themeCubit,
    required this.filterCubit,
    required this.connectivityCubit,
    required this.taskRepository,
  });

  final GoRouter router;
  final AuthBloc authBloc;
  final ThemeCubit themeCubit;
  final TaskFilterCubit filterCubit;
  final ConnectivityCubit connectivityCubit;
  final TaskRepository taskRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<TaskRepository>.value(
      value: taskRepository,
      child: MultiBlocProvider(
        providers: [
          // .value => providers never close DI-owned singletons.
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<TaskFilterCubit>.value(value: filterCubit),
          BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
        ],
        child: BlocBuilder<ThemeCubit, AppThemeOption>(
          builder: (context, option) => MaterialApp.router(
            title: 'GigFlow',
            debugShowCheckedModeBanner: false,
            theme: option == AppThemeOption.lavender
                ? AppTheme.lavender()
                : AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: option.mode,
            routerConfig: router,
            builder: (context, child) =>
                AmbientMeshBackground(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
