import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/enums/task_category.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.category = TaskCategory.general,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final TaskCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isOverdueAt(DateTime now) => !isCompleted && dueDate.isBefore(now);

  TaskEntity copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
    TaskCategory? category,
    DateTime? updatedAt,
  }) => TaskEntity(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    dueDate: dueDate ?? this.dueDate,
    priority: priority ?? this.priority,
    isCompleted: isCompleted ?? this.isCompleted,
    category: category ?? this.category,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    dueDate,
    priority,
    isCompleted,
    category,
    createdAt,
    updatedAt,
  ];
}
