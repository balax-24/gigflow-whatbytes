import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/entities/task_feed.dart';

abstract interface class TaskRepository {
  /// Emits on every local or server change (including metadata changes).
  Stream<TaskFeed> watchTasks(String userId);

  /// Client-side id generation (works offline).
  String newTaskId(String userId);

  /// Writes to the local cache immediately. The returned future completes on
  /// SERVER acknowledgement — callers must NOT await it for UI purposes.
  /// Throws a TaskFailure if the server rejects the write.
  Future<void> upsertTask(String userId, TaskEntity task);

  Future<void> setCompletion(
    String userId,
    String taskId, {
    required bool isCompleted,
    required DateTime updatedAt,
  });

  Future<void> deleteTask(String userId, String taskId);
}
