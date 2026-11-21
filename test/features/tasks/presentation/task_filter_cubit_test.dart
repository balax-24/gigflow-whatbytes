import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_cubit.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockPrefs prefs;

  setUp(() {
    prefs = MockPrefs();
    when(() => prefs.readPriority()).thenReturn(TaskPriority.high);
    when(() => prefs.readStatus()).thenReturn(TaskStatusFilter.incomplete);
    when(() => prefs.writePriority(any())).thenAnswer((_) async {});
    when(() => prefs.writeStatus(any())).thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(TaskStatusFilter.all));

  test('loads persisted values', () {
    expect(
      TaskFilterCubit(prefs).state,
      const TaskFilterState(
        priority: TaskPriority.high,
        status: TaskStatusFilter.incomplete,
      ),
    );
  });

  blocTest<TaskFilterCubit, TaskFilterState>(
    'setters emit and persist',
    build: () => TaskFilterCubit(prefs),
    act: (c) async {
      await c.setPriority(null);
      await c.setStatus(TaskStatusFilter.completed);
      c.setQuery('air');
    },
    expect: () => const [
      TaskFilterState(status: TaskStatusFilter.incomplete),
      TaskFilterState(status: TaskStatusFilter.completed),
      TaskFilterState(status: TaskStatusFilter.completed, query: 'air'),
    ],
    verify: (_) {
      verify(() => prefs.writePriority(null)).called(1);
      verify(() => prefs.writeStatus(TaskStatusFilter.completed)).called(1);
    },
  );

  blocTest<TaskFilterCubit, TaskFilterState>(
    'clearAll resets everything',
    build: () => TaskFilterCubit(prefs),
    seed: () => const TaskFilterState(
      priority: TaskPriority.low,
      status: TaskStatusFilter.completed,
      query: 'x',
    ),
    act: (c) => c.clearAll(),
    expect: () => const [TaskFilterState()],
  );
}
