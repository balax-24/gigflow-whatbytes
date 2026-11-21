import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/features/tasks/data/datasources/local_preferences_datasource.dart';
import 'package:gigflow/features/tasks/domain/enums/task_category.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_state.dart';

class TaskFilterCubit extends Cubit<TaskFilterState> {
  TaskFilterCubit(this._prefs)
    : super(
        TaskFilterState(
          priority: _prefs.readPriority(),
          status: _prefs.readStatus(),
          category: _prefs.readCategory(),
        ),
      );

  final LocalPreferencesDataSource _prefs;

  Future<void> setPriority(TaskPriority? priority) async {
    emit(state.copyWith(priority: priority, clearPriority: priority == null));
    await _prefs.writePriority(priority);
  }

  Future<void> setStatus(TaskStatusFilter status) async {
    emit(state.copyWith(status: status));
    await _prefs.writeStatus(status);
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  Future<void> setCategory(TaskCategory? category) async {
    emit(state.copyWith(category: category, clearCategory: category == null));
    await _prefs.writeCategory(category);
  }

  /// Tapping the selected day again clears the day filter.
  void toggleDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    emit(
      state.day == d ? state.copyWith(clearDay: true) : state.copyWith(day: d),
    );
  }

  Future<void> clearAll() async {
    emit(const TaskFilterState());
    await _prefs.writePriority(null);
    await _prefs.writeStatus(TaskStatusFilter.all);
    await _prefs.writeCategory(null);
  }
}
