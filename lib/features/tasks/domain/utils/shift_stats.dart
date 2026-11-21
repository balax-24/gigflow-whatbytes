import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

final class ShiftStats extends Equatable {
  const ShiftStats({
    required this.todayTotal,
    required this.todayDone,
    required this.overdue,
    required this.highOpen,
  });

  static const empty = ShiftStats(
    todayTotal: 0,
    todayDone: 0,
    overdue: 0,
    highOpen: 0,
  );

  final int todayTotal;
  final int todayDone;
  final int overdue; // incomplete & due before now (any day)
  final int highOpen; // incomplete high-priority (any day)

  double get progress => todayTotal == 0 ? 0 : todayDone / todayTotal;

  /// Computed from ALL visible tasks (ignores filters/search on purpose).
  static ShiftStats compute(List<TaskEntity> tasks, DateTime now) {
    final n = now.toLocal();
    final start = DateTime(n.year, n.month, n.day);
    final end = DateTime(n.year, n.month, n.day + 1);
    var total = 0;
    var done = 0;
    var overdue = 0;
    var high = 0;
    for (final t in tasks) {
      final d = t.dueDate.toLocal();
      if (!d.isBefore(start) && d.isBefore(end)) {
        total++;
        if (t.isCompleted) done++;
      }
      if (t.isOverdueAt(now)) overdue++;
      if (!t.isCompleted && t.priority == TaskPriority.high) high++;
    }
    return ShiftStats(
      todayTotal: total,
      todayDone: done,
      overdue: overdue,
      highOpen: high,
    );
  }

  bool get isCleared => todayTotal > 0 && todayDone == todayTotal;

  /// True when the user just finished the last open task due today
  /// (not on initial load, and not by deleting the last open task).
  static bool justCleared(ShiftStats before, ShiftStats after) =>
      !before.isCleared &&
      before.todayTotal > 0 &&
      after.isCleared &&
      after.todayDone > before.todayDone;

  @override
  List<Object?> get props => [todayTotal, todayDone, overdue, highOpen];
}
