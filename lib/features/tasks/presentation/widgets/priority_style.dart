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

/// Explicit selected/unselected chip styling (WCAG AA in both themes).
/// Selected = solid [fill] (accent by default) with a contrasting label.
({TextStyle label, BorderSide side, Color fill, Color onFill})
selectableChipStyle(
  BuildContext context, {
  required bool selected,
  Color? fill,
}) {
  final scheme = Theme.of(context).colorScheme;
  final background = fill ?? scheme.primary;
  final onFill =
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : const Color(0xFF070B14);
  return (
    label: TextStyle(
      color: selected ? onFill : scheme.onSurface,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
    side: BorderSide(
      color: selected ? background : scheme.onSurface.withValues(alpha: 0.22),
    ),
    fill: background,
    onFill: onFill,
  );
}

/// ChoiceChip with an unmistakable selected state.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.dotColor,
    this.fill,
    this.tooltip,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? dotColor;
  final Color? fill;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final style = selectableChipStyle(context, selected: selected, fill: fill);
    final Widget? avatar = selected
        ? Icon(Icons.check_rounded, size: 18, color: style.onFill)
        : (dotColor == null
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 9),
                ));
    return ChoiceChip(
      tooltip: tooltip,
      avatar: avatar,
      label: Text(label),
      labelStyle: style.label,
      side: style.side,
      selected: selected,
      selectedColor: style.fill,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    );
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
