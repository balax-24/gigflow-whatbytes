import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';

import '../../../helpers/test_data.dart';

void main() {
  final past = makeTask(
    id: 'past',
    due: testNow.subtract(const Duration(days: 1)),
  );
  final today = makeTask(
    id: 'today',
    due: testNow.add(const Duration(hours: 3)),
    priority: TaskPriority.high,
    done: true,
  );
  final nextWeek = makeTask(
    id: 'week',
    due: testNow.add(const Duration(days: 7)),
    priority: TaskPriority.low,
  );

  List<String> ids(List<dynamic> l) => [for (final t in l) t.id as String];

  test('sorts strictly earliest to latest', () {
    final r = TaskQueryEngine.apply(tasks: [nextWeek, today, past]);
    expect(ids(r), ['past', 'today', 'week']);
  });

  test('same dueDate -> high, medium, low', () {
    final due = testNow.add(const Duration(hours: 1));
    final r = TaskQueryEngine.apply(
      tasks: [
        makeTask(id: 'l', due: due, priority: TaskPriority.low),
        makeTask(id: 'h', due: due, priority: TaskPriority.high),
        makeTask(id: 'm', due: due),
      ],
    );
    expect(ids(r), ['h', 'm', 'l']);
  });

  test('same due & priority -> createdAt then id', () {
    final due = testNow.add(const Duration(hours: 1));
    final r = TaskQueryEngine.apply(
      tasks: [
        makeTask(id: 'b', due: due, created: DateTime(2026, 11, 21)),
        makeTask(id: 'c', due: due, created: DateTime(2026, 11, 20)),
        makeTask(id: 'a', due: due, created: DateTime(2026, 11, 21)),
      ],
    );
    expect(ids(r), ['c', 'a', 'b']);
  });

  test('filters by priority alone', () {
    for (final p in TaskPriority.values) {
      final r = TaskQueryEngine.apply(
        tasks: [past, today, nextWeek],
        priorityFilter: p,
      );
      expect(r.every((t) => t.priority == p), isTrue);
    }
    expect(
      ids(
        TaskQueryEngine.apply(
          tasks: [past, today, nextWeek],
          priorityFilter: TaskPriority.high,
        ),
      ),
      ['today'],
    );
  });

  test('filters by status alone', () {
    expect(
      ids(
        TaskQueryEngine.apply(
          tasks: [past, today, nextWeek],
          statusFilter: TaskStatusFilter.completed,
        ),
      ),
      ['today'],
    );
    expect(
      ids(
        TaskQueryEngine.apply(
          tasks: [nextWeek, today, past],
          statusFilter: TaskStatusFilter.incomplete,
        ),
      ),
      ['past', 'week'],
    );
  });

  test('combined priority + status keeps order', () {
    final a = makeTask(
      id: 'a',
      due: testNow.add(const Duration(hours: 5)),
      priority: TaskPriority.high,
    );
    final b = makeTask(
      id: 'b',
      due: testNow.add(const Duration(hours: 1)),
      priority: TaskPriority.high,
    );
    final r = TaskQueryEngine.apply(
      tasks: [a, today, b, nextWeek],
      priorityFilter: TaskPriority.high,
      statusFilter: TaskStatusFilter.incomplete,
    );
    expect(ids(r), ['b', 'a']);
  });

  group('search', () {
    final t1 = makeTask(id: '1', title: 'Airport drop', due: testNow);
    final t2 = makeTask(
      id: '2',
      title: 'Deliver',
      description: 'Gate code at AIRPORT road',
      due: testNow.add(const Duration(hours: 1)),
    );
    final t3 = makeTask(
      id: '3',
      title: 'Restock',
      due: testNow.add(const Duration(hours: 2)),
      priority: TaskPriority.high,
    );

    test('matches title and description, case-insensitive, trimmed', () {
      expect(
        ids(
          TaskQueryEngine.apply(tasks: [t3, t2, t1], searchQuery: '  airport '),
        ),
        ['1', '2'],
      );
    });

    test('combines with filters', () {
      expect(
        TaskQueryEngine.apply(
          tasks: [t1, t2, t3],
          searchQuery: 'airport',
          priorityFilter: TaskPriority.high,
        ),
        isEmpty,
      );
    });
  });

  test('does not mutate input and returns unmodifiable list', () {
    final input = [nextWeek, past];
    final r = TaskQueryEngine.apply(tasks: input);
    expect(ids(input), ['week', 'past']);
    expect(() => r.add(today), throwsUnsupportedError);
  });

  test('normalizeToMinute drops seconds', () {
    expect(
      normalizeToMinute(DateTime(2026, 1, 1, 9, 30, 45, 123)),
      DateTime(2026, 1, 1, 9, 30),
    );
  });
}
