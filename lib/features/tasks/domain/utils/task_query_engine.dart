import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_category.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';

/// Pure filter + search + deterministic earliest-to-latest sort.
abstract final class TaskQueryEngine {
  static List<TaskEntity> apply({
    required List<TaskEntity> tasks,
    TaskPriority? priorityFilter, // null == All
    TaskStatusFilter statusFilter = TaskStatusFilter.all,
    TaskCategory? categoryFilter, // null == All
    DateTime? dayFilter, // local calendar day; null == any day
    String searchQuery = '',
  }) {
    final query = searchQuery.trim().toLowerCase();
    final result = [
      for (final task in tasks)
        if (_matches(task, priorityFilter, statusFilter, query) &&
            (categoryFilter == null || task.category == categoryFilter) &&
            (dayFilter == null || isSameDay(task.dueDate, dayFilter)))
          task,
    ]..sort(compare);
    return List.unmodifiable(result);
  }

  /// Total order: dueDate asc -> priority (high first) -> createdAt -> id.
  static int compare(TaskEntity a, TaskEntity b) {
    final byDue = a.dueDate.compareTo(b.dueDate);
    if (byDue != 0) return byDue;
    final byPriority = a.priority.sortWeight.compareTo(b.priority.sortWeight);
    if (byPriority != 0) return byPriority;
    final byCreated = a.createdAt.compareTo(b.createdAt);
    if (byCreated != 0) return byCreated;
    return a.id.compareTo(b.id);
  }

  static bool _matches(
    TaskEntity task,
    TaskPriority? priority,
    TaskStatusFilter status,
    String query,
  ) {
    if (priority != null && task.priority != priority) return false;
    final statusOk = switch (status) {
      TaskStatusFilter.all => true,
      TaskStatusFilter.incomplete => !task.isCompleted,
      TaskStatusFilter.completed => task.isCompleted,
    };
    if (!statusOk) return false;
    if (query.isEmpty) return true;
    return task.title.toLowerCase().contains(query) ||
        task.description.toLowerCase().contains(query);
  }
}

bool isSameDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// Use everywhere a due date is produced (pickers, presets, edits).
DateTime normalizeToMinute(DateTime d) =>
    DateTime(d.year, d.month, d.day, d.hour, d.minute);
