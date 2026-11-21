import 'package:flutter/foundation.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';

/// Seeds [count] tasks spread from -2 days to +5 days for profiling.
/// No-op in release builds.
void seedDemoTasks(TaskRepository repo, String uid, {int count = 60}) {
  if (kReleaseMode) return;
  final now = DateTime.now();
  const titles = [
    'Deliver order',
    'Pick up parcel',
    'Airport drop',
    'Restock bag',
    'Shift check-in',
  ];
  for (var i = 0; i < count; i++) {
    final due = normalizeToMinute(now.add(Duration(minutes: -2880 + i * 167)));
    final created = now.subtract(Duration(minutes: count - i));
    repo
        .upsertTask(
          uid,
          TaskEntity(
            id: repo.newTaskId(uid),
            title: '${titles[i % titles.length]} #${4800 + i}',
            description:
                'Gate code ${1000 + i}. Call customer on arrival; fragile items.',
            dueDate: due,
            priority: TaskPriority.values[i % 3],
            isCompleted: i % 4 == 0,
            createdAt: created,
            updatedAt: created,
          ),
        )
        .ignore();
  }
}
