import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';

final class TaskFilterState extends Equatable {
  const TaskFilterState({
    this.priority,
    this.status = TaskStatusFilter.all,
    this.query = '',
  });

  /// null == All priorities.
  final TaskPriority? priority;
  final TaskStatusFilter status;
  final String query;

  bool get isFiltering =>
      priority != null ||
      status != TaskStatusFilter.all ||
      query.trim().isNotEmpty;

  int get activeCount =>
      (priority != null ? 1 : 0) +
      (status != TaskStatusFilter.all ? 1 : 0) +
      (query.trim().isNotEmpty ? 1 : 0);

  TaskFilterState copyWith({
    TaskPriority? priority,
    bool clearPriority = false,
    TaskStatusFilter? status,
    String? query,
  }) => TaskFilterState(
    priority: clearPriority ? null : (priority ?? this.priority),
    status: status ?? this.status,
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [priority, status, query];
}
