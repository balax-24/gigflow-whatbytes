import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';

enum TaskSection { pastDue, today, tomorrow, upcoming }

final class TaskSectionGroup {
  const TaskSectionGroup(this.section, this.tasks);

  final TaskSection section;
  final List<TaskEntity> tasks;

  /// "OVERDUE" if any task in the past bucket is incomplete, else "EARLIER".
  String label(DateTime now) => switch (section) {
    TaskSection.pastDue =>
      tasks.any((t) => t.isOverdueAt(now)) ? 'OVERDUE' : 'EARLIER',
    TaskSection.today => 'TODAY',
    TaskSection.tomorrow => 'TOMORROW',
    TaskSection.upcoming => 'UPCOMING',
  };
}

/// Buckets purely by time thresholds, so the bucket order is monotonic and
/// flattening the groups always preserves earliest-to-latest order.
abstract final class DateGrouping {
  static TaskSection sectionFor(DateTime due, DateTime now) {
    final d = due.toLocal();
    final n = now.toLocal();
    final startOfTomorrow = DateTime(n.year, n.month, n.day + 1);
    final startOfDayAfter = DateTime(n.year, n.month, n.day + 2);
    if (d.isBefore(n)) return TaskSection.pastDue;
    if (d.isBefore(startOfTomorrow)) return TaskSection.today;
    if (d.isBefore(startOfDayAfter)) return TaskSection.tomorrow;
    return TaskSection.upcoming;
  }

  /// [sorted] MUST already be sorted by TaskQueryEngine.
  static List<TaskSectionGroup> group(List<TaskEntity> sorted, DateTime now) {
    final buckets = <TaskSection, List<TaskEntity>>{};
    for (final task in sorted) {
      (buckets[sectionFor(task.dueDate, now)] ??= []).add(task);
    }
    return [
      for (final section in TaskSection.values)
        if (buckets[section] case final tasks?)
          TaskSectionGroup(section, tasks),
    ];
  }
}
