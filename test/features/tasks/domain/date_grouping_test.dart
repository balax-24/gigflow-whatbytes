import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/utils/date_grouping.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';

import '../../../helpers/test_data.dart';

void main() {
  test('audit counter-example stays in one ordered past-due group', () {
    final done7 = makeTask(id: 'a', due: DateTime(2026, 11, 22, 7), done: true);
    final open8 = makeTask(id: 'b', due: DateTime(2026, 11, 22, 8));
    final groups = DateGrouping.group(
      TaskQueryEngine.apply(tasks: [open8, done7]),
      testNow,
    );
    expect(groups, hasLength(1));
    expect(groups.single.section, TaskSection.pastDue);
    expect(groups.single.tasks.map((t) => t.id), ['a', 'b']);
    expect(groups.single.label(testNow), 'OVERDUE');
  });

  test('completed-only past bucket is labelled EARLIER', () {
    final g = DateGrouping.group([
      makeTask(due: DateTime(2026, 11, 21, 9), done: true),
    ], testNow);
    expect(g.single.label(testNow), 'EARLIER');
  });

  test('boundaries', () {
    expect(
      DateGrouping.sectionFor(DateTime(2026, 11, 22, 23, 59), testNow),
      TaskSection.today,
    );
    expect(
      DateGrouping.sectionFor(DateTime(2026, 11, 23), testNow),
      TaskSection.tomorrow,
    );
    expect(
      DateGrouping.sectionFor(DateTime(2026, 11, 24), testNow),
      TaskSection.thisWeek,
    );
    expect(
      DateGrouping.sectionFor(DateTime(2026, 11, 28, 23, 59), testNow),
      TaskSection.thisWeek,
    );
    expect(
      DateGrouping.sectionFor(DateTime(2026, 11, 29), testNow),
      TaskSection.upcoming,
    );
    expect(
      DateGrouping.sectionFor(DateTime(2026, 11, 22, 9, 59), testNow),
      TaskSection.pastDue,
    );
  });

  test('flattening groups preserves sorted order (property, seed 42)', () {
    final rnd = Random(42);
    final tasks = [
      for (var i = 0; i < 200; i++)
        makeTask(
          id: 'id$i',
          due: testNow.add(Duration(minutes: rnd.nextInt(8000) - 3000)),
          priority: TaskPriority.values[rnd.nextInt(3)],
          done: rnd.nextBool(),
        ),
    ];
    final sorted = TaskQueryEngine.apply(tasks: tasks);
    final groups = DateGrouping.group(sorted, testNow);
    final flat = [for (final g in groups) ...g.tasks];
    expect(flat.map((t) => t.id).toList(), sorted.map((t) => t.id).toList());
    final order = groups.map((g) => g.section.index).toList();
    expect(order, [...order]..sort());
  });
}
