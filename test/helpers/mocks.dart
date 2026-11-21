import 'package:bloc_test/bloc_test.dart';
import 'package:gigflow/app/theme/app_theme_option.dart';
import 'package:gigflow/app/theme/theme_cubit.dart';
import 'package:gigflow/core/services/connectivity_cubit.dart';
import 'package:gigflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/tasks/data/datasources/local_preferences_datasource.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_state.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_cubit.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockPrefs extends Mock implements LocalPreferencesDataSource {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockTaskBloc extends MockBloc<TaskEvent, TaskState> implements TaskBloc {}

class MockTaskFilterCubit extends MockCubit<TaskFilterState>
    implements TaskFilterCubit {}

class MockThemeCubit extends MockCubit<AppThemeOption> implements ThemeCubit {}

class MockConnectivityCubit extends MockCubit<bool>
    implements ConnectivityCubit {}
