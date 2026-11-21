import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';

/// Deletes [task] and shows a 4-second Undo SnackBar.
/// `persist: false` is required: on Flutter 3.47 SnackBars with an action
/// persist by default and would never auto-dismiss.
void deleteWithUndo({
  required TaskBloc bloc,
  required ScaffoldMessengerState messenger,
  required TaskEntity task,
}) {
  HapticFeedback.mediumImpact();
  bloc.add(TaskDeleted(task));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '“${task.title}” deleted',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        duration: const Duration(seconds: 4),
        persist: false,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            if (!bloc.isClosed) bloc.add(TaskRestored(task));
          },
        ),
      ),
    );
}
