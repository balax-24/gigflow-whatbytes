import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_category.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

/// Pure mapper between Firestore maps and [TaskEntity].
/// Never relies on serverTimestamp (which reads as null while pending).
abstract final class TaskModel {
  static TaskEntity fromMap(
    String id,
    Map<String, dynamic> data, {
    DateTime Function() clock = DateTime.now,
  }) {
    final createdAt =
        _readDate(data['createdAt']) ?? _readDate(data['dueDate']) ?? clock();
    final title = data['title'];
    final description = data['description'];
    final priority = data['priority'];
    final category = data['category'];
    return TaskEntity(
      id: id,
      title: title is String ? title.trim() : '',
      description: description is String ? description : '',
      dueDate: _readDate(data['dueDate']) ?? createdAt,
      priority: TaskPriority.fromName(priority is String ? priority : null),
      isCompleted: data['isCompleted'] == true,
      category: TaskCategory.fromName(category is String ? category : null),
      createdAt: createdAt,
      updatedAt: _readDate(data['updatedAt']) ?? createdAt,
    );
  }

  static Map<String, Object> toFirestore(TaskEntity task) => {
    'title': task.title.trim(),
    'description': task.description.trim(),
    'dueDate': Timestamp.fromDate(task.dueDate.toUtc()),
    'priority': task.priority.name,
    'isCompleted': task.isCompleted,
    'category': task.category.name,
    'createdAt': Timestamp.fromDate(task.createdAt.toUtc()),
    'updatedAt': Timestamp.fromDate(task.updatedAt.toUtc()),
  };

  static DateTime? _readDate(Object? value) => switch (value) {
    Timestamp() => value.toDate(),
    DateTime() => value.toLocal(),
    int() => DateTime.fromMillisecondsSinceEpoch(value),
    _ => null,
  };
}
