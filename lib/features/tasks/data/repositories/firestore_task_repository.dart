import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/features/tasks/data/models/task_model.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/entities/task_feed.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  @override
  Stream<TaskFeed> watchTasks(String userId) => _tasks(userId)
      .orderBy('dueDate')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snap) => TaskFeed(
          tasks: [
            for (final doc in snap.docs) TaskModel.fromMap(doc.id, doc.data()),
          ],
          hasPendingWrites: snap.metadata.hasPendingWrites,
          isFromCache: snap.metadata.isFromCache,
        ),
      )
      .transform(_endOnSignOut)
      .distinct();

  /// After sign-out Firestore fails the old listener with
  /// `permission-denied`. That is an expected end-of-session, not an error
  /// to show the user, so the stream simply completes.
  static final _endOnSignOut =
      StreamTransformer<TaskFeed, TaskFeed>.fromHandlers(
        handleError: (error, stackTrace, sink) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            sink.close();
          } else {
            sink.addError(error, stackTrace);
          }
        },
      );

  @override
  String newTaskId(String userId) => _tasks(userId).doc().id;

  @override
  Future<void> upsertTask(String userId, TaskEntity task) =>
      _guard(_tasks(userId).doc(task.id).set(TaskModel.toFirestore(task)));

  @override
  Future<void> setCompletion(
    String userId,
    String taskId, {
    required bool isCompleted,
    required DateTime updatedAt,
  }) => _guard(
    _tasks(userId).doc(taskId).update({
      'isCompleted': isCompleted,
      'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
    }),
  );

  @override
  Future<void> deleteTask(String userId, String taskId) =>
      _guard(_tasks(userId).doc(taskId).delete());

  Future<void> _guard(Future<void> write) async {
    try {
      await write;
    } on FirebaseException catch (e) {
      throw TaskFailure(_message(e.code), code: e.code);
    }
  }

  static String _message(String code) => switch (code) {
    'permission-denied' =>
      'A change was rejected by the server and has been reverted.',
    'unavailable' =>
      'Server unavailable. Your change will retry automatically.',
    _ => 'Could not sync a change. Please try again.',
  };
}
