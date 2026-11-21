import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/features/tasks/data/models/task_model.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

import '../../../helpers/test_data.dart';

void main() {
  test('round-trip preserves every field', () {
    final task = makeTask(
      id: 'abc',
      title: 'Deliver #4821',
      description: 'Fragile',
      due: DateTime(2026, 11, 23, 9),
      priority: TaskPriority.high,
      done: true,
    );
    final map = TaskModel.toFirestore(task);
    expect(map['priority'], 'high');
    expect(map['dueDate'], isA<Timestamp>());
    expect(TaskModel.fromMap('abc', map), task);
  });

  test(
    'pending serverTimestamp (null) never throws; falls back to dueDate',
    () {
      final due = DateTime(2026, 11, 23, 9);
      final t = TaskModel.fromMap('x', {
        'title': 'A',
        'description': 'B',
        'dueDate': Timestamp.fromDate(due),
        'priority': 'low',
        'isCompleted': false,
        'createdAt': null,
        'updatedAt': null,
      });
      expect(t.createdAt, due);
      expect(t.updatedAt, due);
      expect(t.dueDate, due);
    },
  );

  test('bad data falls back safely', () {
    final clock = DateTime(2026, 1, 1);
    final t = TaskModel.fromMap('x', {
      'title': 42,
      'priority': 'urgent',
      'isCompleted': 'yes',
    }, clock: () => clock);
    expect(t.title, '');
    expect(t.description, '');
    expect(t.priority, TaskPriority.medium);
    expect(t.isCompleted, isFalse);
    expect(t.dueDate, clock);
  });
}
