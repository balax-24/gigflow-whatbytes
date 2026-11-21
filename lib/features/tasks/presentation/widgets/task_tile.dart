import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/liquid_glass_card.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/utils/relative_due.dart';
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
    final relative = RelativeDue.of(task.dueDate, now, completed: done);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('task-${task.id}'),
        // Swipe right = toggle complete (card snaps back), left = delete.
        direction: DismissDirection.horizontal,
        background: _SwipeBackground(
          color: glass.complete,
          icon: done ? Icons.undo_rounded : Icons.check_circle_rounded,
          label: done ? 'Undo' : 'Done',
          alignEnd: false,
        ),
        secondaryBackground: _SwipeBackground(
          color: glass.priorityHigh,
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          alignEnd: true,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await HapticFeedback.lightImpact();
            if (context.mounted) {
              context.read<TaskBloc>().add(TaskCompletionToggled(task));
            }
            return false;
          }
          return true;
        },
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
                                  _CategoryPill(
                                    emoji: task.category.emoji,
                                    label: task.category.label,
                                  ),
                                  if (relative != null)
                                    TagPill(
                                      key: const ValueKey('relative-due'),
                                      label: relative.label,
                                      icon:
                                          relative.urgency == DueUrgency.overdue
                                          ? Icons.warning_amber_rounded
                                          : Icons.timer_outlined,
                                      color: switch (relative.urgency) {
                                        DueUrgency.overdue => glass.overdue,
                                        DueUrgency.soon =>
                                          theme.colorScheme.primary,
                                        DueUrgency.later =>
                                          theme.colorScheme.onSurfaceVariant,
                                      },
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

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          '$emoji $label',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignEnd,
  });

  final Color color;
  final IconData icon;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: alignEnd ? Alignment.centerLeft : Alignment.centerRight,
        end: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        colors: [color.withValues(alpha: 0.05), color.withValues(alpha: 0.75)],
      ),
    ),
    child: Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
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
