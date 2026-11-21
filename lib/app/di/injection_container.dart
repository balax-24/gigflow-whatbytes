import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:gigflow/app/router/app_router.dart';
import 'package:gigflow/app/theme/theme_cubit.dart';
import 'package:gigflow/core/services/connectivity_cubit.dart';
import 'package:gigflow/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:gigflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/tasks/data/datasources/local_preferences_datasource.dart';
import 'package:gigflow/features/tasks/data/repositories/firestore_task_repository.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: LocalPreferencesDataSource.keys,
    ),
  );

  sl
    // External
    ..registerSingleton<FirebaseAuth>(FirebaseAuth.instance)
    ..registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance)
    ..registerSingleton<Connectivity>(Connectivity())
    // Data
    ..registerLazySingleton<LocalPreferencesDataSource>(
      () => LocalPreferencesDataSource(prefs),
    )
    ..registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository(sl()))
    ..registerLazySingleton<TaskRepository>(() => FirestoreTaskRepository(sl()))
    // App-lifetime state
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(sl())..add(const AuthSubscriptionRequested()),
      dispose: (b) => b.close(),
    )
    ..registerLazySingleton<ThemeCubit>(
      () => ThemeCubit(sl()),
      dispose: (c) => c.close(),
    )
    ..registerLazySingleton<TaskFilterCubit>(
      () => TaskFilterCubit(sl()),
      dispose: (c) => c.close(),
    )
    ..registerLazySingleton<ConnectivityCubit>(
      () => ConnectivityCubit(sl()),
      dispose: (c) => c.close(),
    )
    // Per-session: scoped to the /tasks route and closed by its BlocProvider.
    ..registerFactoryParam<TaskBloc, String, void>(
      (uid, _) => TaskBloc(repository: sl(), userId: uid),
    )
    ..registerLazySingleton<AppRouter>(
      () => AppRouter(
        sl(),
        (uid) => sl<TaskBloc>(param1: uid),
        onboardingSeen: () =>
            sl<LocalPreferencesDataSource>().readOnboardingSeen(),
      ),
      dispose: (r) => r.dispose(),
    );
}
