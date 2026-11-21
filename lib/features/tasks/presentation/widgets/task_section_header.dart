import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';

class TaskSectionHeader extends StatelessWidget {
  const TaskSectionHeader({
    super.key,
    required this.label,
    required this.count,
    this.alert = false,
  });

  final String label;
  final int count;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = alert
        ? glass.overdue
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: color),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                color: glass.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
