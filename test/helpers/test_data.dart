import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

/// Fixed reference "now": Sunday 22 Nov 2026, 10:00 local.
final testNow = DateTime(2026, 11, 22, 10);

TaskEntity makeTask({
  String id = 't1',
  String title = 'Task',
  String description = '',
  DateTime? due,
  TaskPriority priority = TaskPriority.medium,
  bool done = false,
  DateTime? created,
}) {
  final c = created ?? DateTime(2026, 11, 20, 8);
  return TaskEntity(
    id: id,
    title: title,
    description: description,
    dueDate: due ?? testNow.add(const Duration(hours: 2)),
    priority: priority,
    isCompleted: done,
    createdAt: c,
    updatedAt: c,
  );
}
