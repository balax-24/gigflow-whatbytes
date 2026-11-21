import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/liquid_glass_card.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/widgets/priority_style.dart';
import 'package:gigflow/features/tasks/presentation/widgets/undo_delete.dart';
import 'package:intl/intl.dart';

final _dueFormat = DateFormat('EEE, d MMM · h:mm a');

/// Tier-2 task card (no BackdropFilter, no Opacity, no clip).
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.now,
    required this.onTap,
  });

  final TaskEntity task;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final overdue = task.isOverdueAt(now);
    final priorityColor = task.priority.colorOf(context);
    final done = task.isCompleted;
    final dueText = _dueFormat.format(task.dueDate.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('task-${task.id}'),
        direction: DismissDirection.endToStart,
        background: _DeleteBackground(color: glass.priorityHigh),
        onDismissed: (_) => deleteWithUndo(
          bloc: context.read<TaskBloc>(),
          messenger: ScaffoldMessenger.of(context),
          task: task,
        ),
        child: Semantics(
          container: true,
          label:
              '${task.title}, due $dueText, ${task.priority.label} priority, '
              '${done ? 'completed' : (overdue ? 'overdue' : 'not completed')}',
          child: LiquidGlassCard(
            accentTint: task.priority == TaskPriority.high && !done
                ? glass.priorityHigh
                : null,
            padding: EdgeInsets.zero,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 8, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompletionCheckbox(task: task),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: theme.textTheme.titleMedium!.copyWith(
                                  color: done
                                      ? glass.textMuted
                                      : theme.colorScheme.onSurface,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: glass.textMuted,
                                ),
                                child: Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  task.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: done
                                        ? glass.textMuted
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  TagPill(
                                    label: dueText,
                                    icon: Icons.schedule_rounded,
                                    color: overdue
                                        ? glass.overdue
                                        : (done
                                              ? glass.textMuted
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                  ),
                                  TagPill(
                                    label: task.priority.label,
                                    color: priorityColor,
                                    dot: true,
                                  ),
                                  if (overdue)
                                    TagPill(
                                      label: 'Overdue',
                                      icon: Icons.warning_amber_rounded,
                                      color: glass.overdue,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: glass.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCheckbox extends StatelessWidget {
  const _CompletionCheckbox({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final done = task.isCompleted;
    return Semantics(
      checked: done,
      button: true,
      label: done
          ? 'Mark “${task.title}” incomplete'
          : 'Mark “${task.title}” complete',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 48,
        child: InkResponse(
          key: ValueKey('toggle-${task.id}'),
          radius: 24,
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<TaskBloc>().add(TaskCompletionToggled(task));
          },
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? glass.complete.withValues(alpha: 0.9)
                    : Colors.transparent,
                border: Border.all(
                  color: done ? glass.complete : glass.textMuted,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.05), color.withValues(alpha: 0.55)],
      ),
    ),
    child: const Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
