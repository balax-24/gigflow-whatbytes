import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';

enum TaskLoadStatus { initial, loading, ready, failure }

final class TaskState extends Equatable {
  const TaskState({
    this.status = TaskLoadStatus.initial,
    this.tasks = const [],
    this.pendingDeleteIds = const {},
    this.hasPendingWrites = false,
    this.isFromCache = false,
    this.errorMessage,
  });

  final TaskLoadStatus status;
  final List<TaskEntity> tasks; // raw feed (ordered by dueDate)
  final Set<String> pendingDeleteIds;
  final bool hasPendingWrites;
  final bool isFromCache;
  final String? errorMessage;

  List<TaskEntity> get visibleTasks => pendingDeleteIds.isEmpty
      ? tasks
      : [
          for (final t in tasks)
            if (!pendingDeleteIds.contains(t.id)) t,
        ];

  TaskState copyWith({
    TaskLoadStatus? status,
    List<TaskEntity>? tasks,
    Set<String>? pendingDeleteIds,
    bool? hasPendingWrites,
    bool? isFromCache,
    String? errorMessage,
    bool clearError = false,
  }) => TaskState(
    status: status ?? this.status,
    tasks: tasks ?? this.tasks,
    pendingDeleteIds: pendingDeleteIds ?? this.pendingDeleteIds,
    hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
    isFromCache: isFromCache ?? this.isFromCache,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [
    status,
    tasks,
    pendingDeleteIds,
    hasPendingWrites,
    isFromCache,
    errorMessage,
  ];
}
