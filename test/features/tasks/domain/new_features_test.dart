import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/features/tasks/data/models/task_model.dart';
import 'package:gigflow/features/tasks/domain/enums/task_category.dart';
import 'package:gigflow/features/tasks/domain/utils/relative_due.dart';
import 'package:gigflow/features/tasks/domain/utils/shift_stats.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('RelativeDue', () {
    test('overdue spans', () {
      expect(
        RelativeDue.of(
          testNow.subtract(const Duration(minutes: 5)),
          testNow,
        )!.label,
        '5m overdue',
      );
      final r = RelativeDue.of(
        testNow.subtract(const Duration(hours: 2)),
        testNow,
      )!;
      expect(r.label, '2h overdue');
      expect(r.urgency, DueUrgency.overdue);
      expect(
        RelativeDue.of(
          testNow.subtract(const Duration(days: 3)),
          testNow,
        )!.label,
        '3d overdue',
      );
    });

    test('upcoming spans and urgency', () {
      final soon = RelativeDue.of(
        testNow.add(const Duration(minutes: 45)),
        testNow,
      )!;
      expect(soon.label, 'in 45m');
      expect(soon.urgency, DueUrgency.soon);
      expect(
        RelativeDue.of(
          testNow.add(const Duration(hours: 1, minutes: 30)),
          testNow,
        )!.label,
        'in 1h 30m',
      );
      final later = RelativeDue.of(
        testNow.add(const Duration(hours: 8)),
        testNow,
      )!;
      expect(later.label, 'in 8h');
      expect(later.urgency, DueUrgency.later);
      expect(RelativeDue.of(testNow, testNow)!.label, 'Due now');
    });

    test('null for completed and far-future tasks', () {
      expect(RelativeDue.of(testNow, testNow, completed: true), isNull);
      expect(
        RelativeDue.of(testNow.add(const Duration(days: 8)), testNow),
        isNull,
      );
    });

    test('greeting by time of day', () {
      expect(greetingFor(DateTime(2026, 1, 1, 7)), startsWith('Good morning'));
      expect(
        greetingFor(DateTime(2026, 1, 1, 13)),
        startsWith('Good afternoon'),
      );
      expect(greetingFor(DateTime(2026, 1, 1, 19)), startsWith('Good evening'));
      expect(greetingFor(DateTime(2026, 1, 1, 2)), startsWith('Late shift'));
    });
  });

  group('Category + day filters', () {
    final a = makeTask(id: 'a', due: DateTime(2026, 11, 22, 12));
    final b = makeTask(
      id: 'b',
      due: DateTime(2026, 11, 23, 9),
    ).copyWith(category: TaskCategory.delivery);
    final c = makeTask(
      id: 'c',
      due: DateTime(2026, 11, 23, 18),
    ).copyWith(category: TaskCategory.ride);

    test('category filter', () {
      expect(
        TaskQueryEngine.apply(
          tasks: [a, b, c],
          categoryFilter: TaskCategory.delivery,
        ).map((t) => t.id),
        ['b'],
      );
    });

    test('day filter keeps order', () {
      expect(
        TaskQueryEngine.apply(
          tasks: [c, a, b],
          dayFilter: DateTime(2026, 11, 23),
        ).map((t) => t.id),
        ['b', 'c'],
      );
    });

    test('model round-trips category; legacy docs default to general', () {
      final map = TaskModel.toFirestore(b);
      expect(map['category'], 'delivery');
      expect(TaskModel.fromMap('b', map).category, TaskCategory.delivery);
      final legacy = TaskModel.fromMap('x', {
        'title': 'Old',
        'dueDate': Timestamp.fromDate(testNow),
      });
      expect(legacy.category, TaskCategory.general);
      expect(TaskCategory.fromName('bogus'), TaskCategory.general);
    });
  });

  group('ShiftStats.justCleared', () {
    const half = ShiftStats(
      todayTotal: 2,
      todayDone: 1,
      overdue: 0,
      highOpen: 0,
    );
    const all = ShiftStats(
      todayTotal: 2,
      todayDone: 2,
      overdue: 0,
      highOpen: 0,
    );
    test('fires when the last open task is completed', () {
      expect(ShiftStats.justCleared(half, all), isTrue);
    });
    test('does not fire on initial load', () {
      expect(ShiftStats.justCleared(ShiftStats.empty, all), isFalse);
    });
    test('does not fire when the last open task is deleted', () {
      const deleted = ShiftStats(
        todayTotal: 1,
        todayDone: 1,
        overdue: 0,
        highOpen: 0,
      );
      expect(ShiftStats.justCleared(half, deleted), isFalse);
    });
  });
}
