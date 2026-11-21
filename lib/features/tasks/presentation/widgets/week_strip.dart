import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';
import 'package:intl/intl.dart';

/// 7-day strip (today → +6). Tap a day to show only that day's tasks; tap
/// again to clear. Dots show how many open tasks are due that day.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.now,
    required this.tasks,
    required this.selectedDay,
    required this.onDayTap,
  });

  final DateTime now;
  final List<TaskEntity> tasks;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDayTap;

  static final _weekday = DateFormat('EEE');

  @override
  Widget build(BuildContext context) {
    final start = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: _DayCell(
                day: day,
                isToday: day == start,
                selected: selectedDay != null && isSameDay(selectedDay!, day),
                openCount: tasks
                    .where((t) => !t.isCompleted && isSameDay(t.dueDate, day))
                    .length,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDayTap(day);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.selected,
    required this.openCount,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool selected;
  final int openCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = context.glass;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    final label = isToday ? 'Today' : WeekStrip._weekday.format(day);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '$label ${day.day}, $openCount open task${openCount == 1 ? '' : 's'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey('day-${day.month}-${day.day}'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 68,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : glass.cardFill.first,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isToday && !selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? fg : glass.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < openCount.clamp(0, 3); i++)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: selected ? fg : scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (openCount == 0) const SizedBox(height: 5),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
