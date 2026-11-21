import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/entities/task_feed.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc({
    required TaskRepository repository,
    required String userId,
    this._clock = DateTime.now,
  }) : _repo = repository,
       _uid = userId,
       super(const TaskState()) {
    on<TaskSubscriptionRequested>(_onSubscribe, transformer: restartable());
    on<TaskCreated>(_onCreated);
    on<TaskUpdated>(_onUpdated);
    on<TaskCompletionToggled>(_onToggled);
    on<TaskDeleted>(_onDeleted);
    on<TaskRestored>(_onRestored);
    on<TaskWriteFailed>(
      (e, emit) => emit(state.copyWith(errorMessage: e.message)),
    );
    on<TaskErrorDismissed>((_, emit) => emit(state.copyWith(clearError: true)));
  }

  final TaskRepository _repo;
  final String _uid;
  final DateTime Function() _clock;

  String get userId => _uid;

  Future<void> _onSubscribe(
    TaskSubscriptionRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskLoadStatus.loading));
    await emit.forEach<TaskFeed>(
      _repo.watchTasks(_uid),
      onData: (feed) {
        final present = {for (final t in feed.tasks) t.id};
        return state.copyWith(
          status: TaskLoadStatus.ready,
          tasks: feed.tasks,
          hasPendingWrites: feed.hasPendingWrites,
          isFromCache: feed.isFromCache,
          pendingDeleteIds: state.pendingDeleteIds.intersection(present),
        );
      },
      onError: (_, _) => state.copyWith(
        status: state.tasks.isEmpty
            ? TaskLoadStatus.failure
            : TaskLoadStatus.ready,
        errorMessage: 'Could not refresh tasks. Showing saved data.',
      ),
    );
  }

  void _onCreated(TaskCreated e, Emitter<TaskState> emit) {
    final now = _clock();
    _track(
      _repo.upsertTask(
        _uid,
        TaskEntity(
          id: _repo.newTaskId(_uid),
          title: e.title.trim(),
          description: e.description.trim(),
          dueDate: normalizeToMinute(e.dueDate),
          priority: e.priority,
          category: e.category,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );
  }

  void _onUpdated(TaskUpdated e, Emitter<TaskState> emit) => _track(
    _repo.upsertTask(
      _uid,
      e.task.copyWith(
        title: e.task.title.trim(),
        description: e.task.description.trim(),
        dueDate: normalizeToMinute(e.task.dueDate),
        updatedAt: _clock(),
      ),
    ),
  );

  void _onToggled(TaskCompletionToggled e, Emitter<TaskState> emit) => _track(
    _repo.setCompletion(
      _uid,
      e.task.id,
      isCompleted: !e.task.isCompleted,
      updatedAt: _clock(),
    ),
  );

  void _onDeleted(TaskDeleted e, Emitter<TaskState> emit) {
    // Emit synchronously so the Dismissible leaves the tree on the next frame.
    emit(
      state.copyWith(pendingDeleteIds: {...state.pendingDeleteIds, e.task.id}),
    );
    _track(_repo.deleteTask(_uid, e.task.id));
  }

  void _onRestored(TaskRestored e, Emitter<TaskState> emit) {
    emit(
      state.copyWith(
        pendingDeleteIds: {...state.pendingDeleteIds}..remove(e.task.id),
      ),
    );
    // Same id + original createdAt => identical position in the list.
    _track(_repo.upsertTask(_uid, e.task.copyWith(updatedAt: _clock())));
  }

  /// Writes complete on server ACK; never awaited (offline-safe).
  void _track(Future<void> write) {
    unawaited(
      write.catchError((Object error) {
        if (isClosed) return;
        add(
          TaskWriteFailed(
            error is TaskFailure
                ? error.message
                : 'Could not sync a change. Please try again.',
          ),
        );
      }),
    );
  }
}
