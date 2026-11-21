import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

extension PriorityColor on TaskPriority {
  Color colorOf(BuildContext context) {
    final glass = context.glass;
    return switch (this) {
      TaskPriority.high => glass.priorityHigh,
      TaskPriority.medium => glass.priorityMedium,
      TaskPriority.low => glass.priorityLow,
    };
  }
}

/// Small tinted pill with solid label (colour is never the only signal).
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dot = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 7),
              ),
              const SizedBox(width: 5),
            ],
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
