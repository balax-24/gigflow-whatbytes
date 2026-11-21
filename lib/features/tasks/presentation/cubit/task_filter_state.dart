import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/enums/task_category.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';

final class TaskFilterState extends Equatable {
  const TaskFilterState({
    this.priority,
    this.status = TaskStatusFilter.all,
    this.query = '',
    this.category,
    this.day,
  });

  /// null == All priorities.
  final TaskPriority? priority;
  final TaskStatusFilter status;
  final String query;

  /// null == All categories.
  final TaskCategory? category;

  /// Selected day from the week strip (local midnight); null == any day.
  final DateTime? day;

  bool get isFiltering =>
      priority != null ||
      status != TaskStatusFilter.all ||
      query.trim().isNotEmpty ||
      category != null ||
      day != null;

  int get activeCount =>
      (priority != null ? 1 : 0) +
      (status != TaskStatusFilter.all ? 1 : 0) +
      (query.trim().isNotEmpty ? 1 : 0) +
      (category != null ? 1 : 0) +
      (day != null ? 1 : 0);

  TaskFilterState copyWith({
    TaskPriority? priority,
    bool clearPriority = false,
    TaskStatusFilter? status,
    String? query,
    TaskCategory? category,
    bool clearCategory = false,
    DateTime? day,
    bool clearDay = false,
  }) => TaskFilterState(
    priority: clearPriority ? null : (priority ?? this.priority),
    status: status ?? this.status,
    query: query ?? this.query,
    category: clearCategory ? null : (category ?? this.category),
    day: clearDay ? null : (day ?? this.day),
  );

  @override
  List<Object?> get props => [priority, status, query, category, day];
}
