import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';

class TaskFeed extends Equatable {
  const TaskFeed({
    required this.tasks,
    this.hasPendingWrites = false,
    this.isFromCache = false,
  });

  final List<TaskEntity> tasks;
  final bool hasPendingWrites;
  final bool isFromCache;

  @override
  List<Object?> get props => [tasks, hasPendingWrites, isFromCache];
}
