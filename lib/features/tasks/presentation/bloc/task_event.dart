import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

sealed class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

final class TaskSubscriptionRequested extends TaskEvent {
  const TaskSubscriptionRequested();
}

final class TaskCreated extends TaskEvent {
  const TaskCreated({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
  });

  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;

  @override
  List<Object?> get props => [title, description, dueDate, priority];
}

final class TaskUpdated extends TaskEvent {
  const TaskUpdated(this.task);

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskCompletionToggled extends TaskEvent {
  const TaskCompletionToggled(this.task);

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskDeleted extends TaskEvent {
  const TaskDeleted(this.task);

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskRestored extends TaskEvent {
  const TaskRestored(this.task);

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskWriteFailed extends TaskEvent {
  const TaskWriteFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class TaskErrorDismissed extends TaskEvent {
  const TaskErrorDismissed();
}
