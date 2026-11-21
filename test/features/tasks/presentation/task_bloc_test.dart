import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/entities/task_feed.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockTaskRepository repo;
  final clockNow = DateTime(2026, 11, 22, 10, 30);
  final task = makeTask(id: 'a', title: 'Deliver');

  setUpAll(() => registerFallbackValue(makeTask()));

  setUp(() {
    repo = MockTaskRepository();
    when(() => repo.newTaskId('u1')).thenReturn('new-id');
    when(() => repo.upsertTask(any(), any())).thenAnswer((_) async {});
    when(() => repo.deleteTask(any(), any())).thenAnswer((_) async {});
    when(
      () => repo.setCompletion(
        any(),
        any(),
        isCompleted: any(named: 'isCompleted'),
        updatedAt: any(named: 'updatedAt'),
      ),
    ).thenAnswer((_) async {});
  });

  TaskBloc build() =>
      TaskBloc(repository: repo, userId: 'u1', clock: () => clockNow);

  blocTest<TaskBloc, TaskState>(
    'subscription emits loading then ready with the feed',
    setUp: () => when(() => repo.watchTasks('u1')).thenAnswer(
      (_) => Stream.value(TaskFeed(tasks: [task], hasPendingWrites: true)),
    ),
    build: build,
    act: (b) => b.add(const TaskSubscriptionRequested()),
    expect: () => [
      const TaskState(status: TaskLoadStatus.loading),
      TaskState(
        status: TaskLoadStatus.ready,
        tasks: [task],
        hasPendingWrites: true,
      ),
    ],
  );

  blocTest<TaskBloc, TaskState>(
    'stream error after data keeps tasks and sets message',
    setUp: () => when(() => repo.watchTasks('u1')).thenAnswer(
      (_) => Stream<TaskFeed>.fromFutures([
        Future.value(TaskFeed(tasks: [task])),
        Future<TaskFeed>.delayed(
          const Duration(milliseconds: 5),
          () => throw Exception('boom'),
        ),
      ]),
    ),
    build: build,
    act: (b) => b.add(const TaskSubscriptionRequested()),
    wait: const Duration(milliseconds: 20),
    skip: 2,
    expect: () => [
      TaskState(
        status: TaskLoadStatus.ready,
        tasks: [task],
        errorMessage: 'Could not refresh tasks. Showing saved data.',
      ),
    ],
  );

  blocTest<TaskBloc, TaskState>(
    'TaskCreated upserts a trimmed, minute-normalised task with generated id',
    build: build,
    act: (b) => b.add(
      TaskCreated(
        title: '  Pick up  ',
        description: ' gate ',
        dueDate: DateTime(2026, 11, 22, 12, 5, 33),
        priority: TaskPriority.high,
      ),
    ),
    verify: (_) => verify(
      () => repo.upsertTask(
        'u1',
        TaskEntity(
          id: 'new-id',
          title: 'Pick up',
          description: 'gate',
          dueDate: DateTime(2026, 11, 22, 12, 5),
          priority: TaskPriority.high,
          createdAt: clockNow,
          updatedAt: clockNow,
        ),
      ),
    ).called(1),
  );

  blocTest<TaskBloc, TaskState>(
    'TaskUpdated bumps updatedAt',
    build: build,
    act: (b) => b.add(TaskUpdated(task.copyWith(title: 'New'))),
    verify: (_) => verify(
      () => repo.upsertTask(
        'u1',
        task.copyWith(title: 'New', updatedAt: clockNow),
      ),
    ).called(1),
  );

  blocTest<TaskBloc, TaskState>(
    'toggle calls setCompletion with inverted value',
    build: build,
    act: (b) => b.add(TaskCompletionToggled(task)),
    verify: (_) => verify(
      () =>
          repo.setCompletion('u1', 'a', isCompleted: true, updatedAt: clockNow),
    ).called(1),
  );

  blocTest<TaskBloc, TaskState>(
    'delete hides immediately and calls repository',
    build: build,
    seed: () => TaskState(status: TaskLoadStatus.ready, tasks: [task]),
    act: (b) => b.add(TaskDeleted(task)),
    expect: () => [
      isA<TaskState>()
          .having((s) => s.pendingDeleteIds, 'pending', {'a'})
          .having((s) => s.visibleTasks, 'visible', isEmpty),
    ],
    verify: (_) => verify(() => repo.deleteTask('u1', 'a')).called(1),
  );

  blocTest<TaskBloc, TaskState>(
    'restore keeps same id + createdAt',
    build: build,
    seed: () => TaskState(
      status: TaskLoadStatus.ready,
      tasks: [task],
      pendingDeleteIds: const {'a'},
    ),
    act: (b) => b.add(TaskRestored(task)),
    expect: () => [
      TaskState(status: TaskLoadStatus.ready, tasks: [task]),
    ],
    verify: (_) {
      final captured =
          verify(() => repo.upsertTask('u1', captureAny())).captured.single
              as TaskEntity;
      expect(captured.id, 'a');
      expect(captured.createdAt, task.createdAt);
    },
  );

  blocTest<TaskBloc, TaskState>(
    'pending delete ids are pruned once the feed drops the doc',
    setUp: () => when(
      () => repo.watchTasks('u1'),
    ).thenAnswer((_) => Stream.value(const TaskFeed(tasks: []))),
    build: build,
    seed: () => TaskState(
      status: TaskLoadStatus.ready,
      tasks: [task],
      pendingDeleteIds: const {'a'},
    ),
    act: (b) => b.add(const TaskSubscriptionRequested()),
    skip: 1,
    expect: () => [const TaskState(status: TaskLoadStatus.ready)],
  );

  blocTest<TaskBloc, TaskState>(
    'server-rejected write surfaces the failure message',
    setUp: () => when(
      () => repo.deleteTask(any(), any()),
    ).thenAnswer((_) => Future.error(const TaskFailure('Rejected'))),
    build: build,
    act: (b) => b.add(TaskDeleted(task)),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const TaskState(pendingDeleteIds: {'a'}),
      const TaskState(pendingDeleteIds: {'a'}, errorMessage: 'Rejected'),
    ],
  );
}
